import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_database.dart';
import 'core_repository.dart';

final patientRepositoryProvider = Provider<PatientRepository>((ref) {
  final db = ref.watch(localDatabaseProvider);
  final core = ref.watch(coreRepositoryProvider);
  return PatientRepository(db, core);
});

class PatientRepository {
  final LocalDatabase _db;
  final CoreRepository _core;

  PatientRepository(this._db, this._core);

  Future<List<Patient>> getAllPatients() {
    return _db.getAllPatients();
  }

  Future<Patient?> getPatientById(String id) {
    return _db.getPatientById(id);
  }

  Future<void> savePatient(Patient patient) async {
    // 1. Save locally
    await _db.insertPatient(patient);
    
    // 2. Queue for background sync
    await _core.writeAndSync(
      'patients', 
      patient.toJson(),
      recordId: patient.id,
      action: 'UPSERT',
    );
  }
}
