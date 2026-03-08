import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

/// End-to-end encryption service for direct messages.
/// Uses X25519 key exchange + HKDF-SHA256 + AES-256-GCM.
class E2EEncryptionService {
  final FlutterSecureStorage _secureStorage;
  final ApiClient _apiClient;

  // In-memory caches
  final Map<String, String> _recipientKeyCache = {};  // userId -> base64 public key
  final Map<String, SecretKey> _sharedSecretCache = {};  // sortedPairKey -> shared secret

  E2EEncryptionService(this._secureStorage, this._apiClient);

  /// Generate X25519 key pair, store private in secure storage, upload public to server.
  /// If key already exists in storage, re-uploads the public key to ensure server has it.
  Future<void> getOrCreateKeyPair(String userId) async {
    final privateKeyStorageKey = 'e2ee_private_key_$userId';
    final publicKeyStorageKey = 'e2ee_public_key_$userId';

    String? existingPrivateKey = await _secureStorage.read(key: privateKeyStorageKey);
    String? existingPublicKey = await _secureStorage.read(key: publicKeyStorageKey);

    if (existingPrivateKey != null && existingPublicKey != null) {
      // Key exists, ensure it's uploaded to server
      try {
        await _uploadPublicKey(existingPublicKey);
        debugPrint('✅ [E2EE] Existing key pair confirmed for user $userId');
      } catch (e) {
        debugPrint('⚠️ [E2EE] Failed to re-upload existing key: $e');
      }
      return;
    }

    // Generate new X25519 key pair
    final algorithm = X25519();
    final keyPair = await algorithm.newKeyPair();

    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();

    final privateKeyBase64 = base64Encode(privateKeyBytes);
    final publicKeyBase64 = base64Encode(publicKey.bytes);

    // Store private key securely
    await _secureStorage.write(key: privateKeyStorageKey, value: privateKeyBase64);
    await _secureStorage.write(key: publicKeyStorageKey, value: publicKeyBase64);

    // Upload public key to server
    await _uploadPublicKey(publicKeyBase64);

    debugPrint('✅ [E2EE] New key pair generated and uploaded for user $userId');
  }

  Future<void> _uploadPublicKey(String publicKeyBase64) async {
    await _apiClient.post(
      '/social/keys/upload',
      data: {
        'public_key': publicKeyBase64,
        'algorithm': 'x25519',
      },
    );
  }

  /// Get recipient's public key from server, with in-memory cache.
  Future<String?> getRecipientPublicKey(String userId) async {
    if (_recipientKeyCache.containsKey(userId)) {
      return _recipientKeyCache[userId];
    }

    try {
      final response = await _apiClient.get('/social/keys/$userId');
      if (response.statusCode == 200) {
        final publicKey = response.data['public_key'] as String;
        _recipientKeyCache[userId] = publicKey;
        return publicKey;
      }
    } catch (e) {
      debugPrint('⚠️ [E2EE] Failed to get public key for $userId: $e');
    }
    return null;
  }

  /// Derive shared secret using X25519 DH + HKDF-SHA256.
  /// Cached per sorted user pair.
  Future<SecretKey?> deriveSharedSecret(String myUserId, String recipientId) async {
    // Sort user IDs for consistent cache key
    final ids = [myUserId, recipientId]..sort();
    final cacheKey = '${ids[0]}_${ids[1]}';

    if (_sharedSecretCache.containsKey(cacheKey)) {
      // Return cached secret wrapped as SecretKey
      return _sharedSecretCache[cacheKey] as SecretKey?;
    }

    try {
      // Load my private key
      final privateKeyBase64 = await _secureStorage.read(
        key: 'e2ee_private_key_$myUserId',
      );
      if (privateKeyBase64 == null) {
        debugPrint('❌ [E2EE] No private key found for $myUserId');
        return null;
      }

      // Get recipient's public key
      final recipientPublicKeyBase64 = await getRecipientPublicKey(recipientId);
      if (recipientPublicKeyBase64 == null) {
        debugPrint('⚠️ [E2EE] No public key found for recipient $recipientId');
        return null;
      }

      // Reconstruct keys
      final privateKeyBytes = base64Decode(privateKeyBase64);
      final recipientPublicKeyBytes = base64Decode(recipientPublicKeyBase64);

      final algorithm = X25519();
      final myKeyPair = await algorithm.newKeyPairFromSeed(privateKeyBytes);
      final recipientPublicKey = SimplePublicKey(
        recipientPublicKeyBytes,
        type: KeyPairType.x25519,
      );

      // Perform DH key exchange
      final sharedSecretResult = await algorithm.sharedSecretKey(
        keyPair: myKeyPair,
        remotePublicKey: recipientPublicKey,
      );

      // Derive encryption key using HKDF-SHA256
      final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
      final derivedKey = await hkdf.deriveKey(
        secretKey: sharedSecretResult,
        info: utf8.encode('fitwiz-e2ee-dm-v1'),
        nonce: Uint8List(0),
      );

      // Cache and return
      _sharedSecretCache[cacheKey] = derivedKey as SecretKey;
      return derivedKey;
    } catch (e) {
      debugPrint('❌ [E2EE] Failed to derive shared secret: $e');
      return null;
    }
  }

  /// Encrypt a message using AES-256-GCM.
  /// Returns (ciphertext, nonce) as base64 strings.
  Future<({String ciphertext, String nonce})?> encryptMessage(
    String plaintext,
    SecretKey sharedSecret,
  ) async {
    try {
      final algorithm = AesGcm.with256bits();
      final secretBox = await algorithm.encrypt(
        utf8.encode(plaintext),
        secretKey: sharedSecret,
      );

      return (
        ciphertext: base64Encode(secretBox.cipherText + secretBox.mac.bytes),
        nonce: base64Encode(secretBox.nonce),
      );
    } catch (e) {
      debugPrint('❌ [E2EE] Encryption failed: $e');
      return null;
    }
  }

  /// Decrypt a message using AES-256-GCM.
  /// Returns plaintext or '[Unable to decrypt]' on failure.
  Future<String> decryptMessage(
    String ciphertextBase64,
    String nonceBase64,
    SecretKey sharedSecret,
  ) async {
    try {
      final combined = base64Decode(ciphertextBase64);
      final nonce = base64Decode(nonceBase64);

      // Last 16 bytes are the MAC
      final cipherText = combined.sublist(0, combined.length - 16);
      final mac = Mac(combined.sublist(combined.length - 16));

      final algorithm = AesGcm.with256bits();
      final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);

      final decrypted = await algorithm.decrypt(secretBox, secretKey: sharedSecret);
      return utf8.decode(decrypted);
    } catch (e) {
      debugPrint('⚠️ [E2EE] Decryption failed: $e');
      return '[Unable to decrypt]';
    }
  }

  /// Check if a recipient has a published encryption key.
  Future<bool> hasEncryptionKey(String userId) async {
    final key = await getRecipientPublicKey(userId);
    return key != null;
  }

  /// Clear in-memory caches (on logout).
  void clearCache() {
    _recipientKeyCache.clear();
    _sharedSecretCache.clear();
  }
}
