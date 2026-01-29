// Archivo de configuración de Firebase
// IMPORTANTE: Debes reemplazar estos valores con los datos reales de tu proyecto Firebase

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(


      apiKey: 'TU_ANDROID_API_KEY_AQUI',
    appId: 'TU_ANDROID_APP_ID_AQUI',
    messagingSenderId: 'TU_MESSAGING_SENDER_ID_AQUI',
    projectId: 'TU_PROJECT_ID_AQUI',
    storageBucket: 'tu-proyecto.appspot.com',

  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'TU_ANDROID_API_KEY_AQUI',
    appId: 'TU_ANDROID_APP_ID_AQUI',
    messagingSenderId: 'TU_MESSAGING_SENDER_ID_AQUI',
    projectId: 'TU_PROJECT_ID_AQUI',
    storageBucket: 'tu-proyecto.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'TU_IOS_API_KEY_AQUI',
    appId: 'TU_IOS_APP_ID_AQUI',
    messagingSenderId: 'TU_MESSAGING_SENDER_ID_AQUI',
    projectId: 'TU_PROJECT_ID_AQUI',
    storageBucket: 'tu-proyecto.appspot.com',
    androidClientId: 'TU_ANDROID_CLIENT_ID_AQUI',
    iosClientId: 'TU_IOS_CLIENT_ID_AQUI',
    iosBundleId: 'com.example.ourensetermal',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'TU_MACOS_API_KEY_AQUI',
    appId: 'TU_MACOS_APP_ID_AQUI',
    messagingSenderId: 'TU_MESSAGING_SENDER_ID_AQUI',
    projectId: 'TU_PROJECT_ID_AQUI',
    storageBucket: 'tu-proyecto.appspot.com',
    iosBundleId: 'com.example.ourensetermal',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'TU_WINDOWS_API_KEY_AQUI',
    appId: 'TU_WINDOWS_APP_ID_AQUI',
    messagingSenderId: 'TU_MESSAGING_SENDER_ID_AQUI',
    projectId: 'TU_PROJECT_ID_AQUI',
    storageBucket: 'tu-proyecto.appspot.com',
    authDomain: 'tu-proyecto.firebaseapp.com',
  );
}
