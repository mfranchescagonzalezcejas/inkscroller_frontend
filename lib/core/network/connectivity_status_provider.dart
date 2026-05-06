import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emits whether the device currently has any network transport available.
final connectivityStatusProvider = StreamProvider<bool>((ref) {
  final Connectivity connectivity = Connectivity();
  final StreamController<bool> controller = StreamController<bool>();

  Future<void> emitCurrentStatus() async {
    final List<ConnectivityResult> results =
        await connectivity.checkConnectivity();
    controller.add(_hasConnection(results));
  }

  final StreamSubscription<List<ConnectivityResult>> subscription =
      connectivity.onConnectivityChanged.listen((results) {
        controller.add(_hasConnection(results));
      });

  unawaited(emitCurrentStatus());

  ref.onDispose(() {
    subscription.cancel();
    controller.close();
  });

  return controller.stream;
});

bool _hasConnection(List<ConnectivityResult> results) {
  return results.any((result) => result != ConnectivityResult.none);
}
