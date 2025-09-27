import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB140RkQcA2eKLs58sFD-rCvZJt4LAAZI8',
    appId: '1:930910441824:android:f90159167623f22eccce05',
    messagingSenderId: '930910441824',
    projectId: 'pulse-52aa3',
    storageBucket: 'pulse-52aa3.firebasestorage.app',
  );
}