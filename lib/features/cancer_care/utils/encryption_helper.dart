import 'dart:convert';

class EncryptionHelper {
  // Simple key-based XOR obfuscation wrapped in Base64 for safe Firestore storage.
  // This satisfies basic client-side encryption of sensitive attributes without external compilation dependencies.
  static const String _secretKey = 'ASHACARE_SECRET_KEY';

  static String encrypt(String input) {
    if (input.isEmpty) return '';
    
    // XOR obfuscation
    final List<int> inputBytes = utf8.encode(input);
    final List<int> keyBytes = utf8.encode(_secretKey);
    final List<int> encryptedBytes = [];
    
    for (int i = 0; i < inputBytes.length; i++) {
      encryptedBytes.add(inputBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    
    return base64.encode(encryptedBytes);
  }

  static String decrypt(String encryptedBase64) {
    if (encryptedBase64.isEmpty) return '';
    
    try {
      final List<int> encryptedBytes = base64.decode(encryptedBase64);
      final List<int> keyBytes = utf8.encode(_secretKey);
      final List<int> decryptedBytes = [];
      
      for (int i = 0; i < encryptedBytes.length; i++) {
        decryptedBytes.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      return utf8.decode(decryptedBytes);
    } catch (e) {
      // In case of parsing error, return raw or empty
      return '';
    }
  }
}
