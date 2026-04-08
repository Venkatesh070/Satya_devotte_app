import 'package:connectivity_plus/connectivity_plus.dart';

enum SyncState { idle, syncing, failed, stale }

class SyncService {
  Future<bool> hasConnection() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }
}
