import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import '../models/user_route_progress_model.dart';
import '../models/route_model.dart' as route_model;
import '../data/routes_data.dart';
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
      } catch (_) {
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
      } catch (_) {
      }
    }

    return progressMap;
  }

  // Actualizar progreso de una ruta cuando el usuario visita un punto termal
  Future<bool> updateRouteProgress({
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
    final wasCompleted = progress.isCompleted;

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
    return !wasCompleted && isCompleted;
  }

  // Guardar progreso en la base de datos
  Future<void> _saveProgress(UserRouteProgress progress) async {
    if (kIsWeb) {
      try {
        await _firestore
            .collection('user_route_progress')
            .doc(progress.id)
            .set(progress.toFirestore(), SetOptions(merge: true));
      } catch (_) {
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
      } catch (_) {
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
      } catch (_) {
      }
    } else {
      try {
        final db = await _databaseService.database;
        await db.delete(
          'user_route_progress',
          where: 'id = ?',
          whereArgs: [id],
        );
      } catch (_) {
      }
    }
  }

  // Obtener lista de rutas predefinidas (delegando a RoutesData)
  static List<route_model.Route> getAvailableRoutes() {
    return RoutesData.getAvailableRoutes();
  }
}
