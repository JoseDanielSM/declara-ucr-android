import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Solo se activa al iniciar explícitamente con USE_FIREBASE_EMULATORS=true.
class LocalEnvironment {
  static const enabled = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
  static const host = '127.0.0.1';
  static const projectId = 'demo-declaraucr-local';

  static const firebaseOptions = FirebaseOptions(
    apiKey: 'local-emulator-api-key',
    appId: '1:123456789:web:local',
    messagingSenderId: '123456789',
    projectId: projectId,
    authDomain: 'localhost',
    storageBucket: '$projectId.appspot.com',
  );

  static Future<void> connect() async {
    if (!enabled) return;
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    // Esta versión de FlutterFire restaura el usuario antes de conectar los
    // emuladores al recargar. Evitar esa restauración impide que una sesión
    // ficticia intente validarse contra Firebase de Internet.
    await FirebaseAuth.instance.setPersistence(Persistence.NONE);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8180);
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
    FirebaseFunctions.instanceFor(region: 'us-east1')
        .useFunctionsEmulator(host, 5001);
    await FirebaseStorage.instance.useStorageEmulator(host, 9199);
  }
}
