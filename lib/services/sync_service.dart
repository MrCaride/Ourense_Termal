import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'database_service.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _databaseService = DatabaseService();

  // Sincronizar usuarios desde SQLite a Firebase
  Future<void> syncUsersToFirebase() async {
    try {
      debugPrint('Iniciando sincronización de usuarios a Firebase...');
      final db = await _databaseService.database;
      
      // Obtener usuarios no sincronizados
      final unsyncedUsers = await db.query(
        'users',
        where: 'syncedWithFirebase = ?',
        whereArgs: [0],
      );

      for (var user in unsyncedUsers) {
        await _firestore.collection('users').doc(user['id'] as String).set({
          'name': user['name'],
          'email': user['email'],
          'passwordHash': user['passwordHash'],
          'points': user['points'],
          'level': user['level'],
          'profileImageUrl': user['profileImageUrl'],
          'createdAt': DateTime.fromMillisecondsSinceEpoch(user['createdAt'] as int),
          'updatedAt': DateTime.fromMillisecondsSinceEpoch(user['updatedAt'] as int),
        }, SetOptions(merge: true));

        // Marcar como sincronizado
        await db.update(
          'users',
          {'syncedWithFirebase': 1},
          where: 'id = ?',
          whereArgs: [user['id']],
        );
      }
      debugPrint('${unsyncedUsers.length} usuarios sincronizados a Firebase');
    } catch (e) {
      debugPrint('Error al sincronizar usuarios: $e');
    }
  }

  // Sincronizar puntos termales desde SQLite a Firebase
  Future<void> syncThermalPointsToFirebase() async {
    try {
      debugPrint('Iniciando sincronización de puntos termales a Firebase...');
      final db = await _databaseService.database;
      
      final unsyncedPoints = await db.query(
        'thermal_points',
        where: 'syncedWithFirebase = ?',
        whereArgs: [0],
      );

      for (var point in unsyncedPoints) {
        await _firestore.collection('thermal_points').doc(point['id'] as String).set({
          'name': point['name'],
          'description': point['description'],
          'latitude': point['latitude'],
          'longitude': point['longitude'],
          'temperature': point['temperature'],
          'imageUrl': point['imageUrl'],
          'facilities': point['facilities'],
          'createdAt': DateTime.fromMillisecondsSinceEpoch(point['createdAt'] as int),
          'updatedAt': DateTime.fromMillisecondsSinceEpoch(point['updatedAt'] as int),
        }, SetOptions(merge: true));

        await db.update(
          'thermal_points',
          {'syncedWithFirebase': 1},
          where: 'id = ?',
          whereArgs: [point['id']],
        );
      }
      debugPrint('${unsyncedPoints.length} puntos termales sincronizados a Firebase');
    } catch (e) {
      debugPrint('Error al sincronizar puntos termales: $e');
    }
  }

  // Descargar datos desde Firebase a SQLite
  Future<void> downloadUsersFromFirebase() async {
    try {
      debugPrint('Descargando usuarios desde Firebase...');
      final db = await _databaseService.database;
      
      final snapshot = await _firestore.collection('users').get();
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        await db.insert(
          'users',
          {
            'id': doc.id,
            'name': data['name'],
            'email': data['email'],
            'passwordHash': data['passwordHash'] ?? '',
            'points': data['points'] ?? 0,
            'level': data['level'] ?? 1,
            'profileImageUrl': data['profileImageUrl'],
            'createdAt': (data['createdAt'] as Timestamp).millisecondsSinceEpoch,
            'updatedAt': (data['updatedAt'] as Timestamp).millisecondsSinceEpoch,
            'syncedWithFirebase': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      debugPrint('${snapshot.docs.length} usuarios descargados desde Firebase');
    } catch (e) {
      debugPrint('Error al descargar usuarios: $e');
    }
  }

  // Descargar puntos termales desde Firebase
  Future<void> downloadThermalPointsFromFirebase() async {
    try {
      debugPrint('Descargando puntos termales desde Firebase...');
      final db = await _databaseService.database;
      
      final snapshot = await _firestore.collection('thermal_points').get();
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        await db.insert(
          'thermal_points',
          {
            'id': doc.id,
            'name': data['name'],
            'description': data['description'],
            'latitude': data['latitude'],
            'longitude': data['longitude'],
            'temperature': data['temperature'],
            'imageUrl': data['imageUrl'],
            'facilities': data['facilities'],
            'createdAt': (data['createdAt'] as Timestamp).millisecondsSinceEpoch,
            'updatedAt': (data['updatedAt'] as Timestamp).millisecondsSinceEpoch,
            'syncedWithFirebase': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      debugPrint('${snapshot.docs.length} puntos termales descargados desde Firebase');
    } catch (e) {
      debugPrint('Error al descargar puntos termales: $e');
    }
  }

  // Sincronización bidireccional completa
  Future<void> syncAll() async {
    try {
      debugPrint('Iniciando sincronización completa...');
      await Future.wait([
        syncUsersToFirebase(),
        syncThermalPointsToFirebase(),
        syncCheckInsToFirebase(),
        syncBadgesToFirebase(),
        downloadUsersFromFirebase(),
        downloadThermalPointsFromFirebase(),
      ]);
      debugPrint('Sincronización completa finalizada');
    } catch (e) {
      debugPrint('Error durante la sincronización completa: $e');
    }
  }

  // Sincronizar check-ins a Firebase
  Future<void> syncCheckInsToFirebase() async {
    try {
      debugPrint('Iniciando sincronización de check-ins a Firebase...');
      final db = await _databaseService.database;
      
      final unsyncedCheckIns = await db.query(
        'check_ins',
        where: 'syncedWithFirebase = ?',
        whereArgs: [0],
      );

      for (var checkIn in unsyncedCheckIns) {
        await _firestore.collection('check_ins').doc(checkIn['id'] as String).set({
          'userId': checkIn['userId'],
          'pointId': checkIn['pointId'],
          'timestamp': DateTime.fromMillisecondsSinceEpoch(checkIn['timestamp'] as int),
          'points': checkIn['points'],
        }, SetOptions(merge: true));

        await db.update(
          'check_ins',
          {'syncedWithFirebase': 1},
          where: 'id = ?',
          whereArgs: [checkIn['id']],
        );
      }
      debugPrint('${unsyncedCheckIns.length} check-ins sincronizados a Firebase');
    } catch (e) {
      debugPrint('Error al sincronizar check-ins: $e');
    }
  }

  // Sincronizar badges a Firebase
  Future<void> syncBadgesToFirebase() async {
    try {
      debugPrint('Iniciando sincronización de badges a Firebase...');
      final db = await _databaseService.database;
      
      final unsyncedBadges = await db.query(
        'badges',
        where: 'syncedWithFirebase = ?',
        whereArgs: [0],
      );

      for (var badge in unsyncedBadges) {
        await _firestore.collection('badges').doc(badge['id'] as String).set({
          'userId': badge['userId'],
          'name': badge['name'],
          'description': badge['description'],
          'icon': badge['icon'],
          'earnedDate': DateTime.fromMillisecondsSinceEpoch(badge['earnedDate'] as int),
        }, SetOptions(merge: true));

        await db.update(
          'badges',
          {'syncedWithFirebase': 1},
          where: 'id = ?',
          whereArgs: [badge['id']],
        );
      }
      debugPrint('${unsyncedBadges.length} badges sincronizados a Firebase');
    } catch (e) {
      debugPrint('Error al sincronizar badges: $e');
    }
  }
}
