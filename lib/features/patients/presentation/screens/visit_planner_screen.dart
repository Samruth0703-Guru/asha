import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/sync_service.dart';
import '../../../sms/controllers/sms_controller.dart';
import '../../../../core/database/local_database.dart';

class VisitPlannerScreen extends ConsumerStatefulWidget {
  const VisitPlannerScreen({super.key});

  @override
  ConsumerState<VisitPlannerScreen> createState() => _VisitPlannerScreenState();
}

class _VisitPlannerScreenState extends ConsumerState<VisitPlannerScreen> {
  // Map Controller for flutter_map
  late final MapController _mapController;

  // View modes: 'list', 'map_view', 'navigate_view', 'visit_view'
  String _viewMode = 'list';
  _PriorityVisit? _currentSelectedVisit;

  // Live navigation state
  double _remainingDistanceMeters = 0.0;
  double _routeDistanceMeters = 0.0;
  double _currentSpeed = 0.0;
  bool _hasArrived = false;
  DateTime? _checkInTime;

  // Simulated movement state
  Timer? _simulationTimer;
  int _simulationIndex = 0;
  bool _isSimulating = false;

  // Default fallback list
  List<_PriorityVisit> get _rankedVisits => [];

  // Dynamic patient list loaded from Drift DB
  List<_PriorityVisit> _dynamicVisits = [];

  // Route state
  bool _isRouteActive = false;
  int _currentRouteIndex = 0;
  final List<String> _completedVisitIds = [];

  LatLng _ashaLocation = const LatLng(10.0400, 78.1200);
  List<LatLng> _routePolyline = [];
  bool _isLoadingRoute = false;
  String _routeInfo = '';

  // Location Stream Subscription
  StreamSubscription<Position>? _positionStreamSub;

  // Visit form controllers
  final _vitalsController = TextEditingController();
  final _notesController = TextEditingController();
  String _capturedPhotoPath = '';

  final Dio _dio = Dio();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initGPS();
    _startLocationTracking();
    _loadVisitsFromDb();
  }

  @override
  void dispose() {
    _vitalsController.dispose();
    _notesController.dispose();
    _stopLocationTracking();
    _simulationTimer?.cancel();
    super.dispose();
  }

  void _initGPS() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        if (mounted) {
          setState(() {
            _ashaLocation = LatLng(pos.latitude, pos.longitude);
          });
          _loadVisitsFromDb();
        }
      }
    } catch (e) {
      debugPrint('GPS error: $e');
    }
  }

  void _startLocationTracking() {
    _positionStreamSub?.cancel();
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 2,
    );
    _positionStreamSub = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position pos) {
      if (mounted) {
        setState(() {
          _ashaLocation = LatLng(pos.latitude, pos.longitude);
          _currentSpeed = pos.speed * 3.6; // convert m/s to km/h
        });

        // Dynamic update of route / remaining distance during active navigation
        if (_viewMode == 'navigate_view' || _viewMode == 'visit_view') {
          _updateLiveRouteAndDistance();
        }
      }
    }, onError: (err) {
      debugPrint('GPS stream error: $err');
    });
  }

  void _stopLocationTracking() {
    _positionStreamSub?.cancel();
    _positionStreamSub = null;
  }

  Future<void> _loadVisitsFromDb() async {
    try {
      final db = ref.read(localDatabaseProvider);
      final dbPatients = await db.getAllPatients();

      if (dbPatients.isNotEmpty) {
        final visits = dbPatients.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;

          // Determine priority
          int score = 40;
          if (p.riskLevel.toLowerCase() == 'critical') {
            score = 98;
          } else if (p.riskLevel.toLowerCase() == 'high') {
            score = 85;
          } else if (p.riskLevel.toLowerCase() == 'medium') {
            score = 65;
          }

          // Read coordinates from patient DB fields, or map default offset relative to current position
          final lat = p.latitude ?? (_ashaLocation.latitude + (i * 0.0015) - 0.002);
          final lon = p.longitude ?? (_ashaLocation.longitude + (i * 0.0015) - 0.002);

          return _PriorityVisit(
            id: 'V${i + 1}',
            patientId: p.id,
            patientName: p.name,
            priorityScore: score,
            distanceMeters: (Geolocator.distanceBetween(_ashaLocation.latitude, _ashaLocation.longitude, lat, lon)).round(),
            visitDurationMinutes: score >= 90 ? 45 : (score >= 70 ? 30 : 20),
            reason: p.reasons ?? 'Routine maternal prenatal follow-up care check.',
            phone: p.phone,
            village: p.village,
            coords: LatLng(lat, lon),
          );
        }).toList();

        // Sort by priority descending
        visits.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));

        setState(() {
          _dynamicVisits = visits;
        });
      } else {
        setState(() {
          _dynamicVisits = _rankedVisits;
        });
      }
    } catch (e) {
      debugPrint('Load visits from DB failure: $e');
      setState(() {
        _dynamicVisits = _rankedVisits;
      });
    }
  }

  Future<void> _fetchRoute(LatLng destination) async {
    setState(() {
      _isLoadingRoute = true;
      _routePolyline = [];
    });

    final url = 'https://router.project-osrm.org/route/v1/driving/'
        '${_ashaLocation.longitude},${_ashaLocation.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson';

    try {
      final resp = await _dio.get(url);
      if (resp.statusCode == 200 && (resp.data['routes'] as List).isNotEmpty) {
        final route = resp.data['routes'][0];
        final coords = (route['geometry']['coordinates'] as List)
            .map((c) => LatLng(c[1] as double, c[0] as double))
            .toList();
        final distM = (route['distance'] as num).toDouble();
        final durS = (route['duration'] as num).toDouble();

        setState(() {
          _routePolyline = coords;
          _routeDistanceMeters = distM;
          _routeInfo = '${(distM / 1000).toStringAsFixed(1)} km  ·  ~${(durS / 60).toStringAsFixed(0)} min';
          _remainingDistanceMeters = distM;
        });
      }
    } catch (_) {
      // Offline fallback
      final distM = Geolocator.distanceBetween(
        _ashaLocation.latitude, _ashaLocation.longitude,
        destination.latitude, destination.longitude
      );
      setState(() {
        _routePolyline = [_ashaLocation, destination];
        _routeDistanceMeters = distM;
        _routeInfo = 'Straight line (offline)';
        _remainingDistanceMeters = distM;
      });
    } finally {
      setState(() => _isLoadingRoute = false);
      _updateLiveRouteAndDistance();
    }
  }

  void _updateLiveRouteAndDistance() {
    if (_currentSelectedVisit == null) return;
    final destination = _currentSelectedVisit!.coords;

    final distM = Geolocator.distanceBetween(
      _ashaLocation.latitude, _ashaLocation.longitude,
      destination.latitude, destination.longitude
    );

    setState(() {
      _remainingDistanceMeters = distM;
      if (distM <= 20.0 && !_hasArrived && _viewMode == 'visit_view') {
        _hasArrived = true;
        _checkInTime = DateTime.now();
        _stopSimulation();
      }
    });
  }

  void _startSimulation(LatLng destination) {
    if (_routePolyline.isEmpty) return;
    _simulationTimer?.cancel();
    _simulationIndex = 0;
    setState(() {
      _isSimulating = true;
      _currentSpeed = 35.0;
    });

    _simulationTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (_simulationIndex < _routePolyline.length) {
        setState(() {
          _ashaLocation = _routePolyline[_simulationIndex];
          _simulationIndex++;
        });
        _updateLiveRouteAndDistance();
        _mapController.move(_ashaLocation, 16.0);
      } else {
        setState(() {
          _ashaLocation = destination;
          _currentSpeed = 0.0;
          _isSimulating = false;
        });
        _simulationTimer?.cancel();
        _updateLiveRouteAndDistance();
      }
    });
  }

  void _stopSimulation() {
    _simulationTimer?.cancel();
    setState(() {
      _isSimulating = false;
      _currentSpeed = 0.0;
    });
  }

  // Action flow triggers
  void _viewOnMap(_PriorityVisit v) {
    setState(() {
      _currentSelectedVisit = v;
      _viewMode = 'map_view';
      _routePolyline = [];
      _routeInfo = '';
    });
    // Center map on patient
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(v.coords, 14.5);
    });
  }

  Future<void> _navigate(_PriorityVisit v) async {
    setState(() {
      _currentSelectedVisit = v;
      _viewMode = 'navigate_view';
      _hasArrived = false;
    });
    await _fetchRoute(v.coords);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitMapCamera(v.coords);
    });
  }

  Future<void> _startVisit(_PriorityVisit v) async {
    setState(() {
      _currentSelectedVisit = v;
      _viewMode = 'visit_view';
      _hasArrived = false;
      _checkInTime = null;
      _capturedPhotoPath = '';
      _vitalsController.clear();
      _notesController.clear();
    });
    await _fetchRoute(v.coords);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitMapCamera(v.coords);
    });
  }

  Future<void> _callPatient(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Cannot launch call interface for: $phone'),
        backgroundColor: AppTheme.dangerColor,
      ));
    }
  }

  // Original optimized path features
  void _startOptimizedRoute() {
    if (_dynamicVisits.isEmpty) return;
    setState(() {
      _isRouteActive = true;
      _currentRouteIndex = 0;
      _completedVisitIds.clear();
      _routePolyline = [];
      _routeInfo = '';
    });
    _drawRouteForCurrentVisit();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('🗺️ Route activated — OpenStreetMap optimized navigation started!'),
      backgroundColor: AppTheme.primaryColor,
    ));
  }

  void _nextPatient() {
    if (_currentRouteIndex < _dynamicVisits.length - 1) {
      setState(() {
        _currentRouteIndex++;
        _routePolyline = [];
        _routeInfo = '';
      });
      _drawRouteForCurrentVisit();
    }
  }

  Future<void> _drawRouteForCurrentVisit() async {
    if (_currentRouteIndex >= _dynamicVisits.length) return;
    final destination = _dynamicVisits[_currentRouteIndex].coords;

    setState(() => _isLoadingRoute = true);

    final url = 'https://router.project-osrm.org/route/v1/driving/'
        '${_ashaLocation.longitude},${_ashaLocation.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson';

    try {
      final resp = await _dio.get(url);
      if (resp.statusCode == 200 && (resp.data['routes'] as List).isNotEmpty) {
        final route = resp.data['routes'][0];
        final coords = (route['geometry']['coordinates'] as List)
            .map((c) => LatLng(c[1] as double, c[0] as double))
            .toList();
        final distKm = (route['distance'] as num) / 1000;
        final durMins = (route['duration'] as num) / 60;

        setState(() {
          _routePolyline = coords;
          _routeInfo = '${distKm.toStringAsFixed(1)} km  ·  ~${durMins.toStringAsFixed(0)} min';
        });
      }
    } catch (_) {
      setState(() {
        _routePolyline = [_ashaLocation, destination];
        _routeInfo = 'Straight line (offline)';
      });
    } finally {
      setState(() => _isLoadingRoute = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitMapCamera(destination);
      });
    }
  }

  Future<void> _finishVisit(String visitId, String patientName) async {
    setState(() {
      _completedVisitIds.add(visitId);
    });

    final syncNotifier = ref.read(syncProvider.notifier);
    await syncNotifier.addRecordToSyncQueue(
      'visit_records',
      'VISIT_${DateTime.now().millisecondsSinceEpoch}',
      'INSERT',
      {
        'patientName': patientName,
        'vitals': _vitalsController.text,
        'notes': _notesController.text,
        'completedAt': DateTime.now().toIso8601String(),
        'checkInTime': _checkInTime?.toIso8601String(),
        'photoPath': _capturedPhotoPath,
      },
    );

    _vitalsController.clear();
    _notesController.clear();
    setState(() {
      _capturedPhotoPath = '';
      _viewMode = 'list';
      _currentSelectedVisit = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✅ Visit for $patientName logged & queued for sync.'),
      backgroundColor: AppTheme.secondaryColor,
    ));

    if (_isRouteActive) {
      if (_completedVisitIds.length == _dynamicVisits.length) {
        setState(() => _isRouteActive = false);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('🎉 Route Completed!'),
            content: const Text('All scheduled visits for today are done. Excellent work, ASHA Worker!'),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done'))],
          ),
        );
      } else {
        _nextPatient();
      }
    }
  }

  Future<void> _sendVisitSms(_PriorityVisit visit, String type) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dispatched SMS process for ${visit.patientName}...'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );

    final db = ref.read(localDatabaseProvider);
    Patient? patient = await db.getPatientById(visit.patientId);

    patient ??= Patient(
      id: visit.patientId,
      isPregnant: false,
      vaccinationRequired: false,
      name: visit.patientName,
      dob: DateTime(1995, 1, 1),
      gender: 'Female',
      phone: visit.phone,
      village: visit.village,
      isHighRisk: visit.priorityScore >= 80,
      previousPregnancies: 0,
      riskLevel: visit.priorityScore >= 90 ? 'Critical' : (visit.priorityScore >= 70 ? 'High' : 'Low'),
      confidenceScore: 0.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    bool success = false;
    final smsController = ref.read(smsControllerProvider.notifier);

    switch (type) {
      case 'ANC':
        if (patient != null) success = await smsController.sendPregnancyReminder(patient);
        break;
      case 'Meds':
        if (patient != null) success = await smsController.sendMedicineReminder(patient);
        break;
      case 'HighRisk':
        if (patient != null) success = await smsController.sendHighRiskAlert(patient);
        break;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'SMS Alert successfully sent to ${visit.patientName}!'
              : 'Failed to send SMS alert to ${visit.patientName}.'),
          backgroundColor: success ? AppTheme.secondaryColor : AppTheme.dangerColor,
        ),
      );
    }
  }

  void _fitMapCamera(LatLng destination) {
    final points = <LatLng>[_ashaLocation, destination];
    if (_routePolyline.isNotEmpty) {
      points.addAll(_routePolyline);
    }
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 70),
      ),
    );
  }

  // Builders for Leaflet / OpenStreetMap layers
  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // ASHA location marker
    markers.add(
      Marker(
        point: _ashaLocation,
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Active destination marker
    if (_isRouteActive) {
      final activeVisit = _currentRouteIndex < _dynamicVisits.length ? _dynamicVisits[_currentRouteIndex] : null;
      if (activeVisit != null) {
        markers.add(
          Marker(
            point: activeVisit.coords,
            width: 45,
            height: 45,
            child: const Icon(
              Icons.location_on_rounded,
              color: AppTheme.dangerColor,
              size: 44,
            ),
          ),
        );
      }
    } else if (_currentSelectedVisit != null) {
      markers.add(
        Marker(
          point: _currentSelectedVisit!.coords,
          width: 45,
          height: 45,
          child: const Icon(
            Icons.location_on_rounded,
            color: AppTheme.dangerColor,
            size: 44,
          ),
        ),
      );
    }

    // Other patients markers
    for (final v in _dynamicVisits) {
      final isCompleted = _completedVisitIds.contains(v.id);
      final isActive = (_isRouteActive && _dynamicVisits[_currentRouteIndex].id == v.id) ||
                       (_currentSelectedVisit?.id == v.id);
      if (!isCompleted && !isActive) {
        markers.add(
          Marker(
            point: v.coords,
            width: 35,
            height: 35,
            child: const Icon(
              Icons.location_pin,
              color: Colors.orange,
              size: 32,
            ),
          ),
        );
      }
    }

    return markers;
  }

  List<Polyline> _buildPolylines() {
    if (_routePolyline.isEmpty) return [];
    return [
      Polyline(
        points: _routePolyline,
        strokeWidth: 5.5,
        color: AppTheme.primaryColor,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_viewMode != 'list') {
      return _buildFullScreenMapConsole();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remaining = _dynamicVisits.length - _completedVisitIds.length;
    final totalDistKm = _dynamicVisits.isNotEmpty 
        ? _dynamicVisits.map((v) => v.distanceMeters).reduce((a, b) => a + b) / 1000
        : 0.0;
    final totalMins = _dynamicVisits.isNotEmpty
        ? _dynamicVisits.map((v) => v.visitDurationMinutes).reduce((a, b) => a + b) + _dynamicVisits.length * 15
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Smart Visit Planner', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          if (_isRouteActive)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Chip(
                label: Text('$remaining left', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Header Card (Optimized Path Console)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff1e293b) : Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text("Today's Optimized Path", style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: (_isRouteActive ? AppTheme.secondaryColor : Colors.grey).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _isRouteActive ? '● ROUTE ACTIVE' : '○ INACTIVE',
                      style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold,
                        color: _isRouteActive ? AppTheme.secondaryColor : Colors.grey,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _metric('Total Dist', '${totalDistKm.toStringAsFixed(1)} km', Icons.directions_walk_rounded),
                  _metric('Est. Time', '~$totalMins min', Icons.access_time_rounded),
                  _metric('Progress', '${_completedVisitIds.length}/${_dynamicVisits.length}', Icons.assignment_turned_in_outlined),
                ]),
                const SizedBox(height: 14),
                if (!_isRouteActive)
                  ElevatedButton.icon(
                    onPressed: _startOptimizedRoute,
                    icon: const Icon(Icons.navigation_rounded),
                    label: const Text('Start Route Dispatcher'),
                  )
                else
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() { _isRouteActive = false; _routePolyline = []; _routeInfo = ''; }),
                        child: const Text('Stop Route'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _nextPatient,
                        child: const Text('Next Stop'),
                      ),
                    ),
                  ]),
              ],
            ),
          ),

          // Body list or active route console
          Expanded(
            child: _isRouteActive ? _buildActiveConsole(isDark) : _buildPlannerList(isDark),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String val, IconData icon) {
    return Row(children: [
      Icon(icon, size: 16, color: AppTheme.primaryColor),
      const SizedBox(width: 6),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(val, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
      ]),
    ]);
  }

  Widget _buildPlannerList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _dynamicVisits.length,
      itemBuilder: (_, i) {
        final v = _dynamicVisits[i];
        final isCompleted = _completedVisitIds.contains(v.id);
        final color = v.priorityScore >= 90 ? AppTheme.dangerColor
            : v.priorityScore >= 70 ? Colors.orange.shade700
            : AppTheme.primaryColor;
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: isCompleted ? AppTheme.secondaryColor.withOpacity(0.1) : color.withOpacity(0.1),
                    shape: BoxShape.circle
                  ),
                  child: Center(
                    child: isCompleted 
                        ? const Icon(Icons.check, color: AppTheme.secondaryColor)
                        : Text('${i + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16))
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(v.patientName, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(v.village, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text('Score: ${v.priorityScore}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                ),
              ]),
              const SizedBox(height: 10),
              Text(v.reason, style: GoogleFonts.inter(fontSize: 12, color: isDark ? const Color(0xffcbd5e1) : const Color(0xff475569))),
              const Divider(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${v.distanceMeters} m from you', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text('${v.visitDurationMinutes} min visit', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
              const Divider(height: 20),
              // Action Chips for patient navigation
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _actionChip(
                    label: 'View Map',
                    icon: Icons.map_rounded,
                    onTap: () => _viewOnMap(v),
                    color: Colors.blue,
                  ),
                  _actionChip(
                    label: 'Navigate',
                    icon: Icons.navigation_rounded,
                    onTap: () => _navigate(v),
                    color: AppTheme.primaryColor,
                  ),
                  _actionChip(
                    label: 'Start Visit',
                    icon: Icons.medical_services_rounded,
                    onTap: () => _startVisit(v),
                    color: AppTheme.secondaryColor,
                  ),
                  _actionChip(
                    label: 'Call',
                    icon: Icons.call_rounded,
                    onTap: () => _callPatient(v.phone),
                    color: Colors.teal,
                  ),
                  _actionChip(
                    label: 'Profile',
                    icon: Icons.person_rounded,
                    onTap: () => context.push('/patient-profile/${v.patientId}'),
                    color: Colors.purple,
                  ),
                ],
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _actionChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 14, color: color),
      label: Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold)),
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildActiveConsole(bool isDark) {
    if (_dynamicVisits.isEmpty) return const SizedBox.shrink();
    final activeVisit = _dynamicVisits[_currentRouteIndex];
    final isCompleted = _completedVisitIds.contains(activeVisit.id);
    final priorityColor = activeVisit.priorityScore >= 90 ? AppTheme.dangerColor
        : activeVisit.priorityScore >= 70 ? Colors.orange.shade700
        : AppTheme.primaryColor;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── LIVE OPENSTREETMAP ───────────────────────────────────────────
          Stack(
            children: [
              SizedBox(
                height: 440,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _ashaLocation,
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.ashacare.app',
                    ),
                    PolylineLayer(polylines: _buildPolylines()),
                    MarkerLayer(markers: _buildMarkers()),
                  ],
                ),
              ),
              if (_isLoadingRoute)
                Positioned.fill(
                  child: Container(
                    color: Colors.black26,
                    child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
                ),
              if (_routeInfo.isNotEmpty)
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                    ),
                    child: Row(children: [
                      const Icon(Icons.navigation_rounded, color: AppTheme.primaryColor, size: 18),
                      const SizedBox(width: 8),
                      Text(_routeInfo, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ]),
                  ),
                ),
            ],
          ),

          // ─── ACTIVE TARGET CARD ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('ACTIVE TARGET LOCATION', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: priorityColor, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: priorityColor.withOpacity(0.3), width: 1.5),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(activeVisit.patientName, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: priorityColor))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: priorityColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: Text('P${activeVisit.priorityScore}', style: TextStyle(fontWeight: FontWeight.bold, color: priorityColor, fontSize: 12)),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Text('📍 ${activeVisit.village}  ·  📞 ${activeVisit.phone}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(activeVisit.reason, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xff374151))),
                    const Divider(height: 24),
                    Text(
                      'SMS ALERTS DISPATCHER',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _smsActionButton(
                          context,
                          label: 'ANC Reminder',
                          icon: Icons.pregnant_woman_rounded,
                          onPressed: () => _sendVisitSms(activeVisit, 'ANC'),
                        ),
                        _smsActionButton(
                          context,
                          label: 'Meds Reminder',
                          icon: Icons.medication_rounded,
                          onPressed: () => _sendVisitSms(activeVisit, 'Meds'),
                        ),
                        if (activeVisit.priorityScore >= 80)
                          _smsActionButton(
                            context,
                            label: 'High-Risk Alert',
                            icon: Icons.warning_amber_rounded,
                            color: AppTheme.dangerColor,
                            onPressed: () => _sendVisitSms(activeVisit, 'HighRisk'),
                          ),
                      ],
                    ),
                  ]),
                ),

                const SizedBox(height: 20),
                Text('Offline Visit Form', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                const Divider(),
                const SizedBox(height: 12),

                if (!isCompleted) ...[
                  TextFormField(
                    controller: _vitalsController,
                    decoration: const InputDecoration(
                      labelText: 'Vitals (BP, Temp, Weight, Hb)',
                      prefixIcon: Icon(Icons.monitor_heart_outlined),
                      hintText: 'e.g., BP 120/80, Hb 10.2, Wt 58kg',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Clinical Notes',
                      prefixIcon: Icon(Icons.edit_note_outlined),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _capturedPhotoPath = 'photo_${activeVisit.id}.jpg'),
                    icon: Icon(_capturedPhotoPath.isNotEmpty ? Icons.check_circle_rounded : Icons.camera_alt_outlined,
                        color: _capturedPhotoPath.isNotEmpty ? AppTheme.secondaryColor : null),
                    label: Text(_capturedPhotoPath.isNotEmpty ? 'Photo Captured ✓' : 'Attach Photo'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _finishVisit(activeVisit.id, activeVisit.patientName),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryColor),
                    icon: const Icon(Icons.cloud_upload_rounded),
                    label: const Text('Submit Visit & Sync'),
                  ),
                ] else ...[
                  const SizedBox(height: 24),
                  Center(child: Column(children: [
                    const Icon(Icons.check_circle_rounded, size: 64, color: AppTheme.secondaryColor),
                    const SizedBox(height: 12),
                    Text('Visit Completed & Logged', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Queued for server sync.', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                  ])),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _smsActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    final themeColor = color ?? AppTheme.primaryColor;
    return Material(
      color: themeColor.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: themeColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── FULL SCREEN INDIVIDUAL MAP / NAVIGATION SCREEN ───────────────────────────
  Widget _buildFullScreenMapConsole() {
    final v = _currentSelectedVisit;
    if (v == null) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final distText = _remainingDistanceMeters >= 1000
        ? '${(_remainingDistanceMeters / 1000).toStringAsFixed(2)} km'
        : '${_remainingDistanceMeters.toStringAsFixed(0)} meters';

    // Estimate arrival time
    final etaMinutes = (_remainingDistanceMeters / (35 * 1000 / 60)).round(); // assuming 35km/h avg
    final arrivalTimeStr = DateFormat('hh:mm a').format(DateTime.now().add(Duration(minutes: etaMinutes)));

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Map Canvas
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: v.coords,
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.ashacare.app',
                ),
                PolylineLayer(polylines: _buildPolylines()),
                MarkerLayer(markers: _buildMarkers()),
              ],
            ),

            // Top Floating Back Button
            Positioned(
              top: 16,
              left: 16,
              child: FloatingActionButton.small(
                heroTag: 'nav_back_btn',
                onPressed: () {
                  _stopSimulation();
                  setState(() {
                    _viewMode = 'list';
                    _currentSelectedVisit = null;
                    _routePolyline = [];
                  });
                },
                backgroundColor: isDark ? const Color(0xff151e2e) : Colors.white,
                child: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black87),
              ),
            ),

            // Top Simulation HUD during navigate/visit view
            if (_viewMode == 'navigate_view' || _viewMode == 'visit_view')
              Positioned(
                top: 16,
                right: 16,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: _isSimulating ? AppTheme.secondaryColor : Colors.white,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      if (_isSimulating) {
                        _stopSimulation();
                      } else {
                        _startSimulation(v.coords);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isSimulating ? Icons.pause_circle : Icons.directions_run_outlined,
                            size: 16,
                            color: _isSimulating ? Colors.white : Colors.black87,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isSimulating ? 'Stop Walk' : 'Simulate Walk',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _isSimulating ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Loading HUD
            if (_isLoadingRoute)
              const Center(
                child: CircularProgressIndicator(),
              ),

            // Bottom dynamic overlay panels based on view mode
            if (_viewMode == 'map_view')
              _buildMapViewPanel(v, distText, etaMinutes)
            else if (_viewMode == 'navigate_view')
              _buildNavigateViewPanel(v, distText, etaMinutes, arrivalTimeStr)
            else if (_viewMode == 'visit_view')
              _buildVisitViewPanel(v, distText, etaMinutes, arrivalTimeStr, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMapViewPanel(_PriorityVisit v, String distText, int etaMinutes) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.patientName, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text('Village: ${v.village}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: v.priorityScore >= 90 ? AppTheme.dangerColor.withOpacity(0.12) : AppTheme.primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      v.priorityScore >= 90 ? 'Critical Risk' : (v.priorityScore >= 70 ? 'High Risk' : 'Low Risk'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: v.priorityScore >= 90 ? AppTheme.dangerColor : AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.social_distance_rounded, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(distText, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text('~$etaMinutes min drive', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _callPatient(v.phone),
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text('Call Patient'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _navigate(v),
                      icon: const Icon(Icons.navigation_rounded, size: 18),
                      label: const Text('Navigate'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => _startVisit(v),
                icon: const Icon(Icons.home_work_rounded, size: 18),
                label: const Text('Start Visit Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigateViewPanel(_PriorityVisit v, String distText, int etaMinutes, String arrivalTimeStr) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Card(
        color: const Color(0xff0b0f19), // sleek dark slate
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.directions_car_rounded, color: Colors.blueAccent, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Navigating to ${v.patientName}', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('Route: Semmancheri PHC Sector', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('REMAINING DIST', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(distText, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SPEED', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('${_currentSpeed.toStringAsFixed(0)} km/h', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ETA', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(arrivalTimeStr, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                      ),
                      onPressed: () {
                        _stopSimulation();
                        setState(() {
                          _viewMode = 'list';
                          _currentSelectedVisit = null;
                        });
                      },
                      child: const Text('Exit Nav'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                      ),
                      onPressed: () => _startVisit(v),
                      child: const Text('Start Clinical Visit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisitViewPanel(_PriorityVisit v, String distText, int etaMinutes, String arrivalTimeStr, bool isDark) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_hasArrived) ...[
                // Still traveling HUD
                Row(
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Traveling to ${v.patientName}...',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Current Distance remaining: $distText. Please move within 20 meters of the patient to unlock check-in actions.',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _routeDistanceMeters > 0 
                      ? (1.0 - (_remainingDistanceMeters / _routeDistanceMeters)).clamp(0.0, 1.0)
                      : 0.0,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () {
                    _stopSimulation();
                    setState(() {
                      _viewMode = 'list';
                      _currentSelectedVisit = null;
                    });
                  },
                  child: const Text('Cancel Visit'),
                ),
              ] else ...[
                // Arrived screen within 20 meters
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppTheme.secondaryColor, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('You have arrived.', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Destination reached (under 20 meters)', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                if (_checkInTime == null) ...[
                  // Arrived but not checked-in
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () {
                      setState(() {
                        _checkInTime = DateTime.now();
                      });
                    },
                    icon: const Icon(Icons.vpn_key_rounded),
                    label: const Text('Check In to Patient Home'),
                  ),
                ] else ...[
                  // Checked in -> show offline vitals / notes fields
                  Text(
                    'Checked In: ${DateFormat('hh:mm:ss a').format(_checkInTime!)}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.secondaryColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _vitalsController,
                    decoration: const InputDecoration(
                      labelText: 'Patient Vitals (BP, Pulse, Temp, Weight)',
                      prefixIcon: Icon(Icons.monitor_heart_rounded),
                      hintText: 'e.g. 120/80 mmHg, 72 bpm, 98.4 F',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Clinical Notes',
                      prefixIcon: Icon(Icons.edit_note_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _capturedPhotoPath = 'patient_visit_${v.patientId}.jpg';
                      });
                    },
                    icon: Icon(
                      _capturedPhotoPath.isNotEmpty ? Icons.check_circle : Icons.camera_alt_rounded,
                      color: _capturedPhotoPath.isNotEmpty ? AppTheme.secondaryColor : null,
                    ),
                    label: Text(_capturedPhotoPath.isNotEmpty ? 'Photo Captured ✓' : 'Capture Photo'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => _finishVisit(v.id, v.patientName),
                    icon: const Icon(Icons.cloud_done_rounded),
                    label: const Text('Complete Visit & Sync'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityVisit {
  final String id, patientId, patientName, reason, phone, village;
  final int priorityScore, distanceMeters, visitDurationMinutes;
  final LatLng coords;

  _PriorityVisit({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.priorityScore,
    required this.distanceMeters,
    required this.visitDurationMinutes,
    required this.reason,
    required this.phone,
    required this.village,
    required this.coords,
  });
}
