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
  // Project: sutoderoapp-ee318 (SuToderoApp)
  
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAFw7Vf-gOs9-Ca1kkg97P1iQC_PJxE0Hk',
    appId: '1:268982041852:web:0b3aed72a818ea5a1e2b79',
    messagingSenderId: '268982041852',
    projectId: 'sutoderoapp-ee318',
    authDomain: 'sutoderoapp-ee318.firebaseapp.com',
    storageBucket: 'sutoderoapp-ee318.firebasestorage.app',
    measurementId: 'G-CZHRFYC635',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCP0lZ6IGMIBGi-e3Pu1cTDVZqqxSjpTp0',
    appId: '1:268982041852:android:fc23e41e400db83a1e2b79',
    messagingSenderId: '268982041852',
    projectId: 'sutoderoapp-ee318',
    storageBucket: 'sutoderoapp-ee318.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCgFu2YdI0BbEPkX0gk3N_HhFZkWAb3JJY',
    appId: '1:268982041852:ios:b87d0645965446461e2b79',
    messagingSenderId: '268982041852',
    projectId: 'sutoderoapp-ee318',
    storageBucket: 'sutoderoapp-ee318.firebasestorage.app',
    iosBundleId: 'sutodero.app',
  );
}
