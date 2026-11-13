import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    if (defaultTargetPlatform == TargetPlatform.android) return android;
    throw UnsupportedError('Plataforma no configurada. Usá Android o web.');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBpEbdzRXsrx5ozmnMBaTqieD-yR_S1KaU',
    appId: '1:807844528626:web:16b8dd49aa2bf8105a2b6b',
    messagingSenderId: '807844528626',
    projectId: 'declarahorario-ucr-cff7a',
    authDomain: 'declarahorario-ucr-cff7a.firebaseapp.com',
    storageBucket: 'declarahorario-ucr-cff7a.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC6O15JqEI8ejYhBUCaelrjL8-cKgltW-A',
    appId: '1:807844528626:android:91e2b604b8269a565a2b6b',
    messagingSenderId: '807844528626',
    projectId: 'declarahorario-ucr-cff7a',
    storageBucket: 'declarahorario-ucr-cff7a.firebasestorage.app',
  );
}
