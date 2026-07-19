import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workmanager/workmanager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../database/local_database.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return Future.value(false); // Can't sync without internet
      }
      
      final db = LocalDatabase();
      final queue = await db.getSyncQueue();
      
      if (queue.isEmpty) {
        return Future.value(true);
      }

      for (var item in queue) {
        final payload = jsonDecode(item.payload);
        
        // Add updated/sync stamps
        payload['isSynced'] = true;
        payload['syncVersion'] = 1;
        
        try {
          if (item.targetTable == 'patients') {
            await FirebaseFirestore.instance
                .collection('patients')
                .doc(item.recordId)
                .set(payload, SetOptions(merge: true));
          } else if (item.targetTable == 'vaccinations') {
            await FirebaseFirestore.instance
                .collection('vaccinations')
                .doc(item.recordId)
                .set(payload, SetOptions(merge: true));
          } else if (item.targetTable == 'inventory') {
            await FirebaseFirestore.instance
                .collection('inventory')
                .doc(item.recordId)
                .set(payload, SetOptions(merge: true));
          }
          // Remove from local sync queue on success
          await db.deleteFromSyncQueue(item.id);
        } catch (e) {
          debugPrint('Sync Engine error on ID ${item.recordId}: $e');
        }
      }
      
      return Future.value(true);
    } catch (err) {
      debugPrint('Workmanager Task failed: $err');
      return Future.value(false);
    }
  });
}

class BackgroundSyncEngine {
  static void initialize() {
    if (kIsWeb) return; // Workmanager not supported on web
    
    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true,
    );
  }

  static void registerPeriodicSync() {
    if (kIsWeb) return;

    Workmanager().registerPeriodicTask(
      "asha_care_sync_task",
      "periodicSync",
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}
