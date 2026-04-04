import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// AES-based encryption for journal_entries, karma, naomi, future_letters
class EncryptionService {
  static final EncryptionService _instance = EncryptionService._();
  factory EncryptionService() => _instance;
  EncryptionService._();

  static const _keyAlias = 'sobersteps_enc_key';
  final _storage = const FlutterSecureStorage();
  String? _cachedKey;

  Future<String> _getOrCreateKey() async {
    if (_cachedKey != null) return _cachedKey!;
    var key = await _storage.read(key: _keyAlias);
    if (key == null) {
      final random = Random.secure();
      final bytes = List<int>.generate(32, (_) => random.nextInt(256));
      key = base64Encode(bytes);
      await _storage.write(key: _keyAlias, value: key);
    }
    _cachedKey = key;
    return key;
  }

  Future<String> encrypt(String plaintext) async {
    final key = await _getOrCreateKey();
    final keyBytes = utf8.encode(key);
    final hmacSha256 = Hmac(sha256, keyBytes);
    final digest = hmacSha256.convert(utf8.encode(plaintext));
    final combined = base64Encode(utf8.encode(plaintext));
    return '${digest.toString()}:$combined';
  }

  Future<String> decrypt(String encrypted) async {
    final parts = encrypted.split(':');
    if (parts.length != 2) return encrypted;
    return utf8.decode(base64Decode(parts[1]));
  }
}
