import 'dart:async';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'google_maps_service.dart';

Future<List<String>> _getGeocodeSearchSuggestions(String input) {
  final completer = Completer<List<String>>();
  final timeoutTimer = Timer(const Duration(milliseconds: 400), () {
    if (!completer.isCompleted) {
      debugPrint('[Web Geocoding Fallback] Timeout occurred for "$input"');
      completer.complete([]);
    }
  });

  try {
    final google = js.context['google'];
    if (google == null) {
      timeoutTimer.cancel();
      debugPrint('[Web Geocoding Fallback] google.maps not loaded');
      completer.complete([]);
      return completer.future;
    }
    final maps = google['maps'];
    final geocoder = js.JsObject(maps['Geocoder']);
    
    final request = js.JsObject.jsify({'address': input});

    geocoder.callMethod('geocode', [
      request,
      (results, status) {
        timeoutTimer.cancel();
        if (status.toString() == 'OK' && results != null) {
          final list = <String>[];
          final len = results['length'] as int;
          for (var i = 0; i < len; i++) {
            list.add(results[i]['formatted_address'].toString());
          }
          debugPrint('[Web Geocoding Fallback] Found ${list.length} results for "$input"');
          completer.complete(list);
        } else {
          debugPrint('[Web Geocoding Fallback] Status: $status for "$input"');
          completer.complete([]);
        }
      }
    ]);
  } catch (e) {
    timeoutTimer.cancel();
    debugPrint('[Web Geocoding Fallback] Exception: $e');
    completer.complete([]);
  }
  return completer.future;
}

Future<List<String>> getAutocompleteSuggestions(String input) {
  final completer = Completer<List<String>>();
  final timeoutTimer = Timer(const Duration(milliseconds: 400), () {
    if (!completer.isCompleted) {
      debugPrint('[Web Places API] Timeout occurred for "$input" — falling back to Geocoding');
      _getGeocodeSearchSuggestions(input).then((fallbackList) {
        if (!completer.isCompleted) completer.complete(fallbackList);
      }).catchError((_) {
        if (!completer.isCompleted) completer.complete([]);
      });
    }
  });

  try {
    final google = js.context['google'];
    if (google == null) {
      timeoutTimer.cancel();
      debugPrint('[Web Places API] google.maps not loaded — falling back to Geocoding');
      _getGeocodeSearchSuggestions(input).then(completer.complete);
      return completer.future;
    }
    final maps = google['maps'];
    final places = maps['places'];
    final service = js.JsObject(places['AutocompleteService']);
    
    final request = js.JsObject.jsify({
      'input': input,
      'types': ['geocode', 'establishment'],
    });

    service.callMethod('getPlacePredictions', [
      request,
      (predictions, status) async {
        timeoutTimer.cancel();
        if (completer.isCompleted) return;
        if (status.toString() == 'OK' && predictions != null) {
          final list = <String>[];
          final len = predictions['length'] as int;
          for (var i = 0; i < len; i++) {
            list.add(predictions[i]['description'].toString());
          }
          debugPrint('[Web Places API] Found ${list.length} predictions for "$input"');
          completer.complete(list);
        } else {
          debugPrint('[Web Places API] Status: $status — falling back to Geocoding');
          final fallbackList = await _getGeocodeSearchSuggestions(input);
          completer.complete(fallbackList);
        }
      }
    ]);
  } catch (e) {
    timeoutTimer.cancel();
    if (!completer.isCompleted) {
      debugPrint('[Web Places API] Exception: $e — falling back to Geocoding');
      _getGeocodeSearchSuggestions(input).then((fallbackList) {
        completer.complete(fallbackList);
      }).catchError((_) {
        completer.complete([]);
      });
    }
  }
  return completer.future;
}

Future<GoogleMapsPlaceDetails?> getPlaceDetails(String address) {
  final completer = Completer<GoogleMapsPlaceDetails?>();
  final timeoutTimer = Timer(const Duration(milliseconds: 500), () {
    if (!completer.isCompleted) {
      debugPrint('[Web Geocoding Details] Timeout occurred for "$address"');
      completer.complete(null);
    }
  });

  try {
    final google = js.context['google'];
    if (google == null) {
      timeoutTimer.cancel();
      completer.complete(null);
      return completer.future;
    }
    final maps = google['maps'];
    final geocoder = js.JsObject(maps['Geocoder']);
    
    final request = js.JsObject.jsify({'address': address});

    geocoder.callMethod('geocode', [
      request,
      (results, status) {
        timeoutTimer.cancel();
        if (completer.isCompleted) return;
        if (status.toString() == 'OK' && results != null && results['length'] as int > 0) {
          final first = results[0];
          final location = first['geometry']['location'];
          final lat = location.callMethod('lat') as double;
          final lng = location.callMethod('lng') as double;
          final placeId = first['place_id'].toString();
          final formatted = first['formatted_address'].toString();
          
          final components = first['address_components'];
          final compLen = components['length'] as int;
          
          String village = '';
          String taluk = '';
          String district = '';
          String state = '';
          String country = '';
          String postalCode = '';

          for (var i = 0; i < compLen; i++) {
            final comp = components[i];
            final types = comp['types'];
            final typesLen = types['length'] as int;
            final typeList = <String>[];
            for (var j = 0; j < typesLen; j++) {
              typeList.add(types[j].toString());
            }
            
            if (typeList.contains('locality') || typeList.contains('sublocality_level_1')) {
              village = comp['long_name'].toString();
            } else if (typeList.contains('administrative_area_level_3')) {
              taluk = comp['long_name'].toString();
            } else if (typeList.contains('administrative_area_level_2')) {
              district = comp['long_name'].toString();
            } else if (typeList.contains('administrative_area_level_1')) {
              state = comp['long_name'].toString();
            } else if (typeList.contains('country')) {
              country = comp['long_name'].toString();
            } else if (typeList.contains('postal_code')) {
              postalCode = comp['long_name'].toString();
            }
          }

          completer.complete(GoogleMapsPlaceDetails(
            latitude: lat,
            longitude: lng,
            placeId: placeId,
            village: village,
            taluk: taluk,
            district: district,
            state: state,
            country: country,
            postalCode: postalCode,
            formattedAddress: formatted,
          ));
        } else {
          completer.complete(null);
        }
      }
    ]);
  } catch (e) {
    timeoutTimer.cancel();
    if (!completer.isCompleted) {
      completer.complete(null);
    }
  }
  return completer.future;
}

Future<GoogleMapsPlaceDetails?> getPlaceDetailsByCoordinates(double lat, double lng) {
  final completer = Completer<GoogleMapsPlaceDetails?>();
  final timeoutTimer = Timer(const Duration(milliseconds: 500), () {
    if (!completer.isCompleted) {
      debugPrint('[Web Reverse Geocoding] Timeout occurred for coordinates ($lat, $lng)');
      completer.complete(null);
    }
  });

  try {
    final google = js.context['google'];
    if (google == null) {
      timeoutTimer.cancel();
      completer.complete(null);
      return completer.future;
    }
    final maps = google['maps'];
    final geocoder = js.JsObject(maps['Geocoder']);
    
    final request = js.JsObject.jsify({
      'location': js.JsObject(maps['LatLng'], [lat, lng])
    });

    geocoder.callMethod('geocode', [
      request,
      (results, status) {
        timeoutTimer.cancel();
        if (completer.isCompleted) return;
        if (status.toString() == 'OK' && results != null && results['length'] as int > 0) {
          final first = results[0];
          final location = first['geometry']['location'];
          final resLat = location.callMethod('lat') as double;
          final resLng = location.callMethod('lng') as double;
          final placeId = first['place_id'].toString();
          final formatted = first['formatted_address'].toString();
          
          final components = first['address_components'];
          final compLen = components['length'] as int;
          
          String village = '';
          String taluk = '';
          String district = '';
          String state = '';
          String country = '';
          String postalCode = '';

          for (var i = 0; i < compLen; i++) {
            final comp = components[i];
            final types = comp['types'];
            final typesLen = types['length'] as int;
            final typeList = <String>[];
            for (var j = 0; j < typesLen; j++) {
              typeList.add(types[j].toString());
            }
            
            if (typeList.contains('locality') || typeList.contains('sublocality_level_1')) {
              village = comp['long_name'].toString();
            } else if (typeList.contains('administrative_area_level_3')) {
              taluk = comp['long_name'].toString();
            } else if (typeList.contains('administrative_area_level_2')) {
              district = comp['long_name'].toString();
            } else if (typeList.contains('administrative_area_level_1')) {
              state = comp['long_name'].toString();
            } else if (typeList.contains('country')) {
              country = comp['long_name'].toString();
            } else if (typeList.contains('postal_code')) {
              postalCode = comp['long_name'].toString();
            }
          }

          completer.complete(GoogleMapsPlaceDetails(
            latitude: resLat,
            longitude: resLng,
            placeId: placeId,
            village: village,
            taluk: taluk,
            district: district,
            state: state,
            country: country,
            postalCode: postalCode,
            formattedAddress: formatted,
          ));
        } else {
          completer.complete(null);
        }
      }
    ]);
  } catch (e) {
    timeoutTimer.cancel();
    if (!completer.isCompleted) {
      completer.complete(null);
    }
  }
  return completer.future;
}
