import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final biometricAuthProvider = Provider<BiometricAuthService>((ref) {
  return BiometricAuthService(FirebaseFirestore.instance);
});

enum BiometricSessionStatus {
  pending,
  authenticated,
  expired,
  failed,
}

class BiometricSession {
  final String sessionId;
  final BiometricSessionStatus status;
  final String? token;
  final DateTime expiresAt;
  final String? deviceName;
  final String? workerName;

  BiometricSession({
    required this.sessionId,
    required this.status,
    this.token,
    required this.expiresAt,
    this.deviceName,
    this.workerName,
  });

  factory BiometricSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) throw Exception("Document is empty");
    
    BiometricSessionStatus getStatus(String s) {
      switch (s) {
        case 'authenticated': return BiometricSessionStatus.authenticated;
        case 'expired': return BiometricSessionStatus.expired;
        case 'failed': return BiometricSessionStatus.failed;
        default: return BiometricSessionStatus.pending;
      }
    }

    return BiometricSession(
      sessionId: doc.id,
      status: getStatus(data['status'] as String? ?? 'pending'),
      token: data['token'] as String?,
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      deviceName: data['deviceName'] as String?,
      workerName: data['workerName'] as String?,
    );
  }
}

class BiometricAuthService {
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();
  
  BiometricAuthService(this._firestore);

  /// 1. Web: Generates a new session and returns QR payload data.
  Future<Map<String, dynamic>> generateSession() async {
    final sessionId = _uuid.v4();
    final encryptedToken = _uuid.v4();
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(seconds: 60));
    
    await _firestore.collection('active_login_sessions').doc(sessionId).set({
      'status': 'pending',
      'expiresAt': Timestamp.fromDate(expiresAt),
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    return {
      'sessionId': sessionId,
      'encryptedToken': encryptedToken,
      'timestamp': now.toIso8601String(),
      'expiryTime': expiresAt.toIso8601String(),
    };
  }

  /// 2. Web: Listens to the session document for status changes.
  Stream<BiometricSession> watchSession(String sessionId) {
    return _firestore
        .collection('active_login_sessions')
        .doc(sessionId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
             // Treat as expired/failed if deleted
             return BiometricSession(
               sessionId: sessionId,
               status: BiometricSessionStatus.expired,
               expiresAt: DateTime.now(),
             );
          }
          return BiometricSession.fromFirestore(doc);
        });
  }

  /// 3. Mobile Companion: Marks the session as authenticated.
  Future<void> authenticateSession({
    required String sessionId,
    required String encryptedToken,
    required String deviceName,
    required String workerName,
  }) async {
    await _firestore.collection('active_login_sessions').doc(sessionId).update({
      'status': 'authenticated',
      'token': encryptedToken,
      'deviceName': deviceName,
      'workerName': workerName,
      'authenticatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 4. Cancel/Invalidate session
  Future<void> invalidateSession(String sessionId) async {
    await _firestore.collection('active_login_sessions').doc(sessionId).update({
      'status': 'expired',
    });
  }
}
