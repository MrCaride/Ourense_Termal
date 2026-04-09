import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'database_service.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseService _databaseService = DatabaseService();

  Future<T> _withRetry<T>(
    Future<T> Function() operation, {
    int maxAttempts = 4,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    var attempt = 0;
    var delay = initialDelay;

    while (true) {
      attempt++;
      try {
        return await operation();
      } on FirebaseException catch (e) {
        final retryable = e.code == 'unavailable' ||
            e.code == 'deadline-exceeded' ||
            e.code == 'network-request-failed';

        if (!retryable || attempt >= maxAttempts) {
          rethrow;
        }
      } catch (_) {
        if (attempt >= maxAttempts) {
          rethrow;
        }
      }

      await Future.delayed(delay);
      delay *= 2;
    }
  }

  // Sincronizar usuarios desde SQLite a Firebase
  Future<void> syncUsersToFirebase() async {
    try {
      final db = await _databaseService.database;
      
      // Obtener usuarios no sincronizados
      final unsyncedUsers = await db.query(
        'users',
        where: 'syncedWithFirebase = ?',
        whereArgs: [0],
      );

      for (var user in unsyncedUsers) {
        final userId = user['id'] as String;
        final localUpdatedAt = user['updatedAt'] as int? ?? 0;

        final remote = await _withRetry(
          () => _firestore.collection('users').doc(userId).get(),
        );

        final remoteUpdatedAt =
            (remote.data()?['updatedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;

        // Conflictos: prevalece el último timestamp.
        if (!remote.exists || localUpdatedAt >= remoteUpdatedAt) {
          await _withRetry(() => _firestore.collection('users').doc(userId).set({
                'name': user['name'],
                'email': user['email'],
                'passwordHash': user['passwordHash'],
                'points': user['points'],
                'level': user['level'],
                'profileImageUrl': user['profileImageUrl'],
                'createdAt': DateTime.fromMillisecondsSinceEpoch(
                    user['createdAt'] as int),
                'updatedAt': DateTime.fromMillisecondsSinceEpoch(localUpdatedAt),
              }, SetOptions(merge: true)));
        } else {
          await db.update(
            'users',
            {
              'name': remote.data()?['name'] ?? user['name'],
              'email': remote.data()?['email'] ?? user['email'],
              'passwordHash': remote.data()?['passwordHash'] ?? user['passwordHash'],
              'points': remote.data()?['points'] ?? user['points'],
              'level': remote.data()?['level'] ?? user['level'],
              'profileImageUrl': remote.data()?['profileImageUrl'],
              'updatedAt': remoteUpdatedAt,
              'syncedWithFirebase': 1,
            },
            where: 'id = ?',
            whereArgs: [userId],
          );
          continue;
        }

        // Marcar como sincronizado
        await db.update(
          'users',
          {'syncedWithFirebase': 1},
          where: 'id = ?',
          whereArgs: [user['id']],
        );
      }
    } catch (_) {
    }
  }

  // Sincronizar puntos termales desde SQLite a Firebase
  Future<void> syncThermalPointsToFirebase() async {
    try {
      final db = await _databaseService.database;
      
      final unsyncedPoints = await db.query(
        'thermal_points',
        where: 'syncedWithFirebase = ?',
        whereArgs: [0],
      );

      for (var point in unsyncedPoints) {
        final pointId = point['id'] as String;
        final localUpdatedAt = point['updatedAt'] as int? ?? 0;

        final remote = await _withRetry(
          () => _firestore.collection('thermal_points').doc(pointId).get(),
        );

        final remoteUpdatedAt =
            (remote.data()?['updatedAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;

        if (!remote.exists || localUpdatedAt >= remoteUpdatedAt) {
          await _withRetry(
            () => _firestore.collection('thermal_points').doc(pointId).set({
              'name': point['name'],
              'description': point['description'],
              'latitude': point['latitude'],
              'longitude': point['longitude'],
              'temperature': point['temperature'],
              'imageUrl': point['imageUrl'],
              'facilities': point['facilities'],
              'createdAt': DateTime.fromMillisecondsSinceEpoch(
                  point['createdAt'] as int),
              'updatedAt': DateTime.fromMillisecondsSinceEpoch(localUpdatedAt),
            }, SetOptions(merge: true)),
          );
        }

        await db.update(
          'thermal_points',
          {'syncedWithFirebase': 1},
          where: 'id = ?',
          whereArgs: [pointId],
        );
      }
    } catch (_) {
    }
  }

  // Descargar datos desde Firebase a SQLite
  Future<void> downloadUsersFromFirebase() async {
    try {
      final db = await _databaseService.database;
      
      final snapshot = await _withRetry(() => _firestore.collection('users').get());
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final remoteUpdatedAt = (data['updatedAt'] as Timestamp?)?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch;

        final local = await db.query(
          'users',
          where: 'id = ?',
          whereArgs: [doc.id],
          limit: 1,
        );

        final localUpdatedAt =
            local.isNotEmpty ? (local.first['updatedAt'] as int? ?? 0) : 0;

        if (localUpdatedAt > remoteUpdatedAt) {
          continue;
        }

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
            'createdAt': (data['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                DateTime.now().millisecondsSinceEpoch,
            'updatedAt': remoteUpdatedAt,
            'syncedWithFirebase': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (_) {
    }
  }

  // Descargar puntos termales desde Firebase
  Future<void> downloadThermalPointsFromFirebase() async {
    try {
      final db = await _databaseService.database;
      
        final snapshot =
          await _withRetry(() => _firestore.collection('thermal_points').get());
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final remoteUpdatedAt = (data['updatedAt'] as Timestamp?)?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch;

        final local = await db.query(
          'thermal_points',
          where: 'id = ?',
          whereArgs: [doc.id],
          limit: 1,
        );
        final localUpdatedAt =
            local.isNotEmpty ? (local.first['updatedAt'] as int? ?? 0) : 0;

        if (localUpdatedAt > remoteUpdatedAt) {
          continue;
        }

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
            'createdAt': (data['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                DateTime.now().millisecondsSinceEpoch,
            'updatedAt': remoteUpdatedAt,
            'syncedWithFirebase': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (_) {
    }
  }

  // Sincronización bidireccional completa
  Future<void> syncAll() async {
    try {
      await Future.wait([
        syncUsersToFirebase(),
        syncThermalPointsToFirebase(),
        syncCheckInsToFirebase(),
        syncBadgesToFirebase(),
        syncUserRouteProgressToFirebase(),
        syncRedeemedRewardsToFirebase(),
        downloadUsersFromFirebase(),
        downloadThermalPointsFromFirebase(),
        downloadUserRouteProgressFromFirebase(),
      ]);
    } catch (_) {
    }
  }

  // Sincronizar check-ins a Firebase
  Future<void> syncCheckInsToFirebase() async {
    try {
      final db = await _databaseService.database;
      
      final unsyncedCheckIns = await db.query(
        'check_ins',
        where: 'syncedWithFirebase = ?',
        whereArgs: [0],
      );

      for (var checkIn in unsyncedCheckIns) {
        await _withRetry(
          () => _firestore.collection('check_ins').doc(checkIn['id'] as String).set({
            'userId': checkIn['userId'],
            'pointId': checkIn['pointId'],
            'timestamp':
                DateTime.fromMillisecondsSinceEpoch(checkIn['timestamp'] as int),
            'points': checkIn['points'],
          }, SetOptions(merge: true)),
        );

        await db.update(
          'check_ins',
          {'syncedWithFirebase': 1},
          where: 'id = ?',
          whereArgs: [checkIn['id']],
        );
      }
    } catch (_) {
    }
  }

  // Sincronizar badges a Firebase
  Future<void> syncBadgesToFirebase() async {
    try {
      final db = await _databaseService.database;
      
      final unsyncedBadges = await db.query(
        'badges',
        where: 'syncedWithFirebase = ?',
        whereArgs: [0],
      );

      for (var badge in unsyncedBadges) {
        await _withRetry(
          () => _firestore.collection('badges').doc(badge['id'] as String).set({
            'userId': badge['userId'],
            'name': badge['name'],
            'description': badge['description'],
            'icon': badge['icon'],
            'earnedDate':
                DateTime.fromMillisecondsSinceEpoch(badge['earnedDate'] as int),
          }, SetOptions(merge: true)),
        );

        await db.update(
          'badges',
          {'syncedWithFirebase': 1},
          where: 'id = ?',
          whereArgs: [badge['id']],
        );
      }
    } catch (_) {
    }
  }

  Future<void> syncUserRouteProgressToFirebase() async {
    try {
      final db = await _databaseService.database;
      final unsynced = await db.query(
        'user_route_progress',
        where: 'syncedWithFirebase = ?',
        whereArgs: [0],
      );

      for (final row in unsynced) {
        final id = row['id'] as String;
        final completedIds = (row['completedPointIds'] as String? ?? '')
            .split(',')
            .where((e) => e.isNotEmpty)
            .toList();

        await _withRetry(
          () => _firestore.collection('user_route_progress').doc(id).set({
            'userId': row['userId'],
            'routeId': row['routeId'],
            'progress': row['progress'],
            'isCompleted': row['isCompleted'] == 1,
            'completedPointIds': completedIds,
            'lastUpdated': DateTime.fromMillisecondsSinceEpoch(
                row['lastUpdated'] as int),
            'completedAt': row['completedAt'] != null
                ? DateTime.fromMillisecondsSinceEpoch(row['completedAt'] as int)
                : null,
          }, SetOptions(merge: true)),
        );

        await db.update(
          'user_route_progress',
          {'syncedWithFirebase': 1},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    } catch (_) {
    }
  }

  Future<void> downloadUserRouteProgressFromFirebase() async {
    try {
      final db = await _databaseService.database;
      final snapshot =
          await _withRetry(() => _firestore.collection('user_route_progress').get());

      for (final doc in snapshot.docs) {
        final data = doc.data();
        await db.insert(
          'user_route_progress',
          {
            'id': doc.id,
            'userId': data['userId'],
            'routeId': data['routeId'],
            'progress': (data['progress'] as num?)?.toDouble() ?? 0.0,
            'isCompleted': (data['isCompleted'] as bool? ?? false) ? 1 : 0,
            'completedPointIds':
                (data['completedPointIds'] as List<dynamic>? ?? const [])
                    .map((e) => e.toString())
                    .join(','),
            'lastUpdated': (data['lastUpdated'] as Timestamp?)
                    ?.millisecondsSinceEpoch ??
                DateTime.now().millisecondsSinceEpoch,
            'completedAt':
                (data['completedAt'] as Timestamp?)?.millisecondsSinceEpoch,
            'syncedWithFirebase': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (_) {
    }
  }

  Future<void> syncRedeemedRewardsToFirebase() async {
    try {
      final db = await _databaseService.database;
      final unsynced = await db.query(
        'user_redeemed_rewards',
        where: 'syncedWithFirebase = ?',
        whereArgs: [0],
      );

      for (final row in unsynced) {
        final userId = row['user_id'] as String;
        final id = row['id'] as String;

        await _withRetry(
          () => _firestore
              .collection('users')
              .doc(userId)
              .collection('redeemed_rewards')
              .doc(id)
              .set({
            'rewardId': row['reward_id'],
            'couponCode': row['coupon_code'],
            'redeemedDate':
                DateTime.fromMillisecondsSinceEpoch(row['redeemed_date'] as int),
            'used': (row['used'] as int? ?? 0) == 1,
          }, SetOptions(merge: true)),
        );

        await db.update(
          'user_redeemed_rewards',
          {'syncedWithFirebase': 1},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    } catch (_) {
    }
  }
}
