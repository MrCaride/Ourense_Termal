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
        theme: 'Urbana',
        type: 'walking',
        thermalPointIds: ['burgas_1', 'burga_muiño', 'outariz'],
        difficulty: 'easy',
        duration: '2 horas',
        distance: 3.5,
        points: 40,
      ),
      route_model.Route(
        id: 'route_2',
        name: 'Paseo de las Burgas',
        description: 'Ruta por las famosas Burgas de Ourense y sus alrededores',
        theme: 'Urbana',
        type: 'walking',
        thermalPointIds: ['burgas_1', 'reza', 'laias'],
        difficulty: 'easy',
        duration: '1.5 horas',
        distance: 2.0,
        points: 30,
      ),
      route_model.Route(
        id: 'route_3',
        name: 'Ribera del Miño Termal',
        description: 'Sigue el río Miño visitando las termas de Outariz y Chavasqueira',
        theme: 'Urbana',
        type: 'walking',
        thermalPointIds: ['burga_muiño', 'outariz', 'chavasqueira'],
        difficulty: 'moderate',
        duration: '3 horas',
        distance: 5.5,
        points: 60,
      ),

      // Rutas provinciales
      route_model.Route(
        id: 'route_4',
        name: 'Ruta del Agua Termal Provincial',
        description: 'Gran ruta por los principales puntos termales de la provincia',
        theme: 'Provincial',
        type: 'driving',
        thermalPointIds: ['burgas_1', 'burga_muiño', 'outariz', 'laias', 'arnoia', 'mondariz', 'bande', 'lobios'],
        difficulty: 'hard',
        duration: '2 días',
        distance: 120.0,
        points: 200,
      ),
      route_model.Route(
        id: 'route_5',
        name: 'Termas del Norte',
        description: 'Ruta por las termas de la zona norte de la provincia',
        theme: 'Provincial',
        type: 'driving',
        thermalPointIds: ['bande', 'lobios', 'prexigueiro', 'partovia'],
        difficulty: 'moderate',
        duration: '1 día',
        distance: 45.0,
        points: 120,
      ),
      route_model.Route(
        id: 'route_6',
        name: 'Termas del Sur',
        description: 'Descubre las termas de la zona sur de Ourense',
        theme: 'Provincial',
        type: 'driving',
        thermalPointIds: ['mondariz', 'carballino', 'cortegada', 'caldas_partovia', 'tintores'],
        difficulty: 'moderate',
        duration: '1 día',
        distance: 50.0,
        points: 130,
      ),

      // Rutas temáticas
      route_model.Route(
        id: 'route_7',
        name: 'Ruta de Balnearios de Lujo',
        description: 'Visita los mejores balnearios con servicios premium',
        theme: 'Temática',
        type: 'driving',
        thermalPointIds: ['laias', 'arnoia', 'mondariz', 'carballino'],
        difficulty: 'easy',
        duration: '1 día',
        distance: 35.0,
        points: 110,
      ),
      route_model.Route(
        id: 'route_8',
        name: 'Ruta de Piscinas Públicas',
        description: 'Disfruta de las piscinas termales gratuitas y públicas',
        theme: 'Temática',
        type: 'walking',
        thermalPointIds: ['burga_muiño', 'outariz', 'chavasqueira', 'reza', 'laias', 'arnoia'],
        difficulty: 'easy',
        duration: '1 día',
        distance: 25.0,
        points: 90,
      ),
      route_model.Route(
        id: 'route_9',
        name: 'Ruta Histórica Termal',
        description: 'Visita termas con historia romana y medieval',
        theme: 'Temática',
        type: 'mixed',
        thermalPointIds: ['burgas_1', 'reza', 'laias', 'aquis_querquennis', 'mondariz'],
        difficulty: 'moderate',
        duration: '1 día',
        distance: 40.0,
        points: 120,
      ),

      // Rutas especiales
      route_model.Route(
        id: 'route_10',
        name: 'Ruta Familiar',
        description: 'Termas ideales para visitar en familia con niños',
        theme: 'Especial',
        type: 'walking',
        thermalPointIds: ['burga_muiño', 'outariz', 'chavasqueira', 'reza'],
        difficulty: 'easy',
        duration: '4 horas',
        distance: 8.0,
        points: 70,
      ),
      route_model.Route(
        id: 'route_11',
        name: 'Ruta Romántica',
        description: 'Los lugares termales más románticos de Ourense',
        theme: 'Especial',
        type: 'driving',
        thermalPointIds: ['laias', 'arnoia', 'mondariz', 'cortegada', 'caldas_partovia'],
        difficulty: 'easy',
        duration: '1 día',
        distance: 42.0,
        points: 140,
      ),
      route_model.Route(
        id: 'route_12',
        name: 'Gran Ruta Completa',
        description: 'Visita todos los puntos termales de Ourense',
        theme: 'Especial',
        type: 'mixed',
        thermalPointIds: [
          'burgas_1', 'burga_muiño', 'outariz', 'chavasqueira', 'muiño_vella', 'reza', 'laias', 'arnoia', 'carballino', 'cortegada',
          'lobios', 'bande', 'mondariz', 'prexigueiro', 'partovia', 'aquis_querquennis', 'cacabelos', 'berducedo', 'riocaldo', 'caldas_partovia'
        ],
        difficulty: 'hard',
        duration: '1 semana',
        distance: 250.0,
        points: 300,
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
