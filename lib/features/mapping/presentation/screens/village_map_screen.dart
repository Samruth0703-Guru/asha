import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/database/sync_service.dart';

class VillageMapScreen extends ConsumerStatefulWidget {
  const VillageMapScreen({super.key});

  @override
  ConsumerState<VillageMapScreen> createState() => _VillageMapScreenState();
}

class _VillageMapScreenState extends ConsumerState<VillageMapScreen> {
  GoogleMapController? _mapController;
  StreamSubscription<Position>? _positionSub;
  final Dio _dio = Dio();

  // GPS state
  LatLng _ashaLocation = const LatLng(10.0400, 78.1200);
  bool _isTracking = true;

  // Search state
  final _searchCtrl = TextEditingController();
  bool _showSuggestions = false;
  String _selectedFilter = 'All';
  List<_SearchResult> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;
  _SearchResult? _searchedPlace;

  // Overlays Sets
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Set<Circle> _circles = {};
  final Set<Polygon> _polygons = {};

  // Layers and Map Type
  bool _layerRisk = false;
  bool _layerVaccination = false;
  bool _layerPregnancy = false;
  bool _layerOutbreak = false;
  bool _layerRoute = false;
  MapType _mapType = MapType.normal;

  // Route Info
  List<LatLng> _routePoints = [];
  String _routeDistText = '';
  String _routeDurText = '';
  bool _isCalcRoute = false;

  List<_Patient> _dbPatients = [];
  List<_Patient> get _patients => _dbPatients;

  void _loadPatients() async {
    try {
      final db = ref.read(localDatabaseProvider);
      final list = await db.getAllPatients();
      if (mounted) {
        setState(() {
          _dbPatients = list.map((p) {
            final lat = p.latitude ?? _ashaLocation.latitude;
            final lng = p.longitude ?? _ashaLocation.longitude;
            return _Patient(
              id: p.id,
              name: p.name,
              age: DateTime.now().year - p.dob.year,
              village: p.village,
              risk: p.riskLevel,
              phone: p.phone,
              pregnancyWeek: p.previousPregnancies > 0 ? 20 : 0,
              vaccinationStatus: p.isHighRisk ? 'Due Today' : 'Completed',
              abhaStatus: p.abhaId != null ? 'Verified' : 'Pending',
              coords: LatLng(lat, lng),
              lastVisit: 'Recent',
            );
          }).toList();
        });
        _rebuildOverlays();
      }
    } catch (e) {
      debugPrint('Error loading patients on map: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _initGPS();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPatients();
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _searchCtrl.dispose();
    _mapController?.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _initGPS() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        _positionSub = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 2),
        ).listen((pos) {
          if (!mounted) return;
          setState(() {
            _ashaLocation = LatLng(pos.latitude, pos.longitude);
          });
          _rebuildOverlays();
          if (_isTracking && _mapController != null) {
            _mapController!.animateCamera(CameraUpdate.newLatLng(_ashaLocation));
          }
        });
      }
    } catch (e) {
      debugPrint('GPS error: $e');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _rebuildOverlays();
    _mapController!.animateCamera(CameraUpdate.newLatLngZoom(_ashaLocation, 14.0));
  }

  double _markerHue(String risk) {
    switch (risk) {
      case 'Critical': return BitmapDescriptor.hueViolet;
      case 'High': return BitmapDescriptor.hueRed;
      case 'Medium': return BitmapDescriptor.hueOrange;
      case 'Low': return BitmapDescriptor.hueGreen;
      default: return BitmapDescriptor.hueBlue;
    }
  }

  Color _riskColor(String risk) {
    switch (risk) {
      case 'Critical': return Colors.purple;
      case 'High': return AppTheme.dangerColor;
      case 'Medium': return AppTheme.warningColor;
      case 'Low': return AppTheme.secondaryColor;
      default: return AppTheme.primaryColor;
    }
  }

  void _rebuildOverlays() {
    if (!mounted) return;
    setState(() {
      _markers.clear();
      _circles.clear();
      _polygons.clear();
      _polylines.clear();

      // 1. ASHA worker GPS location marker
      _markers.add(Marker(
        markerId: const MarkerId('asha_worker'),
        position: _ashaLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Your Location', snippet: 'ASHA Worker GPS'),
        zIndex: 10,
      ));

      // 2. Patient markers
      final filtered = _patients.where((p) {
        if (_selectedFilter == 'High Risk' && p.risk != 'Critical' && p.risk != 'High') return false;
        if (_selectedFilter == 'Pregnant Mothers' && p.pregnancyWeek == 0) return false;
        if (_selectedFilter == 'Vaccination Due' && !p.vaccinationStatus.contains('Due')) return false;
        return true;
      });

      for (final p in filtered) {
        final hue = _markerHue(p.risk);
        _markers.add(Marker(
          markerId: MarkerId(p.id),
          position: p.coords,
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: p.name,
            snippet: '${p.village} · ${p.risk} Risk',
            onTap: () => _showPatientSheet(p),
          ),
          onTap: () => _showPatientSheet(p),
        ));

        // Heatmap circle overlay
        if (_layerRisk) {
          _circles.add(Circle(
            circleId: CircleId('risk_${p.id}'),
            center: p.coords,
            radius: 120,
            fillColor: _riskColor(p.risk).withOpacity(0.2),
            strokeColor: _riskColor(p.risk).withOpacity(0.5),
            strokeWidth: 1,
          ));
        }
      }

      // 3. Search target marker
      if (_searchedPlace != null) {
        _markers.add(Marker(
          markerId: const MarkerId('searched_place'),
          position: _searchedPlace!.coords,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
          infoWindow: InfoWindow(
            title: _searchedPlace!.title,
            snippet: 'Searched Place',
            onTap: () => _showSearchedPlaceSheet(_searchedPlace!),
          ),
          onTap: () => _showSearchedPlaceSheet(_searchedPlace!),
          zIndex: 9,
        ));
      }

      // 4. Pregnancy density circle overlay
      if (_layerPregnancy) {
        _circles.add(Circle(
          circleId: const CircleId('pregnancy_density'),
          center: LatLng(_ashaLocation.latitude + 0.0012, _ashaLocation.longitude - 0.0019),
          radius: 350,
          fillColor: const Color(0x2237aef1),
          strokeColor: AppTheme.primaryColor,
          strokeWidth: 2,
        ));
      }

      // 5. Disease outbreak warning circle overlay
      if (_layerOutbreak) {
        _circles.add(Circle(
          circleId: const CircleId('outbreak'),
          center: LatLng(_ashaLocation.latitude + 0.0036, _ashaLocation.longitude + 0.0024),
          radius: 400,
          fillColor: const Color(0x33ff5722),
          strokeColor: Colors.deepOrange,
          strokeWidth: 2,
        ));
      }

      // 6. Vaccination coverage zone boundary
      if (_layerVaccination) {
        _polygons.add(Polygon(
          polygonId: const PolygonId('vaccination_zone'),
          points: [
            LatLng(_ashaLocation.latitude + 0.0060, _ashaLocation.longitude - 0.0040),
            LatLng(_ashaLocation.latitude + 0.0060, _ashaLocation.longitude + 0.0060),
            LatLng(_ashaLocation.latitude - 0.0060, _ashaLocation.longitude + 0.0060),
            LatLng(_ashaLocation.latitude - 0.0060, _ashaLocation.longitude - 0.0040),
          ],
          fillColor: AppTheme.secondaryColor.withOpacity(0.15),
          strokeColor: AppTheme.secondaryColor,
          strokeWidth: 2,
        ));
      }

      // 7. Active driving polyline route
      if (_layerRoute && _routePoints.isNotEmpty) {
        _polylines.add(Polyline(
          polylineId: const PolylineId('visit_route'),
          points: _routePoints,
          color: AppTheme.primaryColor,
          width: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ));
      }
    });
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _searchResults = [];
          _showSuggestions = false;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
      _showSuggestions = true;
    });

    final results = <_SearchResult>[];

    // Local patients & villages
    final matchedPatients = _patients.where((p) =>
        p.name.toLowerCase().contains(query.toLowerCase()) ||
        p.village.toLowerCase().contains(query.toLowerCase()));
    for (final p in matchedPatients) {
      results.add(_SearchResult(
        title: p.name,
        subtitle: '${p.village} · Patient (${p.risk} Risk)',
        coords: p.coords,
        isPatient: true,
      ));
    }

    // Geocoding place API
    try {
      final url = 'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5';
      final response = await _dio.get(
        url,
        options: Options(headers: {
          'User-Agent': 'ASHA_CARE_Plus_App/1.0 (com.ashacareplus.app)',
        }),
      );
      if (response.statusCode == 200 && response.data is List) {
        final list = response.data as List;
        for (final item in list) {
          final lat = double.tryParse(item['lat'] ?? '');
          final lon = double.tryParse(item['lon'] ?? '');
          if (lat != null && lon != null) {
            results.add(_SearchResult(
              title: item['display_name'].split(',')[0],
              subtitle: item['display_name'],
              coords: LatLng(lat, lon),
              isPatient: false,
            ));
          }
        }
      }
    } catch (e) {
      debugPrint('Geocoding API search error: $e');
    }

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  Future<void> _calculateRoute(LatLng dest) async {
    setState(() => _isCalcRoute = true);
    final url = 'http://router.project-osrm.org/route/v1/driving/'
        '${_ashaLocation.longitude},${_ashaLocation.latitude};'
        '${dest.longitude},${dest.latitude}'
        '?overview=full&geometries=geojson';
    try {
      final resp = await _dio.get(url);
      if (resp.statusCode == 200 && (resp.data['routes'] as List).isNotEmpty) {
        final route = resp.data['routes'][0];
        final pts = (route['geometry']['coordinates'] as List)
            .map((c) => LatLng(c[1] as double, c[0] as double))
            .toList();
        final dist = (route['distance'] as num) / 1000;
        final dur = (route['duration'] as num) / 60;
        setState(() {
          _routePoints = pts;
          _routeDistText = '${dist.toStringAsFixed(1)} km';
          _routeDurText = '~${dur.toStringAsFixed(0)} min';
          _layerRoute = true;
        });

        // Zoom map bounds to fit route
        if (_mapController != null) {
          _mapController!.animateCamera(CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(
                [_ashaLocation.latitude, dest.latitude].reduce((a, b) => a < b ? a : b),
                [_ashaLocation.longitude, dest.longitude].reduce((a, b) => a < b ? a : b),
              ),
              northeast: LatLng(
                [_ashaLocation.latitude, dest.latitude].reduce((a, b) => a > b ? a : b),
                [_ashaLocation.longitude, dest.longitude].reduce((a, b) => a > b ? a : b),
              ),
            ),
            70,
          ));
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Route: $_routeDistText (${_routeDurText})'),
            backgroundColor: AppTheme.primaryColor,
          ));
        }
      }
    } catch (_) {
      setState(() {
        _routePoints = [_ashaLocation, dest];
        _routeDistText = 'Direct line';
        _routeDurText = 'Offline';
        _layerRoute = true;
      });
    } finally {
      setState(() => _isCalcRoute = false);
      _rebuildOverlays();
    }
  }

  void _showPatientSheet(_Patient p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        final color = _riskColor(p.risk);
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
            Row(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withOpacity(0.12),
                child: Text(p.name[0], style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xff0f172a))),
                Text('Age ${p.age} · Week ${p.pregnancyWeek} · ${p.id}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(p.risk, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
              ),
            ]),
            const Divider(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('ABHA: ${p.abhaStatus}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text('Last: ${p.lastVisit}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('💉 ${p.vaccinationStatus}', style: const TextStyle(fontSize: 12)),
              Text('📞 ${p.phone}', style: const TextStyle(fontSize: 12)),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ElevatedButton.icon(
                onPressed: () { Navigator.pop(context); _calculateRoute(p.coords); },
                icon: const Icon(Icons.navigation_rounded, size: 18),
                label: const Text('Navigate'),
              )),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.medical_services_outlined, size: 18),
                label: const Text('View EHR'),
              )),
            ]),
          ]),
        );
      },
    );
  }

  void _showSearchedPlaceSheet(_SearchResult place) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
            Row(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.amber.withOpacity(0.12),
                child: Icon(Icons.location_on_rounded, size: 28, color: Colors.amber.shade800),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(place.title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xff0f172a))),
                Text('Searched Place', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
              ])),
            ]),
            const Divider(height: 24),
            Text(place.subtitle, style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xff475569))),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _calculateRoute(place.coords);
                },
                icon: const Icon(Icons.navigation_rounded, size: 18),
                label: const Text('Navigate'),
              )),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _searchedPlace = null;
                    _routePoints = [];
                    _routeDistText = '';
                    _routeDurText = '';
                    _layerRoute = false;
                  });
                  _rebuildOverlays();
                },
                icon: const Icon(Icons.clear_rounded, size: 18),
                label: const Text('Clear'),
              )),
            ]),
          ]),
        );
      },
    );
  }

  void _showLayersSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 16),
          Text('Map Layers', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildLayerTile(setS, 'Risk Heatmap', Icons.local_fire_department_rounded, _layerRisk, (v) => setState(() => _layerRisk = v)),
          _buildLayerTile(setS, 'Vaccination Zones', Icons.vaccines_rounded, _layerVaccination, (v) => setState(() => _layerVaccination = v)),
          _buildLayerTile(setS, 'Pregnancy Density', Icons.pregnant_woman_rounded, _layerPregnancy, (v) => setState(() => _layerPregnancy = v)),
          _buildLayerTile(setS, 'Outbreak Warning', Icons.warning_amber_rounded, _layerOutbreak, (v) => setState(() => _layerOutbreak = v)),
          _buildLayerTile(setS, 'Visit Route', Icons.route_rounded, _layerRoute, (v) => setState(() => _layerRoute = v)),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text('Satellite View'),
            trailing: Switch(
              value: _mapType == MapType.satellite,
              onChanged: (v) {
                setS(() {});
                setState(() {
                  _mapType = v ? MapType.satellite : MapType.normal;
                  _rebuildOverlays();
                });
              },
              activeColor: AppTheme.primaryColor,
            ),
          ),
        ]),
      )),
    );
  }

  Widget _buildLayerTile(StateSetter setS, String label, IconData icon, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppTheme.primaryColor, size: 22),
      title: Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
      value: value,
      activeColor: AppTheme.primaryColor,
      onChanged: (v) {
        setS(() {});
        onChanged(v);
        _rebuildOverlays();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('EHR GIS Map', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        actions: [
          if (_isCalcRoute)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            ),
          IconButton(icon: const Icon(Icons.layers_rounded), onPressed: _showLayersSheet, tooltip: 'Layers'),
        ],
      ),
      body: Stack(children: [
        // Real Google Maps Layer
        GoogleMap(
          onMapCreated: _onMapCreated,
          mapType: _mapType,
          initialCameraPosition: CameraPosition(target: _ashaLocation, zoom: 14.0),
          markers: _markers,
          polylines: _polylines,
          circles: _circles,
          polygons: _polygons,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          compassEnabled: true,
          zoomControlsEnabled: false,
          tiltGesturesEnabled: true,
          rotateGesturesEnabled: true,
          buildingsEnabled: true,
          onTap: (_) => setState(() => _showSuggestions = false),
        ),

        // Search Bar
        Positioned(
          top: 12, left: 12, right: 12,
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 3))],
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search patients, places...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {
                              _showSuggestions = false;
                              _searchResults = [];
                              _searchedPlace = null;
                            });
                            _rebuildOverlays();
                          },
                        )
                      : null,
                ),
              ),
            ),
            if (_showSuggestions)
              Container(
                margin: const EdgeInsets.only(top: 6),
                constraints: const BoxConstraints(maxHeight: 240),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : _searchResults.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: Text('No matching places or patients found', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _searchResults.length,
                            itemBuilder: (ctx, idx) {
                              final item = _searchResults[idx];
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: item.isPatient
                                      ? AppTheme.primaryColor.withOpacity(0.12)
                                      : Colors.amber.withOpacity(0.12),
                                  child: Icon(
                                    item.isPatient ? Icons.person_rounded : Icons.location_on_rounded,
                                    size: 16,
                                    color: item.isPatient ? AppTheme.primaryColor : Colors.amber.shade800,
                                  ),
                                ),
                                title: Text(item.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                                subtitle: Text(item.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                                onTap: () {
                                  _searchCtrl.text = item.title;
                                  setState(() {
                                    _showSuggestions = false;
                                    if (!item.isPatient) {
                                      _searchedPlace = item;
                                    } else {
                                      _searchedPlace = null;
                                    }
                                  });
                                  
                                  if (_mapController != null) {
                                    _mapController!.animateCamera(CameraUpdate.newLatLngZoom(item.coords, 16.0));
                                  }
                                  _rebuildOverlays();

                                  if (item.isPatient) {
                                    final p = _patients.firstWhere(
                                      (pat) => pat.name == item.title,
                                      orElse: () => _patients.first,
                                    );
                                    _showPatientSheet(p);
                                  } else {
                                    _showSearchedPlaceSheet(item);
                                  }
                                },
                              );
                            },
                          ),
              ),
          ]),
        ),

        // Route info banner
        if (_layerRoute && _routeDistText.isNotEmpty)
          Positioned(
            bottom: 90, left: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.navigation_rounded, color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Route Active', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600)),
                  Text('$_routeDistText  ·  $_routeDurText', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
                ]),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() {
                    _layerRoute = false;
                    _routePoints = [];
                    _routeDistText = '';
                    _rebuildOverlays();
                  }),
                  child: const Text('Clear', style: TextStyle(color: Colors.red)),
                ),
              ]),
            ),
          ),

        // Filter chips
        Positioned(
          bottom: 12, left: 12, right: 12,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', 'High Risk', 'Pregnant Mothers', 'Vaccination Due'].map((f) {
                final selected = _selectedFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f),
                    selected: selected,
                    selectedColor: AppTheme.primaryColor,
                    checkmarkColor: Colors.white,
                    backgroundColor: Colors.white,
                    elevation: selected ? 0 : 2,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : const Color(0xff0f172a),
                      fontWeight: FontWeight.bold, fontSize: 12,
                    ),
                    onSelected: (_) => setState(() {
                      _selectedFilter = f;
                      _rebuildOverlays();
                    }),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // FAB controls
        Positioned(
          right: 12, bottom: 90,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            FloatingActionButton.small(
              heroTag: 'gps',
              backgroundColor: _isTracking ? AppTheme.primaryColor : Colors.white,
              foregroundColor: _isTracking ? Colors.white : AppTheme.primaryColor,
              elevation: 4,
              onPressed: () {
                setState(() => _isTracking = !_isTracking);
                if (_isTracking && _mapController != null) {
                  _mapController!.animateCamera(CameraUpdate.newLatLng(_ashaLocation));
                }
              },
              child: const Icon(Icons.gps_fixed_rounded),
            ),
            const SizedBox(height: 8),
            FloatingActionButton.small(
              heroTag: 'zoomin',
              backgroundColor: Colors.white, foregroundColor: const Color(0xff0f172a), elevation: 4,
              onPressed: () {
                _mapController?.animateCamera(CameraUpdate.zoomIn());
              },
              child: const Icon(Icons.add),
            ),
            const SizedBox(height: 8),
            FloatingActionButton.small(
              heroTag: 'zoomout',
              backgroundColor: Colors.white, foregroundColor: const Color(0xff0f172a), elevation: 4,
              onPressed: () {
                _mapController?.animateCamera(CameraUpdate.zoomOut());
              },
              child: const Icon(Icons.remove),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Patient {
  final String id, name, village, risk, phone, vaccinationStatus, abhaStatus, lastVisit;
  final int age, pregnancyWeek;
  final LatLng coords;
  _Patient({required this.id, required this.name, required this.age, required this.village,
    required this.risk, required this.phone, required this.pregnancyWeek,
    required this.vaccinationStatus, required this.abhaStatus, required this.coords, required this.lastVisit});
}

class _SearchResult {
  final String title;
  final String subtitle;
  final LatLng coords;
  final bool isPatient;

  _SearchResult({
    required this.title,
    required this.subtitle,
    required this.coords,
    required this.isPatient,
  });
}
