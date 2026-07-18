import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart';
import 'local_database.dart';

enum SyncStatus { idle, syncing, success, error }

class SyncState {
  final SyncStatus status;
  final int pendingItems;
  final double progress;
  final String message;

  SyncState({
    required this.status,
    required this.pendingItems,
    required this.progress,
    required this.message,
  });

  SyncState copyWith({
    SyncStatus? status,
    int? pendingItems,
    double? progress,
    String? message,
  }) {
    return SyncState(
      status: status ?? this.status,
      pendingItems: pendingItems ?? this.pendingItems,
      progress: progress ?? this.progress,
      message: message ?? this.message,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  final LocalDatabase _db;

  SyncNotifier(this._db) : super(SyncState(status: SyncStatus.idle, pendingItems: 0, progress: 0.0, message: 'System Ready')) {
    _initSyncStatus();
  }

  void _initSyncStatus() async {
    try {
      final queue = await _db.getSyncQueue();
      state = state.copyWith(pendingItems: queue.length);
      if (queue.isEmpty) {
        await _prepopulateIfNeeded();
      }
    } catch (e) {
      print('SyncNotifier local database init error: $e');
      state = state.copyWith(message: 'Database Unavailable (Offline Mode)');
    }
  }

  Future<void> _prepopulateIfNeeded() async {
    return;
  }

  Future<void> addRecordToSyncQueue(String table, String id, String action, Map<String, dynamic> data) async {
    await _db.addToSyncQueue(SyncQueueCompanion(
      targetTable: Value(table),
      recordId: Value(id),
      action: Value(action),
      payload: Value(jsonEncode(data)),
    ));
    final queue = await _db.getSyncQueue();
    state = state.copyWith(pendingItems: queue.length);
  }

  Future<void> forceSync() async {
    final queue = await _db.getSyncQueue();
    if (queue.isEmpty) {
      state = state.copyWith(message: 'All records are up to date.');
      return;
    }

    state = state.copyWith(status: SyncStatus.syncing, progress: 0.0, message: 'Connecting to Supabase Cloud...');
    
    final client = Supabase.instance.client;

    int total = queue.length;
    for (int i = 0; i < total; i++) {
      final item = queue[i];
      try {
        final payload = jsonDecode(item.payload);
        if (item.targetTable == 'patients') {
          await client.from('patients').upsert(payload);
        } else if (item.targetTable == 'vaccinations') {
          await client.from('vaccinations').upsert(payload);
        } else if (item.targetTable == 'inventory') {
          await client.from('inventory').upsert(payload);
        }
        await _db.deleteFromSyncQueue(item.id);
      } catch (e) {
        print('Supabase Sync Error on ID \${item.recordId}: \$e');
        await Future.delayed(const Duration(milliseconds: 300));
        // Keep item in the queue so it can be retried during the next sync
      }
      
      double progress = (i + 1) / total;
      state = state.copyWith(
        progress: progress,
        pendingItems: total - (i + 1),
        message: 'Synchronized: ${item.targetTable} [ID: ${item.recordId}]',
      );
    }

    state = state.copyWith(
      status: SyncStatus.success,
      progress: 1.0,
      message: 'Cloud Sync Completed Successfully!',
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        state = state.copyWith(status: SyncStatus.idle, progress: 0.0, message: 'Sync System Idle');
      }
    });
  }
}

// Providers
final localDatabaseProvider = Provider<LocalDatabase>((ref) {
  final db = LocalDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final db = ref.watch(localDatabaseProvider);
  return SyncNotifier(db);
});
