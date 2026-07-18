import 'google_maps_service_stub.dart'
    if (dart.library.js) 'google_maps_service_web.dart'
    if (dart.library.io) 'google_maps_service_mobile.dart' as impl;

class GoogleMapsPlaceDetails {
  final double latitude;
  final double longitude;
  final String placeId;
  final String village;
  final String taluk;
  final String district;
  final String state;
  final String country;
  final String postalCode;
  final String formattedAddress;

  GoogleMapsPlaceDetails({
    required this.latitude,
    required this.longitude,
    required this.placeId,
    required this.village,
    required this.taluk,
    required this.district,
    required this.state,
    required this.country,
    required this.postalCode,
    required this.formattedAddress,
  });
}

class GoogleMapsService {
  static final Map<String, GoogleMapsPlaceDetails> _localFallbackLocations = {
    'Alanganallur, Madurai, Tamil Nadu, India': GoogleMapsPlaceDetails(
      latitude: 9.9739,
      longitude: 78.1196,
      placeId: 'fallback_alanganallur',
      village: 'Alanganallur',
      taluk: 'Vadipatti',
      district: 'Madurai',
      state: 'Tamil Nadu',
      country: 'India',
      postalCode: '625501',
      formattedAddress: 'Alanganallur, Madurai, Tamil Nadu, India',
    ),
    'Bengaluru, Karnataka, India': GoogleMapsPlaceDetails(
      latitude: 12.9716,
      longitude: 77.5946,
      placeId: 'fallback_bengaluru',
      village: 'Bengaluru',
      taluk: 'Bengaluru North',
      district: 'Bengaluru',
      state: 'Karnataka',
      country: 'India',
      postalCode: '560001',
      formattedAddress: 'Bengaluru, Karnataka, India',
    ),
    'Chennai, Tamil Nadu, India': GoogleMapsPlaceDetails(
      latitude: 13.0827,
      longitude: 80.2707,
      placeId: 'fallback_chennai',
      village: 'Chennai',
      taluk: 'Egmore',
      district: 'Chennai',
      state: 'Tamil Nadu',
      country: 'India',
      postalCode: '600001',
      formattedAddress: 'Chennai, Tamil Nadu, India',
    ),
    'Coimbatore, Tamil Nadu, India': GoogleMapsPlaceDetails(
      latitude: 11.0168,
      longitude: 76.9558,
      placeId: 'fallback_coimbatore',
      village: 'Coimbatore',
      taluk: 'Coimbatore North',
      district: 'Coimbatore',
      state: 'Tamil Nadu',
      country: 'India',
      postalCode: '641001',
      formattedAddress: 'Coimbatore, Tamil Nadu, India',
    ),
    'Chidambaram, Tamil Nadu, India': GoogleMapsPlaceDetails(
      latitude: 11.3995,
      longitude: 79.6936,
      placeId: 'fallback_chidambaram',
      village: 'Chidambaram',
      taluk: 'Chidambaram',
      district: 'Cuddalore',
      state: 'Tamil Nadu',
      country: 'India',
      postalCode: '608001',
      formattedAddress: 'Chidambaram, Tamil Nadu, India',
    ),
    'Cuddalore, Tamil Nadu, India': GoogleMapsPlaceDetails(
      latitude: 11.7480,
      longitude: 79.7714,
      placeId: 'fallback_cuddalore',
      village: 'Cuddalore',
      taluk: 'Cuddalore',
      district: 'Cuddalore',
      state: 'Tamil Nadu',
      country: 'India',
      postalCode: '607001',
      formattedAddress: 'Cuddalore, Tamil Nadu, India',
    ),
    'Dharmapuri, Tamil Nadu, India': GoogleMapsPlaceDetails(
      latitude: 12.1211,
      longitude: 78.1582,
      placeId: 'fallback_dharmapuri',
      village: 'Dharmapuri',
      taluk: 'Dharmapuri',
      district: 'Dharmapuri',
      state: 'Tamil Nadu',
      country: 'India',
      postalCode: '636701',
      formattedAddress: 'Dharmapuri, Tamil Nadu, India',
    ),
    'Erode, Tamil Nadu, India': GoogleMapsPlaceDetails(
      latitude: 11.3410,
      longitude: 77.7172,
      placeId: 'fallback_erode',
      village: 'Erode',
      taluk: 'Erode',
      district: 'Erode',
      state: 'Tamil Nadu',
      country: 'India',
      postalCode: '638001',
      formattedAddress: 'Erode, Tamil Nadu, India',
    ),
    'Faridabad, Haryana, India': GoogleMapsPlaceDetails(
      latitude: 28.4089,
      longitude: 77.3178,
      placeId: 'fallback_faridabad',
      village: 'Faridabad',
      taluk: 'Faridabad',
      district: 'Faridabad',
      state: 'Haryana',
      country: 'India',
      postalCode: '121001',
      formattedAddress: 'Faridabad, Haryana, India',
    ),
    'Gandhinagar, Gujarat, India': GoogleMapsPlaceDetails(
      latitude: 23.2156,
      longitude: 72.6369,
      placeId: 'fallback_gandhinagar',
      village: 'Gandhinagar',
      taluk: 'Gandhinagar',
      district: 'Gandhinagar',
      state: 'Gujarat',
      country: 'India',
      postalCode: '382010',
      formattedAddress: 'Gandhinagar, Gujarat, India',
    ),
    'Hosur, Krishnagiri, Tamil Nadu, India': GoogleMapsPlaceDetails(
      latitude: 12.7409,
      longitude: 77.8253,
      placeId: 'fallback_hosur',
      village: 'Hosur',
      taluk: 'Hosur',
      district: 'Krishnagiri',
      state: 'Tamil Nadu',
      country: 'India',
      postalCode: '635109',
      formattedAddress: 'Hosur, Krishnagiri, Tamil Nadu, India',
    ),
    'Indore, Madhya Pradesh, India': GoogleMapsPlaceDetails(
      latitude: 22.7196,
      longitude: 75.8577,
      placeId: 'fallback_indore',
      village: 'Indore',
      taluk: 'Indore',
      district: 'Indore',
      state: 'Madhya Pradesh',
      country: 'India',
      postalCode: '452001',
      formattedAddress: 'Indore, Madhya Pradesh, India',
    ),
    'Jaipur, Rajasthan, India': GoogleMapsPlaceDetails(
      latitude: 26.9124,
      longitude: 75.7873,
      placeId: 'fallback_jaipur',
      village: 'Jaipur',
      taluk: 'Jaipur',
      district: 'Jaipur',
      state: 'Rajasthan',
      country: 'India',
      postalCode: '302001',
      formattedAddress: 'Jaipur, Rajasthan, India',
    ),
    'Kanchipuram, Tamil Nadu, India': GoogleMapsPlaceDetails(
      latitude: 12.8387,
      longitude: 79.7016,
      placeId: 'fallback_kanchipuram',
      village: 'Kanchipuram',
      taluk: 'Kanchipuram',
      district: 'Kanchipuram',
      state: 'Tamil Nadu',
      country: 'India',
      postalCode: '631501',
      formattedAddress: 'Kanchipuram, Tamil Nadu, India',
    ),
    'Kanyakumari, Tamil Nadu, India': GoogleMapsPlaceDetails(
      latitude: 8.0883,
      longitude: 77.5385,
      placeId: 'fallback_kanyakumari',
      village: 'Kanyakumari',
      taluk: 'Agastheeswaram',
      district: 'Kanyakumari',
      state: 'Tamil Nadu',
      country: 'India',
      postalCode: '629001',
      formattedAddress: 'Kanyakumari, Tamil Nadu, India',
    ),
    'Lalgudi, Trichy, Tamil Nadu, India': GoogleMapsPlaceDetails(
      latitude: 10.8694,
      longitude: 78.8284,
      placeId: 'fallback_lalgudi',
      village: 'Lalgudi',
      taluk: 'Lalgudi',
      district: 'Tiruchirappalli',
      state: 'Tamil Nadu',
      country: 'India',
      postalCode: '621601',
      formattedAddress: 'Lalgudi, Trichy, Tamil Nadu, India',
    ),
    'Madurai, Tamil Nadu, India': GoogleMapsPlaceDetails(
      latitude: 9.9252,
      longitude: 78.1198,
      placeId: 'fallback_madurai',
      village: 'Madurai',
      taluk: 'Madurai South',
      district: 'Madurai',
      state: 'Tamil Nadu',
      country: 'India',
      postalCode: '625001',
      formattedAddress: 'Madurai, Tamil Nadu, India',
    ),
    'Melur, Madurai, Tamil Nadu, India': GoogleMapsPlaceDetails(
      latitude: 9.9984,
      longitude: 78.3370,
      placeId: 'fallback_melur',
      village: 'Melur',
      taluk: 'Melur',
      district: 'Madurai',
      state: 'Tamil Nadu',
      country: 'India',
      postalCode: '625106',
      formattedAddress: 'Melur, Madurai, Tamil Nadu, India',
    ),
    'Nagercoil, Tamil Nadu, India': GoogleMapsPlaceDetails(
      latitude: 8.1830,
      longitude: 77.4119,
      placeId: 'fallback_nagercoil',
      village: 'Nagercoil',
      taluk: 'Agastheeswaram',
      district: 'Kanyakumari',
      state: 'Tamil Nadu',
      country: 'India',
      postalCode: '629001',
      formattedAddress: 'Nagercoil, Tamil Nadu, India',
    ),
    'Ooty, The Nilgiris, Tamil Nadu, India': GoogleMapsPlaceDetails(
      latitude: 11.4102,
      longitude: 76.6950,
      placeId: 'fallback_ooty',
      village: 'Ooty',
      taluk: 'Udhagamandalam',
      district: 'The Nilgiris',
      state: 'Tamil Nadu',
      country: 'India',
      postalCode: '643001',
      formattedAddress: 'Ooty, The Nilgiris, Tamil Nadu, India',
    ),
    'Pondicherry, Puducherry, India': GoogleMapsPlaceDetails(
      latitude: 11.9416,
      longitude: 79.8083,
      placeId: 'fallback_pondicherry',
      village: 'Pondicherry',
      taluk: 'Pondicherry',
      district: 'Pondicherry',
      state: 'Puducherry',
      country: 'India',
      postalCode: '605001',
      formattedAddress: 'Pondicherry, Puducherry, India',
    ),
    'Quilon (Kollam), Kerala, India': GoogleMapsPlaceDetails(
      latitude: 8.8932,
      longitude: 76.6141,
      placeId: 'fallback_quilon',
      village: 'Kollam',
      taluk: 'Kollam',
      district: 'Kollam',
      state: 'Kerala',
      country: 'India',
      postalCode: '691001',
      formattedAddress: 'Quilon (Kollam), Kerala, India',
    ),
    'Rameshwaram, Ramanathapuram, Tamil Nadu, India': GoogleMapsPlaceDetails(
      latitude: 9.2876,
      longitude: 79.3129,
      placeId: 'fallback_rameshwaram',
      village: 'Rameshwaram',
      taluk: 'Rameshwaram',
      district: 'Ramanathapuram',
      state: 'Tamil Nadu',
      country: 'India',
      postalCode: '623526',
      formattedAddress: 'Rameshwaram, Ramanathapuram, Tamil Nadu, India',
    ),
    'Salem, Tamil Nadu, India': GoogleMapsPlaceDetails(
      latitude: 11.6643,
      longitude: 78.1460,
      placeId: 'fallback_salem',
      village: 'Salem',
      taluk: 'Salem',
      district: 'Salem',
      state: 'Tamil Nadu',
      country: 'India',
      postalCode: '636001',
      formattedAddress: 'Salem, Tamil Nadu, India',
    ),
    'Trichy, Tamil Nadu, India': GoogleMapsPlaceDetails(
      latitude: 10.7905,
      longitude: 78.7047,
      placeId: 'fallback_trichy',
      village: 'Trichy',
      taluk: 'Tiruchirappalli',
      district: 'Tiruchirappalli',
      state: 'Tamil Nadu',
      country: 'India',
      postalCode: '620001',
      formattedAddress: 'Trichy, Tamil Nadu, India',
    ),
    'Tirunelveli, Tamil Nadu, India': GoogleMapsPlaceDetails(
      latitude: 8.7139,
      longitude: 77.7567,
      placeId: 'fallback_tirunelveli',
      village: 'Tirunelveli',
      taluk: 'Tirunelveli',
      district: 'Tirunelveli',
      state: 'Tamil Nadu',
      country: 'India',
      postalCode: '627001',
      formattedAddress: 'Tirunelveli, Tamil Nadu, India',
    ),
    'Thanjavur, Tamil Nadu, India': GoogleMapsPlaceDetails(
      latitude: 10.7870,
      longitude: 79.1378,
      placeId: 'fallback_thanjavur',
      village: 'Thanjavur',
      taluk: 'Thanjavur',
      district: 'Thanjavur',
      state: 'Tamil Nadu',
      country: 'India',
      postalCode: '613001',
      formattedAddress: 'Thanjavur, Tamil Nadu, India',
    ),
    'Udupi, Karnataka, India': GoogleMapsPlaceDetails(
      latitude: 13.3409,
      longitude: 74.7421,
      placeId: 'fallback_udupi',
      village: 'Udupi',
      taluk: 'Udupi',
      district: 'Udupi',
      state: 'Karnataka',
      country: 'India',
      postalCode: '576101',
      formattedAddress: 'Udupi, Karnataka, India',
    ),
    'Vellore, Tamil Nadu, India': GoogleMapsPlaceDetails(
      latitude: 12.9165,
      longitude: 79.1325,
      placeId: 'fallback_vellore',
      village: 'Vellore',
      taluk: 'Vellore',
      district: 'Vellore',
      state: 'Tamil Nadu',
      country: 'India',
      postalCode: '632001',
      formattedAddress: 'Vellore, Tamil Nadu, India',
    ),
    'Wardha, Maharashtra, India': GoogleMapsPlaceDetails(
      latitude: 20.7453,
      longitude: 78.6022,
      placeId: 'fallback_wardha',
      village: 'Wardha',
      taluk: 'Wardha',
      district: 'Wardha',
      state: 'Maharashtra',
      country: 'India',
      postalCode: '442001',
      formattedAddress: 'Wardha, Maharashtra, India',
    ),
    'Xavier Nagar, Tirunelveli, Tamil Nadu, India': GoogleMapsPlaceDetails(
      latitude: 8.7200,
      longitude: 77.7600,
      placeId: 'fallback_xaviernagar',
      village: 'Xavier Nagar',
      taluk: 'Tirunelveli',
      district: 'Tirunelveli',
      state: 'Tamil Nadu',
      country: 'India',
      postalCode: '627002',
      formattedAddress: 'Xavier Nagar, Tirunelveli, Tamil Nadu, India',
    ),
    'Yercaud, Salem, Tamil Nadu, India': GoogleMapsPlaceDetails(
      latitude: 11.7753,
      longitude: 78.2093,
      placeId: 'fallback_yercaud',
      village: 'Yercaud',
      taluk: 'Yercaud',
      district: 'Salem',
      state: 'Tamil Nadu',
      country: 'India',
      postalCode: '636601',
      formattedAddress: 'Yercaud, Salem, Tamil Nadu, India',
    ),
    'Zamin Uthukuli, Pollachi, Tamil Nadu, India': GoogleMapsPlaceDetails(
      latitude: 10.6653,
      longitude: 77.0012,
      placeId: 'fallback_zaminuthukuli',
      village: 'Zamin Uthukuli',
      taluk: 'Pollachi',
      district: 'Coimbatore',
      state: 'Tamil Nadu',
      country: 'India',
      postalCode: '642004',
      formattedAddress: 'Zamin Uthukuli, Pollachi, Tamil Nadu, India',
    ),
  };

  static List<String> _getLocalFallbackSuggestions(String input) {
    final query = input.trim().toLowerCase();
    if (query.isEmpty) return [];

    return _localFallbackLocations.keys
        .where((address) => address.toLowerCase().contains(query))
        .toList();
  }

  static GoogleMapsPlaceDetails? _getLocalPlaceDetails(String address) {
    // Exact or partial match
    final matchedKey = _localFallbackLocations.keys.firstWhere(
      (key) => key.toLowerCase() == address.toLowerCase(),
      orElse: () => _localFallbackLocations.keys.firstWhere(
        (key) => key.toLowerCase().contains(address.toLowerCase()),
        orElse: () => '',
      ),
    );

    if (matchedKey.isNotEmpty) {
      return _localFallbackLocations[matchedKey];
    }

    // Dynamic generation as safety fallback
    return GoogleMapsPlaceDetails(
      latitude: 9.9252, // Default Madurai coordinates
      longitude: 78.1198,
      placeId: 'mock_place_${address.hashCode}',
      village: address,
      taluk: 'Madurai East',
      district: 'Madurai',
      state: 'Tamil Nadu',
      country: 'India',
      postalCode: '625001',
      formattedAddress: address,
    );
  }

  static GoogleMapsPlaceDetails? _getLocalPlaceDetailsByCoordinates(double lat, double lng) {
    // Return nearest offline cached location or default to dynamic coordinates
    for (final details in _localFallbackLocations.values) {
      final diffLat = (details.latitude - lat).abs();
      final diffLng = (details.longitude - lng).abs();
      if (diffLat < 0.05 && diffLng < 0.05) {
        return details;
      }
    }

    return GoogleMapsPlaceDetails(
      latitude: lat,
      longitude: lng,
      placeId: 'mock_gps_${lat.toStringAsFixed(4)}_${lng.toStringAsFixed(4)}',
      village: 'Geolocated Area',
      taluk: 'Local Taluk',
      district: 'District',
      state: 'State',
      country: 'India',
      postalCode: '000000',
      formattedAddress: 'GPS Location (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})',
    );
  }

  static Future<List<String>> getAutocompleteSuggestions(String input) async {
    try {
      final suggestions = await impl.getAutocompleteSuggestions(input);
      if (suggestions.isEmpty && input.trim().isNotEmpty) {
        return _getLocalFallbackSuggestions(input);
      }
      return suggestions;
    } catch (_) {
      return _getLocalFallbackSuggestions(input);
    }
  }

  static Future<GoogleMapsPlaceDetails?> getPlaceDetails(String address) async {
    try {
      final details = await impl.getPlaceDetails(address);
      if (details == null) {
        return _getLocalPlaceDetails(address);
      }
      return details;
    } catch (_) {
      return _getLocalPlaceDetails(address);
    }
  }

  static Future<GoogleMapsPlaceDetails?> getPlaceDetailsByCoordinates(double lat, double lng) async {
    try {
      final details = await impl.getPlaceDetailsByCoordinates(lat, lng);
      if (details == null) {
        return _getLocalPlaceDetailsByCoordinates(lat, lng);
      }
      return details;
    } catch (_) {
      return _getLocalPlaceDetailsByCoordinates(lat, lng);
    }
  }
}
