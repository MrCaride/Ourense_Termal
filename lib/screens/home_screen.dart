import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/thermal_point_model.dart';
import 'map_screen.dart';
import 'routes_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Datos mockados
  late User _user;
  late List<ThermalPoint> _thermalPoints;
  late List<CheckIn> _checkIns;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Crear usuario mockado
    _user = User(
      id: '1',
      name: 'Usuario Test',
      email: 'test@email.com',
      points: 250,
      level: 2,
      joinedDate: DateTime.now().subtract(const Duration(days: 30)),
      badges: [
        AchievementBadge(
          id: 'first-checkin',
          name: 'Primera Visita',
          description: 'Has visitado tu primer punto termal',
          icon: '🎯',
          earnedDate: DateTime.now().subtract(const Duration(days: 20)),
        ),
      ],
    );

    // Puntos termales mockados
    _thermalPoints = [
      ThermalPoint(
        id: '1',
        name: 'Baños de Ourense',
        description: 'Las famosas burgas termales en el centro de Ourense',
        type: 'fountain',
        temperature: 67,
        address: 'Plaza Mayor, Ourense',
        latitude: 42.3376,
        longitude: -7.8653,
        imageUrl: 'https://images.unsplash.com/photo-1636689523952-8d94e3a82a94?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx0aGVybWFsJTIwc3ByaW5ncyUyMGhvdCUyMHdhdGVyfGVufDF8fHx8MTc2NDA2OTE5OXww&ixlib=rb-4.1.0&q=80&w=1080',
        openingHours: '24/7',
        accessibility: 'high',
        properties: ['Sulfurosa', 'Temperatura alta', 'Minerales'],
        safety: [
          'El agua es muy caliente, cuidado al entrar',
          'No se recomienda para personas con problemas cardíacos',
          'Mantén distancia de otras personas',
        ],
      ),
      ThermalPoint(
        id: '2',
        name: 'Balneario de As Burgas',
        description: 'Complejo de termas con servicios premium',
        type: 'spa',
        temperature: 65,
        address: 'Rúa da Paz, Ourense',
        latitude: 42.3380,
        longitude: -7.8640,
        imageUrl: 'https://images.unsplash.com/photo-1667235195726-a7c440bca9bd?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzcGElMjBsdXh1cnklMjB3ZWxsbmVzc3xlbnwxfHx8fDE3NjQwNDE5MjF8MA&ixlib=rb-4.1.0&q=80&w=1080',
        price: '15€ - 45€',
        openingHours: '09:00 - 20:00',
        accessibility: 'high',
        properties: ['Sulfurosa', 'Relajante', 'Terapéutica'],
        safety: [
          'Supervivencia recomendada',
          'Horarios de entrada respetados',
        ],
      ),
      ThermalPoint(
        id: '3',
        name: 'Pozas de Caldeliñas',
        description: 'Pozas naturales de agua termal en el río Miño',
        type: 'pool',
        temperature: 40,
        address: 'Río Miño, Ourense',
        latitude: 42.2850,
        longitude: -7.8200,
        imageUrl: 'https://images.unsplash.com/photo-1665512987872-4a4c06a8aab2?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxvdXRkb29yJTIwcG9vbCUyMG5hdHVyZXxlbnwxfHx8fDE3NjQwNjkxOTl8MA&ixlib=rb-4.1.0&q=80&w=1080',
        openingHours: 'Amanecer - Atardecer',
        accessibility: 'medium',
        properties: ['Natural', 'Mineral', 'Refrescante'],
        safety: [
          'Cuidado con las corrientes del río',
          'No nadar solo',
          'Revisar el nivel del agua antes de entrar',
        ],
      ),
    ];

    _checkIns = [
      CheckIn(
        id: '1',
        pointId: '1',
        timestamp: DateTime.now().subtract(const Duration(days: 5)),
        points: 50,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      MapScreen(
        thermalPoints: _thermalPoints,
        user: _user,
        checkIns: _checkIns,
      ),
      RoutesScreen(
        user: _user,
      ),
      ProfileScreen(
        user: _user,
        checkIns: _checkIns,
        thermalPoints: _thermalPoints,
      ),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
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
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
