// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA5Y9ATrqWzoAijUgGixcGAoBql4VPcsjw',
    appId: '1:644327565328:web:e5274d7e4ddfb4fc7ec295',
    messagingSenderId: '644327565328',
    projectId: 'chatx-f6975',
    authDomain: 'chatx-f6975.firebaseapp.com',
    storageBucket: 'chatx-f6975.firebasestorage.app',
    measurementId: 'G-QZBPQ3K2SP',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBEGdN8EmSV6Yba2xW4W9gLeimyTilE3Gs',
    appId: '1:644327565328:android:cd4ff8d225c6085c7ec295',
    messagingSenderId: '644327565328',
    projectId: 'chatx-f6975',
    storageBucket: 'chatx-f6975.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB-LOiTpIcdo7B_FjA7mMnHsd8H9EqLSYk',
    appId: '1:644327565328:ios:74a0a29793a05ffe7ec295',
    messagingSenderId: '644327565328',
    projectId: 'chatx-f6975',
    storageBucket: 'chatx-f6975.firebasestorage.app',
    iosBundleId: 'com.example.chatx',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB-LOiTpIcdo7B_FjA7mMnHsd8H9EqLSYk',
    appId: '1:644327565328:ios:74a0a29793a05ffe7ec295',
    messagingSenderId: '644327565328',
    projectId: 'chatx-f6975',
    storageBucket: 'chatx-f6975.firebasestorage.app',
    iosBundleId: 'com.example.chatx',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA5Y9ATrqWzoAijUgGixcGAoBql4VPcsjw',
    appId: '1:644327565328:web:1df492ea11d37aaa7ec295',
    messagingSenderId: '644327565328',
    projectId: 'chatx-f6975',
    authDomain: 'chatx-f6975.firebaseapp.com',
    storageBucket: 'chatx-f6975.firebasestorage.app',
    measurementId: 'G-VDCMRLVTZF',
  );
}
