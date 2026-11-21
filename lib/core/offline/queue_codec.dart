import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// A single queued offline mutation. `id` doubles as the server-side
/// idempotency key (sync_operations.operation_uuid).
class QueueEntry {
  QueueEntry({
    required this.id,
    required this.kind,
    required this.payload,
    required this.createdAt,
    this.attempts = 0,
    this.lastError,
  });

  final String id;
  final String kind;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  int attempts;
  String? lastError;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'attempts': attempts,
        'lastError': lastError,
      };

  static QueueEntry fromJson(Map<String, dynamic> j) => QueueEntry(
        id: j['id'] as String,
        kind: j['kind'] as String,
        payload: Map<String, dynamic>.from(j['payload'] as Map),
        createdAt: DateTime.parse(j['createdAt'] as String),
        attempts: (j['attempts'] as int?) ?? 0,
        lastError: j['lastError'] as String?,
      );
}

/// Pure AES-256-GCM codec — separated from storage so it is fully unit-testable.
class QueueCodec {
  static const int nonceLength = 12;
  static const int tagBits = 128;

  static String encryptToBase64(String plaintext, Uint8List key) {
    final nonce = _randomBytes(nonceLength);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key), tagBits, nonce, Uint8List(0)));
    final out = cipher.process(Uint8List.fromList(utf8.encode(plaintext)));
    final packed = Uint8List(nonce.length + out.length);
    packed.setAll(0, nonce);
    packed.setAll(nonce.length, out);
    return base64Encode(packed);
  }

  static String decryptFromBase64(String blob, Uint8List key) {
    final packed = base64Decode(blob);
    if (packed.length <= nonceLength) throw const FormatException('Corrupt queue blob');
    final nonce = Uint8List.sublistView(packed, 0, nonceLength);
    final cipherBytes = Uint8List.sublistView(packed, nonceLength);
    final cipher = GCMBlockCipher(AESEngine())
      ..init(false, AEADParameters(KeyParameter(key), tagBits, nonce, Uint8List(0)));
    final plain = cipher.process(cipherBytes);
    return utf8.decode(plain);
  }

  static Uint8List randomKey() => _randomBytes(32);

  static Uint8List _randomBytes(int n) {
    final rnd = Random.secure();
    return Uint8List.fromList(List.generate(n, (_) => rnd.nextInt(256)));
  }
}
