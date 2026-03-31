import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../models/thermal_point_model.dart';
import 'database_service.dart';
import 'route_service.dart';

class UserDataService {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RouteService _routeService = RouteService();

  // Obtener check-ins del usuario
  Future<List<CheckIn>> getUserCheckIns(String userId) async {
    if (kIsWeb) {
      final snapshot = await _firestore
          .collection('check_ins')
          .where('userId', isEqualTo: userId)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return CheckIn(
          id: doc.id,
          userId: data['userId'] as String,
          pointId: data['pointId'] as String,
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          points: data['points'] as int? ?? 50,
        );
      }).toList();
    }

    final db = await _databaseService.database;
    final result = await db.query(
      'check_ins',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );

    return result.map((map) => CheckIn(
      id: map['id'] as String,
      userId: map['userId'] as String,
      pointId: map['pointId'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      points: map['points'] as int? ?? 50,
    )).toList();
  }

  // Crear un check-in
  Future<CheckIn> createCheckIn({
    required String userId,
    required String pointId,
    int points = 50,
  }) async {
    final now = DateTime.now();
    final checkIn = CheckIn(
      id: now.millisecondsSinceEpoch.toString(),
      userId: userId,
      pointId: pointId,
      timestamp: now,
      points: points,
    );

    if (kIsWeb) {
      await _firestore.collection('check_ins').doc(checkIn.id).set({
        'userId': checkIn.userId,
        'pointId': checkIn.pointId,
        'timestamp': checkIn.timestamp,
        'points': checkIn.points,
      });
    } else {
      final db = await _databaseService.database;
      await db.insert('check_ins', {
        'id': checkIn.id,
        'userId': checkIn.userId,
        'pointId': checkIn.pointId,
        'timestamp': checkIn.timestamp.millisecondsSinceEpoch,
        'points': checkIn.points,
        'syncedWithFirebase': 0,
      });
    }

    // Actualizar progreso de rutas que incluyen este punto termal
    try {
      final routes = RouteService.getAvailableRoutes();
      for (final route in routes) {
        if (route.thermalPointIds.contains(pointId)) {
          final justCompleted = await _routeService.updateRouteProgress(
            userId: userId,
            route: route,
            visitedPointId: pointId,
          );

          if (justCompleted) {
            await updateUserPoints(userId, route.points);
          }
        }
      }
    } catch (e) {
      debugPrint('Error al actualizar progreso de rutas: $e');
      // No lanzar error, solo registrar
    }

    return checkIn;
  }

  // Obtener insignias del usuario
  Future<List<AchievementBadge>> getUserBadges(String userId) async {
    if (kIsWeb) {
      final snapshot = await _firestore
          .collection('badges')
          .where('userId', isEqualTo: userId)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AchievementBadge(
          id: doc.id,
          name: data['name'] as String,
          description: data['description'] as String,
          icon: data['icon'] as String,
          earnedDate: (data['earnedDate'] as Timestamp).toDate(),
        );
      }).toList();
    }

    final db = await _databaseService.database;
    final result = await db.query(
      'badges',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'earnedDate DESC',
    );

    return result.map((map) => AchievementBadge(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      icon: map['icon'] as String,
      earnedDate: DateTime.fromMillisecondsSinceEpoch(map['earnedDate'] as int),
    )).toList();
  }

  // Añadir insignia al usuario
  Future<void> addBadge({
    required String userId,
    required String badgeId,
    required String name,
    required String description,
    required String icon,
  }) async {
    final now = DateTime.now();

    if (kIsWeb) {
      await _firestore.collection('badges').doc(badgeId).set({
        'userId': userId,
        'name': name,
        'description': description,
        'icon': icon,
        'earnedDate': now,
      });
    } else {
      final db = await _databaseService.database;
      await db.insert('badges', {
        'id': badgeId,
        'userId': userId,
        'name': name,
        'description': description,
        'icon': icon,
        'earnedDate': now.millisecondsSinceEpoch,
        'syncedWithFirebase': 0,
      });
    }
  }

  // Actualizar puntos y nivel del usuario
  Future<void> updateUserPoints(String userId, int pointsToAdd) async {
    if (kIsWeb) {
      final userDoc = _firestore.collection('users').doc(userId);
      final snapshot = await userDoc.get();
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final currentPoints = (data['points'] as int? ?? 0) + pointsToAdd;
      final currentLevel = data['level'] as int? ?? 1;
      final newLevel = _calculateLevel(currentPoints);

      await userDoc.update({
        'points': currentPoints,
        'level': newLevel,
        'updatedAt': DateTime.now(),
      });

      // Verificar si subió de nivel
      if (newLevel > currentLevel) {
        await addBadge(
          userId: userId,
          badgeId: 'level_$newLevel',
          name: 'Nivel $newLevel Alcanzado',
          description: 'Has alcanzado el nivel $newLevel',
          icon: '⭐',
        );
      }
    } else {
      final db = await _databaseService.database;
      final result = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (result.isEmpty) return;

      final userData = result.first;
      final currentPoints = (userData['points'] as int? ?? 0) + pointsToAdd;
      final currentLevel = userData['level'] as int? ?? 1;
      final newLevel = _calculateLevel(currentPoints);

      await db.update(
        'users',
        {
          'points': currentPoints,
          'level': newLevel,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
          'syncedWithFirebase': 0,
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

      // Verificar si subió de nivel
      if (newLevel > currentLevel) {
        await addBadge(
          userId: userId,
          badgeId: 'level_$newLevel',
          name: 'Nivel $newLevel Alcanzado',
          description: 'Has alcanzado el nivel $newLevel',
          icon: '⭐',
        );
      }
    }
  }

  // Establecer puntos del usuario (no suma, establece el valor exacto)
  Future<void> setUserPoints(String userId, int newPoints) async {
    if (kIsWeb) {
      final userDoc = _firestore.collection('users').doc(userId);
      final snapshot = await userDoc.get();
      if (!snapshot.exists) return;

      final data = snapshot.data()!;
      final currentLevel = data['level'] as int? ?? 1;
      final newLevel = _calculateLevel(newPoints);

      await userDoc.update({
        'points': newPoints,
        'level': newLevel,
        'updatedAt': DateTime.now(),
      });

      // Verificar si subió de nivel
      if (newLevel > currentLevel) {
        await addBadge(
          userId: userId,
          badgeId: 'level_$newLevel',
          name: 'Nivel $newLevel Alcanzado',
          description: 'Has alcanzado el nivel $newLevel',
          icon: '⭐',
        );
      }
    } else {
      final db = await _databaseService.database;
      final result = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (result.isEmpty) return;

      final userData = result.first;
      final currentLevel = userData['level'] as int? ?? 1;
      final newLevel = _calculateLevel(newPoints);

      await db.update(
        'users',
        {
          'points': newPoints,
          'level': newLevel,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
          'syncedWithFirebase': 0,
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

      // Verificar si subió de nivel
      if (newLevel > currentLevel) {
        await addBadge(
          userId: userId,
          badgeId: 'level_$newLevel',
          name: 'Nivel $newLevel Alcanzado',
          description: 'Has alcanzado el nivel $newLevel',
          icon: '⭐',
        );
      }
    }
  }

  // Calcular nivel basado en puntos
  int _calculateLevel(int points) {
    return (points / 300).floor() + 1;
  }

  // Obtener datos completos del usuario
  Future<User> getUserWithStats(String userId) async {
    if (kIsWeb) {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) throw Exception('Usuario no encontrado');

      final data = userDoc.data()!;
      final badges = await getUserBadges(userId);

      return User(
        id: userId,
        name: data['name'] as String? ?? '',
        email: data['email'] as String? ?? '',
        passwordHash: data['passwordHash'] as String? ?? '',
        points: data['points'] as int? ?? 0,
        level: data['level'] as int? ?? 1,
        joinedDate: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        badges: badges,
      );
    }

    final db = await _databaseService.database;
    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (result.isEmpty) throw Exception('Usuario no encontrado');

    final userData = result.first;
    final badges = await getUserBadges(userId);

    return User(
      id: userId,
      name: userData['name'] as String? ?? '',
      email: userData['email'] as String? ?? '',
      passwordHash: userData['passwordHash'] as String? ?? '',
      points: userData['points'] as int? ?? 0,
      level: userData['level'] as int? ?? 1,
      joinedDate: DateTime.fromMillisecondsSinceEpoch(
        userData['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      badges: badges,
    );
  }

  // Verificar si el usuario ya hizo check-in en un punto
  Future<bool> hasCheckedIn(String userId, String pointId) async {
    if (kIsWeb) {
      final snapshot = await _firestore
          .collection('check_ins')
          .where('userId', isEqualTo: userId)
          .where('pointId', isEqualTo: pointId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    }

    final db = await _databaseService.database;
    final result = await db.query(
      'check_ins',
      where: 'userId = ? AND pointId = ?',
      whereArgs: [userId, pointId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  // Obtener todos los usuarios (solo admin)
  Future<List<User>> getAllUsers() async {
    if (kIsWeb) {
      final snapshot = await _firestore.collection('users').get();
      final users = <User>[];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final badges = await getUserBadges(doc.id);
        users.add(User(
          id: doc.id,
          name: data['name'] as String? ?? '',
          email: data['email'] as String? ?? '',
          passwordHash: data['passwordHash'] as String? ?? '',
          points: data['points'] as int? ?? 0,
          level: data['level'] as int? ?? 1,
          role: data['role'] != null 
            ? UserRole.fromString(data['role'] as String) 
            : UserRole.user,
          thermalPointId: data['thermalPointId'] as String?,
          joinedDate: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
          badges: badges,
        ));
      }
      
      return users;
    }

    final db = await _databaseService.database;
    final result = await db.query('users');
    final users = <User>[];

    for (var row in result) {
      final badges = await getUserBadges(row['id'] as String);
      users.add(User(
        id: row['id'] as String,
        name: row['name'] as String? ?? '',
        email: row['email'] as String? ?? '',
        passwordHash: row['passwordHash'] as String? ?? '',
        points: row['points'] as int? ?? 0,
        level: row['level'] as int? ?? 1,
        role: row['role'] != null 
          ? UserRole.fromString(row['role'] as String) 
          : UserRole.user,
        thermalPointId: row['thermalPointId'] as String?,
        joinedDate: DateTime.fromMillisecondsSinceEpoch(
          row['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
        ),
        badges: badges,
      ));
    }

    return users;
  }

  // Eliminar un usuario (solo admin)
  Future<void> deleteUser(String userId) async {
    if (kIsWeb) {
      await _firestore.collection('users').doc(userId).delete();
      // También eliminar check-ins del usuario
      final checkIns = await _firestore
          .collection('check_ins')
          .where('userId', isEqualTo: userId)
          .get();
      for (var doc in checkIns.docs) {
        await doc.reference.delete();
      }
    } else {
      final db = await _databaseService.database;
      await db.delete('users', where: 'id = ?', whereArgs: [userId]);
      await db.delete('check_ins', where: 'userId = ?', whereArgs: [userId]);
      await db.delete('achievements', where: 'userId = ?', whereArgs: [userId]);
    }
  }

  // Asignar un punto termal a un gerente
  Future<void> assignThermalPointToManager(String managerId, String? thermalPointId) async {
    if (kIsWeb) {
      await _firestore.collection('users').doc(managerId).update({
        'thermalPointId': thermalPointId,
      });
    } else {
      final db = await _databaseService.database;
      await db.update(
        'users',
        {
          'thermalPointId': thermalPointId,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
          'syncedWithFirebase': 0,
        },
        where: 'id = ?',
        whereArgs: [managerId],
      );
    }
  }
}
