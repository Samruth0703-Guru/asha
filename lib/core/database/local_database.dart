import 'package:drift/drift.dart';
import 'connection/connection.dart'
    if (dart.library.io) 'connection/native.dart'
    if (dart.library.html) 'connection/web.dart' as conn;

part 'local_database.g.dart';

class Patients extends Table {
  TextColumn get id => text()();
  TextColumn get abhaId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get photoPath => text().nullable()();
  DateTimeColumn get dob => dateTime()();
  TextColumn get gender => text()();
  TextColumn get phone => text()();
  TextColumn get village => text()();
  BoolColumn get isHighRisk => boolean().withDefault(const Constant(false))();
  BoolColumn get isPregnant => boolean().withDefault(const Constant(false))();
  BoolColumn get vaccinationRequired => boolean().withDefault(const Constant(false))();
  
  // Vitals & Risk fields
  TextColumn get bloodPressure => text().nullable()();
  RealColumn get hemoglobin => real().nullable()();
  RealColumn get bloodSugar => real().nullable()();
  RealColumn get temperature => real().nullable()();
  RealColumn get weight => real().nullable()();
  TextColumn get symptoms => text().nullable()();
  IntColumn get previousPregnancies => integer().withDefault(const Constant(0))();
  
  // AI Prediction Output
  TextColumn get riskLevel => text().withDefault(const Constant('Low'))();
  RealColumn get confidenceScore => real().withDefault(const Constant(0.0))();
  TextColumn get reasons => text().nullable()();
  TextColumn get recommendations => text().nullable()();
  DateTimeColumn get nextFollowUp => dateTime().nullable()();
  
  // Location
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get placeId => text().nullable()();
  TextColumn get district => text().nullable()();
  TextColumn get state => text().nullable()();
  TextColumn get country => text().nullable()();
  TextColumn get postalCode => text().nullable()();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Vaccinations extends Table {
  TextColumn get id => text()();
  TextColumn get patientId => text()();
  TextColumn get vaccineName => text()();
  DateTimeColumn get dueDate => dateTime()();
  DateTimeColumn get administeredDate => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('Pending'))(); // Pending, Completed, Missed
  BoolColumn get smsSent => boolean().withDefault(const Constant(false))();
  TextColumn get doseNumber => text().nullable()();
  TextColumn get batchNumber => text().nullable()();
  TextColumn get healthWorker => text().nullable()();
  TextColumn get remarks => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class AncVisits extends Table {
  TextColumn get id => text()();
  TextColumn get patientId => text()();
  DateTimeColumn get visitDate => dateTime()();
  DateTimeColumn get nextVisitDate => dateTime().nullable()();
  TextColumn get expectedDeliveryDate => text().nullable()();
  TextColumn get healthWorker => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('Pending'))(); 
  BoolColumn get smsSent => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Inventory extends Table {
  TextColumn get id => text()();
  TextColumn get medicineName => text()();
  IntColumn get stockCount => integer()();
  DateTimeColumn get expiryDate => dateTime()();
  IntColumn get minThreshold => integer().withDefault(const Constant(10))();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get targetTable => text()();
  TextColumn get recordId => text()();
  TextColumn get action => text()(); // INSERT, UPDATE, DELETE
  TextColumn get payload => text()(); // JSON string
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class SmsHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get recipient => text()();
  TextColumn get messageType => text()(); // OTP, Confirmation, Reminder, Warning, Referral, Emergency
  TextColumn get messageContent => text()();
  DateTimeColumn get sentAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get status => text().withDefault(const Constant('Pending'))(); // Sent, Failed, Retrying
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
}

@DriftDatabase(tables: [Patients, Vaccinations, Inventory, SyncQueue, SmsHistory, AncVisits])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(conn.openConnection());

  @override
  int get schemaVersion => 1;

  // Helper CRUD methods
  Future<List<Patient>> getAllPatients() => select(patients).get();
  Future<Patient?> getPatientById(String id) => (select(patients)..where((t) => t.id.equals(id))).getSingleOrNull();
  Future<int> insertPatient(Patient p) => into(patients).insert(p, mode: InsertMode.insertOrReplace);
  Future<bool> updatePatient(Patient p) => update(patients).replace(p);
  Future<int> deletePatient(String id) => (delete(patients)..where((t) => t.id.equals(id))).go();

  // Vaccinations CRUD
  Future<List<Vaccination>> getVaccinationsForPatient(String patientId) => 
    (select(vaccinations)..where((t) => t.patientId.equals(patientId))).get();
  Future<List<Vaccination>> getUpcomingVaccinations() => 
    (select(vaccinations)..where((t) => t.status.equals('Pending'))).get();
  Future<int> insertVaccination(Vaccination v) => into(vaccinations).insert(v, mode: InsertMode.insertOrReplace);
  Future<bool> updateVaccination(Vaccination v) => update(vaccinations).replace(v);

  // Inventory CRUD
  Future<List<InventoryData>> getInventory() => select(inventory).get();
  Future<int> insertInventory(InventoryData i) => into(inventory).insert(i, mode: InsertMode.insertOrReplace);
  Future<bool> updateInventory(InventoryData i) => update(inventory).replace(i);

  // Sync Queue CRUD
  Future<List<SyncQueueData>> getSyncQueue() => select(syncQueue).get();
  Future<int> addToSyncQueue(SyncQueueCompanion entry) => into(syncQueue).insert(entry);
  Future<int> deleteFromSyncQueue(int id) => (delete(syncQueue)..where((t) => t.id.equals(id))).go();

  // SMS History CRUD
  Future<List<SmsHistoryData>> getSmsHistory() => (select(smsHistory)..orderBy([(t) => OrderingTerm.desc(t.sentAt)])).get();
  Future<int> insertSmsRecord(SmsHistoryCompanion entry) => into(smsHistory).insert(entry);
  Future<bool> updateSmsRecord(SmsHistoryData entry) => update(smsHistory).replace(entry);
}

class LocalDatabaseFallback {
  static final List<Patient> registeredPatients = [];
}
