import 'dart:html' as html;
import 'dart:convert';
import 'local_database.dart';

void savePatientsToWeb(List<Patient> patients) {
  try {
    final List<Map<String, dynamic>> jsonList = patients.map((p) => p.toJson()).toList();
    html.window.localStorage['asha_care_patients_fallback'] = jsonEncode(jsonList);
    print('Successfully serialized patients directly to LocalStorage fallback.');
  } catch (e) {
    print('Failed to write patients to LocalStorage fallback: \$e');
  }
}

void loadPatientsFromWeb() {
  final stored = html.window.localStorage['asha_care_patients_fallback'];
  if (stored != null) {
    try {
      final List<dynamic> decoded = jsonDecode(stored);
      LocalDatabaseFallback.registeredPatients.clear();
      for (var item in decoded) {
        LocalDatabaseFallback.registeredPatients.add(Patient.fromJson(item as Map<String, dynamic>));
      }
      print('Successfully restored \${decoded.length} patients from LocalStorage fallback.');
    } catch (e) {
      print('Failed to read patients from LocalStorage fallback: \$e');
    }
  }
}
