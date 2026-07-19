import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'network_status_provider.dart';
import '../database/sync_service.dart';

class GlobalOfflineIndicator extends ConsumerWidget {
  const GlobalOfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkState = ref.watch(networkStatusProvider);
    final syncState = ref.watch(syncProvider);

    if (networkState == NetworkState.offline) {
      return Container(
        width: double.infinity,
        color: Colors.red.shade600,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text(
              'You are currently offline. Changes will sync automatically when reconnected.',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    if (syncState.status == SyncStatus.syncing) {
      return Container(
        width: double.infinity,
        color: Colors.blue.shade600,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              'Syncing... \${(syncState.progress * 100).toInt()}% (\${syncState.pendingItems} items remaining)',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
