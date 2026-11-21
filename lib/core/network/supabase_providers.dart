import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../offline/queue_store.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

/// Connectivity changes (connectivity_plus v6 emits a list of results).
final connectivityStreamProvider = StreamProvider.autoDispose<bool>((ref) {
  final controller = StreamController<bool>();
  late final StreamSubscription<List<ConnectivityResult>> sub;
  sub = Connectivity().onConnectivityChanged.listen((results) {
    controller.add(results.isNotEmpty &&
        results.any((r) => r != ConnectivityResult.none));
  }, onError: (_) => controller.add(true));
  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });
  return controller.stream;
});

/// Lazily initialized encrypted offline queue.
final queueStoreProvider = FutureProvider<EncryptedQueueStore>((ref) async {
  final store = EncryptedQueueStore();
  await store.load();
  return store;
});
