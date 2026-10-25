import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../utils/constants.dart';
import 'auth_service.dart';

/// Top-level background message handler required by Firebase Messaging
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(
    '[FCM Background] Handling background message: ${message.messageId}',
  );
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  final _messageStreamController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onMessageReceived =>
      _messageStreamController.stream;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      if (Firebase.apps.isEmpty) return;

      // Register background handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Request user permission for notifications
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      debugPrint(
        '[FCM] Notification authorization status: ${settings.authorizationStatus}',
      );

      // Obtain FCM device registration token
      try {
        // ignore: deprecated_member_use
        _fcmToken = await FirebaseMessaging.instance.getToken();
        debugPrint('[FCM] Device Token: $_fcmToken');
      } catch (tokenErr) {
        debugPrint('[FCM] Error obtaining FCM token: $tokenErr');
      }

      // Sync token to Firestore whenever user authenticates
      SafeHerAuthService().authStateChanges.listen((userId) {
        if (userId != null && _fcmToken != null) {
          _saveTokenToFirestore(userId, _fcmToken!);
        }
      });

      final currentUid = SafeHerAuthService().currentUserId;
      if (currentUid != null && _fcmToken != null) {
        _saveTokenToFirestore(currentUid, _fcmToken!);
      }

      // Listen for token refresh events
      // ignore: deprecated_member_use
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        final uid = SafeHerAuthService().currentUserId;
        if (uid != null) {
          _saveTokenToFirestore(uid, newToken);
        }
      });

      // Foreground message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          '[FCM] Foreground notification received: ${message.notification?.title}',
        );
        _messageStreamController.add(message);
      });

      // Notification click / open listener
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[FCM] User tapped notification: ${message.data}');
      });
    } catch (e) {
      debugPrint('[FCM] PushNotificationService initialization warning: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String userId, String token) async {
    if (SafeHerAuthService().isUsingFallbackLocalAuth) return;

    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('fcmTokens')
          .doc(token)
          .set({
            'token': token,
            'platform': defaultTargetPlatform.name,
            'createdAt': FieldValue.serverTimestamp(),
            'lastActive': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      debugPrint('[FCM] Token registered to Firestore for user: $userId');
    } catch (e) {
      debugPrint('[FCM] Failed to store FCM token in Firestore: $e');
    }
  }
}
