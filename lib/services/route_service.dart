import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import '../models/user_route_progress_model.dart';
import '../models/route_model.dart' as route_model;
import 'database_service.dart';

class RouteService {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener progreso de todas las rutas para un usuario
  Future<Map<String, UserRouteProgress>> getUserRouteProgress(String userId) async {
    final Map<String, UserRouteProgress> progressMap = {};

    if (kIsWeb) {
      try {
        final snapshot = await _firestore
            .collection('user_route_progress')
            .where('userId', isEqualTo: userId)
            .get();

        for (var doc in snapshot.docs) {
          final progress = UserRouteProgress.fromFirestore(doc.id, doc.data());
          progressMap[progress.routeId] = progress;
        }
      } catch (e) {
        debugPrint('Error al cargar progreso de rutas desde Firestore: $e');
      }
    } else {
      try {
        final db = await _databaseService.database;
        final results = await db.query(
          'user_route_progress',
          where: 'userId = ?',
          whereArgs: [userId],
        );

        for (var row in results) {
          final progress = UserRouteProgress.fromMap(Map<String, dynamic>.from(row));
          progressMap[progress.routeId] = progress;
        }
      } catch (e) {
        debugPrint('Error al cargar progreso de rutas desde SQLite: $e');
      }
    }

    return progressMap;
  }

  // Actualizar progreso de una ruta cuando el usuario visita un punto termal
  Future<void> updateRouteProgress({
    required String userId,
    required route_model.Route route,
    required String visitedPointId,
  }) async {
    // Cargar progreso actual o crear uno nuevo
    final progressMap = await getUserRouteProgress(userId);
    UserRouteProgress progress = progressMap[route.id] ?? UserRouteProgress(
      id: '${userId}_${route.id}',
      userId: userId,
      routeId: route.id,
      progress: 0.0,
      isCompleted: false,
      completedPointIds: [],
      lastUpdated: DateTime.now(),
    );

    // Agregar punto visitado si no está ya en la lista
    final updatedPoints = List<String>.from(progress.completedPointIds);
    if (!updatedPoints.contains(visitedPointId) && 
        route.thermalPointIds.contains(visitedPointId)) {
      updatedPoints.add(visitedPointId);
    }

    // Calcular nuevo progreso
    final newProgress = UserRouteProgress.calculateProgress(
      updatedPoints.length,
      route.thermalPointIds.length,
    );

    // Verificar si se completó la ruta
    final isCompleted = updatedPoints.length >= route.thermalPointIds.length;

    // Actualizar modelo
    progress = progress.copyWith(
      completedPointIds: updatedPoints,
      progress: newProgress,
      isCompleted: isCompleted,
      lastUpdated: DateTime.now(),
      completedAt: isCompleted && !progress.isCompleted ? DateTime.now() : progress.completedAt,
    );

    // Guardar en la base de datos
    await _saveProgress(progress);
  }

  // Guardar progreso en la base de datos
  Future<void> _saveProgress(UserRouteProgress progress) async {
    if (kIsWeb) {
      try {
        await _firestore
            .collection('user_route_progress')
            .doc(progress.id)
            .set(progress.toFirestore(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error al guardar progreso en Firestore: $e');
      }
    } else {
      try {
        final db = await _databaseService.database;
        await db.insert(
          'user_route_progress',
          {
            ...progress.toMap(),
            'completedPointIds': progress.completedPointIds.join(','),
            'syncedWithFirebase': 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (e) {
        debugPrint('Error al guardar progreso en SQLite: $e');
      }
    }
  }

  // Obtener progreso de una ruta específica
  Future<UserRouteProgress?> getRouteProgress(String userId, String routeId) async {
    final progressMap = await getUserRouteProgress(userId);
    return progressMap[routeId];
  }

  // Reiniciar progreso de una ruta
  Future<void> resetRouteProgress(String userId, String routeId) async {
    final id = '${userId}_$routeId';

    if (kIsWeb) {
      try {
        await _firestore.collection('user_route_progress').doc(id).delete();
      } catch (e) {
        debugPrint('Error al reiniciar progreso en Firestore: $e');
      }
    } else {
      try {
        final db = await _databaseService.database;
        await db.delete(
          'user_route_progress',
          where: 'id = ?',
          whereArgs: [id],
        );
      } catch (e) {
        debugPrint('Error al reiniciar progreso en SQLite: $e');
      }
    }
  }

  // Obtener lista de rutas predefinidas
  List<route_model.Route> getAvailableRoutes() {
    return [
      // RUTAS URBANAS - CENTRO DE OURENSE
      route_model.Route(
        id: 'route_burgas',
        name: 'Ruta de As Burgas',
        description: 'Descubre el centro histórico y los manantiales termales más emblemáticos de Ourense',
        theme: 'Historia y Cultura',
        type: 'walking',
        difficulty: 'easy',
        distance: 1.5,
        duration: '1h',
        thermalPointIds: ['burgas_1', 'burga_muiño'],
        points: 200,
      ),

      route_model.Route(
        id: 'route_rio_mino',
        name: 'Ruta del Río Miño',
        description: 'Recorre las termas públicas junto al río Miño, desde Outariz hasta A Reza',
        theme: 'Naturaleza',
        type: 'walking',
        difficulty: 'easy',
        distance: 4.0,
        duration: '2h',
        thermalPointIds: ['outariz', 'chavasqueira', 'muiño_vella', 'reza'],
        points: 400,
      ),

      route_model.Route(
        id: 'route_centro_completo',
        name: 'Gran Ruta Termal Urbana',
        description: 'Circuito completo por todas las termas del centro de Ourense',
        theme: 'Turismo Termal',
        type: 'walking',
        difficulty: 'moderate',
        distance: 5.5,
        duration: '3h',
        thermalPointIds: ['burgas_1', 'burga_muiño', 'outariz', 'chavasqueira', 'muiño_vella', 'reza'],
        points: 600,
      ),

      // RUTAS POR LA PROVINCIA
      route_model.Route(
        id: 'route_balnearios_norte',
        name: 'Ruta de Balnearios del Norte',
        description: 'Visita los balnearios históricos de O Carballiño y Cortegada',
        theme: 'Wellness Premium',
        type: 'driving',
        difficulty: 'moderate',
        distance: 45.0,
        duration: '1 día',
        thermalPointIds: ['carballino', 'cortegada', 'partovia', 'caldas_partovia'],
        points: 800,
      ),

      route_model.Route(
        id: 'route_ribeira_sacra',
        name: 'Termas de la Ribeira Sacra',
        description: 'Descubre las aguas termales en el corazón de la Ribeira Sacra',
        theme: 'Patrimonio',
        type: 'driving',
        difficulty: 'moderate',
        distance: 60.0,
        duration: '1 día',
        thermalPointIds: ['prexigueiro', 'laias'],
        points: 500,
      ),

      route_model.Route(
        id: 'route_sur_ourense',
        name: 'Ruta Termal del Sur',
        description: 'Explora las termas del sur de Ourense: Arnoia, Bande y el Parque Natural',
        theme: 'Naturaleza',
        type: 'driving',
        difficulty: 'hard',
        distance: 85.0,
        duration: '1-2 días',
        thermalPointIds: ['arnoia', 'bande', 'aquis_querquennis', 'lobios'],
        points: 1000,
      ),

      route_model.Route(
        id: 'route_alta_montana',
        name: 'Termas de Alta Montaña',
        description: 'Aventura termal en las montañas: Lobios y Riocaldo en el Xurés',
        theme: 'Aventura',
        type: 'mixed',
        difficulty: 'hard',
        distance: 70.0,
        duration: '1 día',
        thermalPointIds: ['lobios', 'riocaldo', 'berducedo'],
        points: 900,
      ),

      route_model.Route(
        id: 'route_aguas_curativas',
        name: 'Ruta de Aguas Medicinales',
        description: 'Circuito por los balnearios con propiedades medicinales reconocidas',
        theme: 'Salud y Bienestar',
        type: 'driving',
        difficulty: 'moderate',
        distance: 55.0,
        duration: '1 día',
        thermalPointIds: ['laias', 'arnoia', 'carballino', 'partovia'],
        points: 700,
      ),

      route_model.Route(
        id: 'route_lujo',
        name: 'Ruta Premium Spa',
        description: 'Disfruta de los mejores spas y balnearios de lujo de la provincia',
        theme: 'Luxury Wellness',
        type: 'driving',
        difficulty: 'easy',
        distance: 90.0,
        duration: '2 días',
        thermalPointIds: ['lobios', 'mondariz', 'laias', 'outariz'],
        points: 1200,
      ),

      route_model.Route(
        id: 'route_romana',
        name: 'Ruta Termal Romana',
        description: 'Sigue las huellas de la cultura termal romana en Ourense',
        theme: 'Historia Romana',
        type: 'mixed',
        difficulty: 'moderate',
        distance: 65.0,
        duration: '1 día',
        thermalPointIds: ['burgas_1', 'aquis_querquennis', 'bande'],
        points: 600,
      ),

      route_model.Route(
        id: 'route_gratis',
        name: 'Ruta Termal Gratuita',
        description: 'Recorre las mejores termas de acceso libre y gratuito',
        theme: 'Económica',
        type: 'mixed',
        difficulty: 'moderate',
        distance: 50.0,
        duration: '1 día',
        thermalPointIds: ['burgas_1', 'burga_muiño', 'chavasqueira', 'muiño_vella', 'reza', 'bande', 'prexigueiro'],
        points: 800,
      ),

      route_model.Route(
        id: 'route_master',
        name: 'Gran Tour Termal de Ourense',
        description: 'Completa el circuito maestro visitando los principales puntos termales de la provincia',
        theme: 'Gran Desafío',
        type: 'mixed',
        difficulty: 'hard',
        distance: 200.0,
        duration: '3-5 días',
        thermalPointIds: [
          'burgas_1', 'burga_muiño', 'outariz', 'chavasqueira', 'muiño_vella', 'reza',
          'laias', 'arnoia', 'carballino', 'cortegada', 'lobios', 'mondariz', 'prexigueiro',
          'bande', 'aquis_querquennis', 'riocaldo'
        ],
        points: 2500,
      ),
    ];
  }
}
