import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sqflite/sqflite.dart' show databaseFactory;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Importar el plugin web de shared_preferences para Web
import 'package:shared_preferences_web/shared_preferences_web.dart';

import 'firebase_options.dart';
import 'services/database_service.dart';
import 'services/sync_service.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Registrar el plugin de SharedPreferences para web
  if (kIsWeb) {
    SharedPreferencesPlugin.registerWith(null);
  }

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // En web no inicializa SQLite ni sincroniza. Trabaja directamente con Firestore.
  
  runApp(const OurenseTermalApp());
}

class OurenseTermalApp extends StatelessWidget {
  const OurenseTermalApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ourense Termal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF06B6D4), // Cyan
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      ),
      home: const AuthChecker(),
      routes: {
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}

// Widget que verifica si hay una sesión activa
class AuthChecker extends StatefulWidget {
  const AuthChecker({Key? key}) : super(key: key);

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final user = await _authService.getCurrentUser();
    if (!mounted) return;
    
    setState(() {
      _isLoading = false;
    });

    if (user != null) {
      // Si hay sesión, ir al HomeScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(user: user)),
      );
    } else {
      // Si no hay sesión, ir al LoginScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pantalla de carga mientras se verifica la sesión
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.cyan[500]!,
              Colors.blue[500]!,
              Colors.blue[600]!,
            ],
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

