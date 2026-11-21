import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'queue_codec.dart';

export 'queue_codec.dart';

/// Encrypted offline mutation queue.
///
/// The whole queue is serialized to JSON, encrypted with AES-256-GCM using a
/// device-generated key held in secure storage (Keychain / Keystore /
/// encrypted web storage), and persisted as a single tamper-evident blob.
class EncryptedQueueStore {
  EncryptedQueueStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  static const _keyName = 'ksms_queue_key_v1';
  static const _blobName = 'ksms_queue_blob_v1';

  final FlutterSecureStorage _storage;
  List<QueueEntry> _entries = [];

  Future<Uint8List?> _loadKey() async {
    final stored = await _storage.read(key: _keyName);
    if (stored != null) return base64Decode(stored);
    return null;
  }

  Future<Uint8List> _ensureKey() async {
    final existing = await _loadKey();
    if (existing != null && existing.length == 32) return existing;
    final key = QueueCodec.randomKey();
    await _storage.write(key: _keyName, value: base64Encode(key));
    return key;
  }

  Future<void> load() async {
    final key = await _loadKey();
    final blob = await _storage.read(key: _blobName);
    if (key == null || blob == null) {
      _entries = [];
      return;
    }
    try {
      final raw = QueueCodec.decryptFromBase64(blob, key);
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _entries = list.map(QueueEntry.fromJson).toList();
    } on FormatException {
      _entries = [];
    }
  }

  Future<void> _persist() async {
    final key = await _ensureKey();
    final blob = QueueCodec.encryptToBase64(
        jsonEncode(_entries.map((e) => e.toJson()).toList()), key);
    await _storage.write(key: _blobName, value: blob);
  }

  List<QueueEntry> get entries => List.unmodifiable(_entries);

  int get length => _entries.length;

  Future<void> enqueue(QueueEntry entry) async {
    if (_entries.any((e) => e.id == entry.id)) return; // idempotent locally too
    _entries.add(entry);
    await _persist();
  }

  Future<void> remove(String id) async {
    _entries.removeWhere((e) => e.id == id);
    await _persist();
  }

  Future<void> markAttempt(String id, String? error) async {
    for (final e in _entries) {
      if (e.id == id) {
        e.attempts += 1;
        e.lastError = error;
      }
    }
    await _persist();
  }

  Future<void> clear() async {
    _entries = [];
    await _persist();
  }
}
