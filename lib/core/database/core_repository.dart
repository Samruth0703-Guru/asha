import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import 'local_database.dart';
import 'sync_service.dart';

final coreRepositoryProvider = Provider<CoreRepository>((ref) {
  final db = ref.watch(localDatabaseProvider);
  final syncNotifier = ref.watch(syncProvider.notifier);
  return CoreRepository(db, syncNotifier);
});

class CoreRepository {
  final LocalDatabase _db;
  final SyncNotifier _syncNotifier;
  final Uuid _uuid = const Uuid();

  CoreRepository(this._db, this._syncNotifier);

  /// Write to local database and queue for sync
  Future<void> writeAndSync(String targetTable, Map<String, dynamic> payload, {String? action, String? recordId}) async {
    final id = recordId ?? _uuid.v4();
    final operation = action ?? 'UPSERT';

    // Queue for sync
    await _syncNotifier.addRecordToSyncQueue(targetTable, id, operation, payload);
    
    // Automatically attempt a background sync if online
    // _syncNotifier.forceSync() can be called here or handled by the Network provider
  }
}
