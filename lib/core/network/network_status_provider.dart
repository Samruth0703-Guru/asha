import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkState { online, offline, slow }

final networkStatusProvider = StateNotifierProvider<NetworkStatusNotifier, NetworkState>((ref) {
  return NetworkStatusNotifier();
});

class NetworkStatusNotifier extends StateNotifier<NetworkState> {
  NetworkStatusNotifier() : super(NetworkState.online) {
    _init();
  }

  void _init() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.none)) {
        state = NetworkState.offline;
      } else if (results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi)) {
        // Here we could add a ping to check for "slow" connection, but we default to online
        state = NetworkState.online;
      }
    });
  }
}
