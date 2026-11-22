import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:ksms/core/offline/queue_codec.dart';
import 'package:ksms/core/offline/sync_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ksms/core/network/supabase_providers.dart';
import 'package:ksms/core/offline/queue_store.dart';

void main() {
  group('QueueCodec', () {
    test('encryption/decryption roundtrip', () {
      final key = QueueCodec.randomKey();
      final text = '{"test": "data", "id": "123"}';
      final encrypted = QueueCodec.encryptToBase64(text, key);
      final decrypted = QueueCodec.decryptFromBase64(encrypted, key);
      expect(decrypted, text);
    });

    test('decrypting corrupt blob throws FormatException', () {
      final key = QueueCodec.randomKey();
      expect(() => QueueCodec.decryptFromBase64('corrupt_base64', key), throwsA(isA<FormatException>()));
    });
  });

  group('SyncEngine', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(overrides: [
        // Mock providers as needed
      ]);
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is idle', () {
      final engine = container.read(syncEngineProvider.notifier);
      expect(engine.state.phase, SyncPhase.idle);
      expect(engine.state.pendingCount, 0);
    });
    
    // Additional tests for SyncEngine (idempotency, conflict transitions) would follow here.
    // Due to the complex dependencies (Supabase client, secure storage), 
    // these would require extensive mocking or integration with a test-env Supabase.
  });
}
