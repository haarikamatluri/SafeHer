import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../firebase_options.dart';

abstract class AuthService {
  String? get currentUserId;
  bool get isAuthenticated;
  bool get isAnonymous;
  Stream<String?> get authStateChanges;
  Future<void> initialize();
  Future<String> signInAnonymously();
  Future<void> signOut();
}

class SafeHerAuthService implements AuthService {
  static final SafeHerAuthService _instance = SafeHerAuthService._internal();
  factory SafeHerAuthService() => _instance;
  SafeHerAuthService._internal();

  final _authStreamController = StreamController<String?>.broadcast();
  FirebaseAuth? _firebaseAuth;
  String? _cachedUserId;
  bool _isUsingFallbackLocalAuth = false;

  @override
  String? get currentUserId => _firebaseAuth?.currentUser?.uid ?? _cachedUserId;

  @override
  bool get isAuthenticated => currentUserId != null;

  @override
  bool get isAnonymous => _firebaseAuth?.currentUser?.isAnonymous ?? true;

  @override
  Stream<String?> get authStateChanges => _authStreamController.stream;

  bool get isUsingFallbackLocalAuth => _isUsingFallbackLocalAuth;

  @override
  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _firebaseAuth = FirebaseAuth.instance;

      _firebaseAuth!.authStateChanges().listen((User? user) {
        if (user != null) {
          _cachedUserId = user.uid;
          _authStreamController.add(user.uid);
        } else if (!_isUsingFallbackLocalAuth) {
          _cachedUserId = null;
          _authStreamController.add(null);
        }
      });

      // Auto sign-in anonymously if not signed in
      if (_firebaseAuth!.currentUser == null) {
        await signInAnonymously();
      } else {
        _cachedUserId = _firebaseAuth!.currentUser!.uid;
        _authStreamController.add(_cachedUserId);
      }
    } catch (e) {
      debugPrint('[SafeHerAuth] Firebase Auth init fallback to local: $e');
      _isUsingFallbackLocalAuth = true;
      await _initializeLocalFallback();
    }
  }

  Future<void> _initializeLocalFallback() async {
    final prefs = await SharedPreferences.getInstance();
    var localUid = prefs.getString('local_user_uid');
    if (localUid == null) {
      localUid = 'local_${const Uuid().v4().substring(0, 8)}';
      await prefs.setString('local_user_uid', localUid);
    }
    _cachedUserId = localUid;
    _authStreamController.add(_cachedUserId);
  }

  @override
  Future<String> signInAnonymously() async {
    try {
      if (_firebaseAuth != null && !_isUsingFallbackLocalAuth) {
        final cred = await _firebaseAuth!.signInAnonymously();
        _cachedUserId = cred.user?.uid;
        _authStreamController.add(_cachedUserId);
        return _cachedUserId ?? '';
      }
    } catch (e) {
      debugPrint('[SafeHerAuth] Firebase anonymous sign-in error: $e');
      _isUsingFallbackLocalAuth = true;
    }

    await _initializeLocalFallback();
    return _cachedUserId ?? '';
  }

  @override
  Future<void> signOut() async {
    try {
      if (_firebaseAuth != null && !_isUsingFallbackLocalAuth) {
        await _firebaseAuth!.signOut();
      }
    } catch (e) {
      debugPrint('[SafeHerAuth] Sign out error: $e');
    }
    _cachedUserId = null;
    _authStreamController.add(null);
  }
}
