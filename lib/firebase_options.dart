// Firebase Configuration for SUTODERO App
// This file contains Firebase configuration for Web and Android platforms

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  // Firebase project credentials configured
  // Project: su-todero
  
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDltBp3tPYtsgw9WJo68mRuKIFnFZqMmP8',
    appId: '1:292635586927:web:bad9207d28dc0c9e29789a',
    messagingSenderId: '292635586927',
    projectId: 'su-todero',
    authDomain: 'su-todero.firebaseapp.com',
    storageBucket: 'su-todero.firebasestorage.app',
    measurementId: 'G-HZLJ1WZTRP',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDltBp3tPYtsgw9WJo68mRuKIFnFZqMmP8',
    appId: '1:292635586927:android:PENDING_ANDROID_CONFIG',
    messagingSenderId: '292635586927',
    projectId: 'su-todero',
    storageBucket: 'su-todero.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: '1:YOUR_APP_ID:ios:YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'sutodero-app',
    storageBucket: 'sutodero-app.appspot.com',
    iosBundleId: 'com.sutodero.app',
  );
}
