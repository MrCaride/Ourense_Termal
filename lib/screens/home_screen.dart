import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/thermal_point_model.dart';
import '../services/user_data_service.dart';
import '../data/thermal_points_data.dart';
import 'map_screen.dart';
import 'routes_screen.dart';
import 'rewards_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({Key? key, required this.user}) : super(key: key);

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
    } catch (e) {
      debugPrint('Error cargando datos del usuario: $e');
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
    } catch (e) {
      debugPrint('Error actualizando datos: $e');
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
      body: screens[_selectedIndex],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showTutorial,
        icon: const Icon(Icons.help_outline),
        label: const Text('Ayuda'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[700],
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route),
            label: 'Rutas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Recompensas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
