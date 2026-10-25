import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for SafeHer.
///
/// Connected directly to Firebase Project: safeher-e5003
/// Android Package Name: com.SafeHer.app
class DefaultFirebaseOptions {
  static const bool isDemoMode = false;

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBrjHwNCJ2Lbe5SfuY98yWtMVW7rQbIxB8',
    appId: '1:190321479460:web:0bf3da09adde1691652db1',
    messagingSenderId: '190321479460',
    projectId: 'safeher-e5003',
    authDomain: 'safeher-e5003.firebaseapp.com',
    storageBucket: 'safeher-e5003.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBrjHwNCJ2Lbe5SfuY98yWtMVW7rQbIxB8',
    appId: '1:190321479460:android:0bf3da09adde1691652db1',
    messagingSenderId: '190321479460',
    projectId: 'safeher-e5003',
    storageBucket: 'safeher-e5003.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBrjHwNCJ2Lbe5SfuY98yWtMVW7rQbIxB8',
    appId: '1:190321479460:ios:0bf3da09adde1691652db1',
    messagingSenderId: '190321479460',
    projectId: 'safeher-e5003',
    storageBucket: 'safeher-e5003.firebasestorage.app',
    iosBundleId: 'com.SafeHer.app',
  );
}
