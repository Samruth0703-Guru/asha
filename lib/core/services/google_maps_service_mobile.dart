import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'google_maps_service.dart';

const String _apiKey = 'AIzaSyBA9GgVEE6pcdWdKo2svvcP6zFc9Ds2bI8';

final Dio _dio = Dio(BaseOptions(
  connectTimeout: const Duration(seconds: 2),
  receiveTimeout: const Duration(seconds: 2),
));

Future<List<String>> _getGeocodeSearchSuggestions(String input) async {
  try {
    final dio = _dio;
    final response = await dio.get(
      'https://maps.googleapis.com/maps/api/geocode/json',
      queryParameters: {
        'address': input,
        'key': _apiKey,
      },
    );
    
    if (response.statusCode == 200 && response.data != null) {
      final status = response.data['status']?.toString() ?? 'UNKNOWN';
      if (status == 'OK' && (response.data['results'] as List).isNotEmpty) {
        final results = response.data['results'] as List;
        final suggestions = results.map((r) => r['formatted_address'].toString()).toList();
        debugPrint('[Geocoding Fallback] Found ${suggestions.length} results for "$input"');
        return suggestions;
      } else if (status == 'REQUEST_DENIED') {
        final errorMsg = response.data['error_message']?.toString() ?? 'Unknown error';
        debugPrint('[Geocoding Fallback] REQUEST_DENIED: $errorMsg');
      } else if (status == 'ZERO_RESULTS') {
        debugPrint('[Geocoding Fallback] No results found for "$input"');
      } else {
        debugPrint('[Geocoding Fallback] Status: $status for "$input"');
      }
    }
  } catch (e) {
    debugPrint('[Geocoding Fallback] Exception: $e');
  }
  return [];
}

Future<List<String>> getAutocompleteSuggestions(String input) async {
  try {
    final dio = _dio;
    final response = await dio.get(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json',
      queryParameters: {
        'input': input,
        'types': 'geocode|establishment',
        'key': _apiKey,
      },
    );
    
    if (response.statusCode == 200 && response.data != null) {
      final status = response.data['status']?.toString() ?? 'UNKNOWN';
      if (status == 'OK') {
        final predictions = response.data['predictions'] as List;
        debugPrint('[Places API] Found ${predictions.length} predictions for "$input"');
        return predictions.map((p) => p['description'].toString()).toList();
      }
      final errorMsg = response.data['error_message']?.toString() ?? '';
      debugPrint('[Places API] Status: $status | Error: $errorMsg — falling back to Geocoding');
    }
  } catch (e) {
    debugPrint('[Places API] Exception: $e — falling back to Geocoding');
  }
  
  // Fall back to Geocoding suggestions if Places API failed or returned REQUEST_DENIED
  return _getGeocodeSearchSuggestions(input);
}

Future<GoogleMapsPlaceDetails?> getPlaceDetails(String address) async {
  try {
    final dio = _dio;
    final response = await dio.get(
      'https://maps.googleapis.com/maps/api/geocode/json',
      queryParameters: {
        'address': address,
        'key': _apiKey,
      },
    );
    
    if (response.statusCode == 200 && response.data != null && (response.data['results'] as List).isNotEmpty) {
      final first = response.data['results'][0];
      final geometry = first['geometry'];
      final location = geometry['location'];
      final lat = location['lat'] as double;
      final lng = location['lng'] as double;
      final placeId = first['place_id'].toString();
      final formatted = first['formatted_address'].toString();

      final components = first['address_components'] as List;
      String? village;
      String? taluk;
      String? district;
      String? state;
      String? country;
      String? postalCode;

      for (final comp in components) {
        final types = comp['types'] as List;
        if (types.contains('locality') || types.contains('sublocality_level_1')) {
          village = comp['long_name'].toString();
        } else if (types.contains('administrative_area_level_3')) {
          taluk = comp['long_name'].toString();
        } else if (types.contains('administrative_area_level_2')) {
          district = comp['long_name'].toString();
        } else if (types.contains('administrative_area_level_1')) {
          state = comp['long_name'].toString();
        } else if (types.contains('country')) {
          country = comp['long_name'].toString();
        } else if (types.contains('postal_code')) {
          postalCode = comp['long_name'].toString();
        }
      }

      return GoogleMapsPlaceDetails(
        latitude: lat,
        longitude: lng,
        placeId: placeId,
        village: village ?? '',
        taluk: taluk ?? '',
        district: district ?? '',
        state: state ?? '',
        country: country ?? '',
        postalCode: postalCode ?? '',
        formattedAddress: formatted,
      );
    }
  } catch (e) {
    // Fallback/log
  }
  return null;
}

Future<GoogleMapsPlaceDetails?> getPlaceDetailsByCoordinates(double lat, double lng) async {
  try {
    final dio = _dio;
    final response = await dio.get(
      'https://maps.googleapis.com/maps/api/geocode/json',
      queryParameters: {
        'latlng': '$lat,$lng',
        'key': _apiKey,
      },
    );
    
    if (response.statusCode == 200 && response.data != null && (response.data['results'] as List).isNotEmpty) {
      final first = response.data['results'][0];
      final geometry = first['geometry'];
      final location = geometry['location'];
      final resLat = location['lat'] as double;
      final resLng = location['lng'] as double;
      final placeId = first['place_id'].toString();
      final formatted = first['formatted_address'].toString();

      final components = first['address_components'] as List;
      String? village;
      String? taluk;
      String? district;
      String? state;
      String? country;
      String? postalCode;

      for (final comp in components) {
        final types = comp['types'] as List;
        if (types.contains('locality') || types.contains('sublocality_level_1')) {
          village = comp['long_name'].toString();
        } else if (types.contains('administrative_area_level_3')) {
          taluk = comp['long_name'].toString();
        } else if (types.contains('administrative_area_level_2')) {
          district = comp['long_name'].toString();
        } else if (types.contains('administrative_area_level_1')) {
          state = comp['long_name'].toString();
        } else if (types.contains('country')) {
          country = comp['long_name'].toString();
        } else if (types.contains('postal_code')) {
          postalCode = comp['long_name'].toString();
        }
      }

      return GoogleMapsPlaceDetails(
        latitude: resLat,
        longitude: resLng,
        placeId: placeId,
        village: village ?? '',
        taluk: taluk ?? '',
        district: district ?? '',
        state: state ?? '',
        country: country ?? '',
        postalCode: postalCode ?? '',
        formattedAddress: formatted,
      );
    }
  } catch (e) {
    // Fallback/log
  }
  return null;
}
