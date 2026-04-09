import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../models/thermal_point_model.dart';
import '../services/user_data_service.dart';
import '../data/thermal_points_data.dart';
import 'map_screen.dart';
import 'routes_screen.dart';
import 'rewards_screen.dart';
import 'profile_screen.dart';
import '../widgets/role_based_navigator.dart';
import '../utils/app_theme.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final UserDataService _userDataService = UserDataService();

  // Datos mockados
  late User _user;
  late List<ThermalPoint> _thermalPoints;
  List<CheckIn> _checkIns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    _user = widget.user;

    // Esta pantalla es solo para usuarios normales.
    if (_user.role != UserRole.user) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Puntos termales desde datos locales ampliados
    _thermalPoints = ThermalPointsData.getThermalPoints();

    // Cargar check-ins del usuario
    try {
      _checkIns = await _userDataService.getUserCheckIns(_user.id);
      
      // Cargar datos actualizados del usuario (puntos, nivel, insignias)
      _user = await _userDataService.getUserWithStats(_user.id);
      
      setState(() {
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    try {
      _checkIns = await _userDataService.getUserCheckIns(_user.id);
      _user = await _userDataService.getUserWithStats(_user.id);
      setState(() {});
    } catch (_) {
    }
  }

  void _showTutorial() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tutorial de la aplicación'),
        content: const SingleChildScrollView(
          child: Text(
            '1. Regístrate o inicia sesión para acceder al contenido.\n\n'
            '2. En Mapa puedes ver puntos termales cercanos y hacer check-in.\n\n'
            '3. En Rutas puedes seguir recorridos y completar objetivos.\n\n'
            '4. Al completar visitas y rutas acumulas puntos y subes de nivel.\n\n'
            '5. En Recompensas puedes canjear tus puntos por beneficios.\n\n'
            '6. En Perfil puedes consultar progreso, nivel e insignias.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user.role != UserRole.user) {
      return RoleBasedNavigator(user: _user);
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final userCheckIns = _checkIns.where((c) => c.userId == _user.id).toList();
    final screens = [
      MapScreen(
        thermalPoints: _thermalPoints,
        user: _user,
        checkIns: userCheckIns,
        onCheckIn: _refreshData,
      ),
      RoutesScreen(
        user: _user,
        onCheckIn: _refreshData,
      ),
      RewardsScreen(
        user: _user,
      ),
      ProfileScreen(
        user: _user,
        checkIns: userCheckIns,
        thermalPoints: _thermalPoints,
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: screens[_selectedIndex],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showTutorial,
        backgroundColor: AppTheme.brandTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.auto_awesome_outlined),
        label: const Text('Ayuda'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.11),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: NavigationBar(
                selectedIndex: _selectedIndex,
                height: 72,
                indicatorColor: AppTheme.brandTeal.withValues(alpha: 0.14),
                backgroundColor: Colors.transparent,
                onDestinationSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Mapa'),
                  NavigationDestination(icon: Icon(Icons.route_outlined), selectedIcon: Icon(Icons.route), label: 'Rutas'),
                  NavigationDestination(icon: Icon(Icons.redeem_outlined), selectedIcon: Icon(Icons.redeem), label: 'Recompensas'),
                  NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
