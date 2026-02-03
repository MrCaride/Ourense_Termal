import '../models/route_model.dart' as route_model;

class RoutesData {
  // Obtener todas las rutas disponibles
  static List<route_model.Route> getAvailableRoutes() {
    return [
      // Rutas urbanas de Ourense ciudad
      route_model.Route(
        id: 'route_1',
        name: 'Ruta Termal Urbana',
        description: 'Descubre las termas históricas del casco urbano de Ourense',
        thermalPointIds: ['1', '2', '3'],
        difficulty: 'Fácil',
        estimatedDuration: '2 horas',
        distance: 3.5,
      ),
      route_model.Route(
        id: 'route_2',
        name: 'Paseo de las Burgas',
        description: 'Ruta por las famosas Burgas de Ourense y sus alrededores',
        thermalPointIds: ['1', '5', '8'],
        difficulty: 'Fácil',
        estimatedDuration: '1.5 horas',
        distance: 2.0,
      ),
      route_model.Route(
        id: 'route_3',
        name: 'Ribera del Miño Termal',
        description: 'Sigue el río Miño visitando las termas de Outariz y Chavasqueira',
        thermalPointIds: ['2', '3', '4'],
        difficulty: 'Media',
        estimatedDuration: '3 horas',
        distance: 5.5,
      ),

      // Rutas provinciales
      route_model.Route(
        id: 'route_4',
        name: 'Ruta del Agua Termal Provincial',
        description: 'Gran ruta por los principales puntos termales de la provincia',
        thermalPointIds: ['1', '2', '3', '6', '7', '9', '10', '11'],
        difficulty: 'Difícil',
        estimatedDuration: '2 días',
        distance: 120.0,
      ),
      route_model.Route(
        id: 'route_5',
        name: 'Termas del Norte',
        description: 'Ruta por las termas de la zona norte de la provincia',
        thermalPointIds: ['12', '13', '14', '15'],
        difficulty: 'Media',
        estimatedDuration: '1 día',
        distance: 45.0,
      ),
      route_model.Route(
        id: 'route_6',
        name: 'Termas del Sur',
        description: 'Descubre las termas de la zona sur de Ourense',
        thermalPointIds: ['16', '17', '18', '19', '20'],
        difficulty: 'Media',
        estimatedDuration: '1 día',
        distance: 50.0,
      ),

      // Rutas temáticas
      route_model.Route(
        id: 'route_7',
        name: 'Ruta de Balnearios de Lujo',
        description: 'Visita los mejores balnearios con servicios premium',
        thermalPointIds: ['6', '7', '10', '11'],
        difficulty: 'Fácil',
        estimatedDuration: '1 día',
        distance: 35.0,
      ),
      route_model.Route(
        id: 'route_8',
        name: 'Ruta de Piscinas Públicas',
        description: 'Disfruta de las piscinas termales gratuitas y públicas',
        thermalPointIds: ['2', '3', '4', '5', '8', '9'],
        difficulty: 'Fácil',
        estimatedDuration: '1 día',
        distance: 25.0,
      ),
      route_model.Route(
        id: 'route_9',
        name: 'Ruta Histórica Termal',
        description: 'Visita termas con historia romana y medieval',
        thermalPointIds: ['1', '5', '8', '12', '15'],
        difficulty: 'Media',
        estimatedDuration: '1 día',
        distance: 40.0,
      ),

      // Rutas especiales
      route_model.Route(
        id: 'route_10',
        name: 'Ruta Familiar',
        description: 'Termas ideales para visitar en familia con niños',
        thermalPointIds: ['2', '3', '4', '9'],
        difficulty: 'Fácil',
        estimatedDuration: '4 horas',
        distance: 8.0,
      ),
      route_model.Route(
        id: 'route_11',
        name: 'Ruta Romántica',
        description: 'Los lugares termales más románticos de Ourense',
        thermalPointIds: ['6', '7', '10', '13', '17'],
        difficulty: 'Fácil',
        estimatedDuration: '1 día',
        distance: 42.0,
      ),
      route_model.Route(
        id: 'route_12',
        name: 'Gran Ruta Completa',
        description: 'Visita todos los puntos termales de Ourense',
        thermalPointIds: [
          '1', '2', '3', '4', '5', '6', '7', '8', '9', '10',
          '11', '12', '13', '14', '15', '16', '17', '18', '19', '20'
        ],
        difficulty: 'Muy Difícil',
        estimatedDuration: '1 semana',
        distance: 250.0,
      ),
    ];
  }

  // Obtener ruta por ID
  static route_model.Route? getRouteById(String routeId) {
    try {
      return getAvailableRoutes().firstWhere((route) => route.id == routeId);
    } catch (e) {
      return null;
    }
  }

  // Filtrar rutas por dificultad
  static List<route_model.Route> filterByDifficulty(String difficulty) {
    return getAvailableRoutes()
        .where((route) => route.difficulty == difficulty)
        .toList();
  }

  // Obtener rutas que contengan un punto termal específico
  static List<route_model.Route> getRoutesContainingPoint(String thermalPointId) {
    return getAvailableRoutes()
        .where((route) => route.thermalPointIds.contains(thermalPointId))
        .toList();
  }
}
