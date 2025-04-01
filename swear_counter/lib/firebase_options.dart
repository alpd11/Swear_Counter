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
    apiKey: 'AIzaSyBKRLRD-WW7c1Mgr4wVJvQELsDSCGtfayQ',
    appId: '1:605415794165:web:0213d55c93381d11376cbc',
    messagingSenderId: '605415794165',
    projectId: 'swear-counter-fb94b',
    authDomain: 'swear-counter-fb94b.firebaseapp.com',
    storageBucket: 'swear-counter-fb94b.firebasestorage.app',
    measurementId: 'G-BMTRCE7BLW',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCDzXnLp3ks4Vl1FVZ3i2pN0a1JH_T2Y7c',
    appId: '1:605415794165:android:1e58b8bdcf0b8e2a376cbc',
    messagingSenderId: '605415794165',
    projectId: 'swear-counter-fb94b',
    storageBucket: 'swear-counter-fb94b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBtWvhemTGL7VSfXrdnl1CplM35QSxVEL4',
    appId: '1:605415794165:ios:72a5f6efc7e629f2376cbc',
    messagingSenderId: '605415794165',
    projectId: 'swear-counter-fb94b',
    storageBucket: 'swear-counter-fb94b.firebasestorage.app',
    iosBundleId: 'com.example.swearCounter',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBtWvhemTGL7VSfXrdnl1CplM35QSxVEL4',
    appId: '1:605415794165:ios:72a5f6efc7e629f2376cbc',
    messagingSenderId: '605415794165',
    projectId: 'swear-counter-fb94b',
    storageBucket: 'swear-counter-fb94b.firebasestorage.app',
    iosBundleId: 'com.example.swearCounter',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBKRLRD-WW7c1Mgr4wVJvQELsDSCGtfayQ',
    appId: '1:605415794165:web:d5cc30664803ed0e376cbc',
    messagingSenderId: '605415794165',
    projectId: 'swear-counter-fb94b',
    authDomain: 'swear-counter-fb94b.firebaseapp.com',
    storageBucket: 'swear-counter-fb94b.firebasestorage.app',
    measurementId: 'G-GQ8H1TZTXQ',
  );
}
