import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import 'database_service.dart';
import 'user_data_service.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  static const String _userIdKey = 'logged_user_id';
  static const String _userEmailKey = 'logged_user_email';

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  String? _extractRoleValue(Map<String, dynamic> data) {
    final dynamic raw =
        data['role'] ?? data['rol'] ?? data['userRole'] ?? data['tipo'];
    if (raw == null) return null;
    return raw.toString();
  }

  String? _extractThermalPointId(Map<String, dynamic> data) {
    final dynamic raw =
        data['thermalPointId'] ?? data['thermal_point_id'] ?? data['pointId'];
    if (raw == null) return null;
    final value = raw.toString().trim();
    return value.isEmpty ? null : value;
  }

  UserRole _resolveRoleFromProfile(Map<String, dynamic> data) {
    final parsedRole = UserRole.fromString(_extractRoleValue(data) ?? 'user');
    final thermalPointId = _extractThermalPointId(data);
    if (parsedRole == UserRole.user &&
        thermalPointId != null &&
        thermalPointId.trim().isNotEmpty) {
      return UserRole.thermalManager;
    }
    return parsedRole;
  }

  // Guardar sesión del usuario
  Future<void> _saveSession(String userId, String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, userId);
      await prefs.setString(_userEmailKey, email);
    } catch (_) {
      // No lanzar error, solo registrar
    }
  }

  // Eliminar sesión del usuario
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
      await prefs.remove(_userEmailKey);
      await _firebaseAuth.signOut();
    } catch (_) {
      // No lanzar error, solo registrar
    }
  }

  Future<String?> deleteCurrentAccount() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw AuthException('No hay una sesión activa.');
    }

    final userId = currentUser.uid;
    String? cleanupWarning;

    try {
      await UserDataService().deleteUser(userId);
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AuthException(
          'Para borrar la cuenta, cierra sesión, vuelve a entrar y prueba de nuevo.',
        );
      }
      throw AuthException('No se pudo borrar la cuenta. Inténtalo de nuevo.');
    } catch (_) {
      cleanupWarning = 'La cuenta se eliminó, pero no se pudieron borrar todos los datos asociados.';
    }

    try {
      await currentUser.delete();
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AuthException(
          'Para borrar la cuenta, cierra sesión, vuelve a entrar y prueba de nuevo.',
        );
      }
      throw AuthException('No se pudo borrar la cuenta. Inténtalo de nuevo.');
    } finally {
      await logout();
    }

    return cleanupWarning;
  }

  // Obtener usuario de sesión guardada
  Future<User?> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_userIdKey);
      final email = prefs.getString(_userEmailKey);

      // En web solo se confía en Firebase Auth para evitar UID local obsoleto.
      if (kIsWeb && firebaseUser == null) {
        await prefs.remove(_userIdKey);
        await prefs.remove(_userEmailKey);
        return null;
      }

      final effectiveUserId = firebaseUser?.uid ?? (kIsWeb ? null : userId);
      final effectiveEmail = firebaseUser?.email ?? (kIsWeb ? null : email);

      if (effectiveUserId == null || effectiveEmail == null) {
        return null;
      }

      if (firebaseUser != null &&
          (userId != firebaseUser.uid || email != firebaseUser.email)) {
        await _saveSession(firebaseUser.uid, firebaseUser.email ?? effectiveEmail);
      }

      if (kIsWeb) {
        final doc = await _firestore.collection('users').doc(effectiveUserId).get();
        if (!doc.exists) {
          await logout();
          return null;
        }

        final data = doc.data()!;
        return User(
          id: doc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? effectiveEmail,
          passwordHash: data['passwordHash'] ?? '',
          points: data['points'] ?? 0,
          level: data['level'] ?? 1,
          joinedDate: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          role: _resolveRoleFromProfile(data),
          thermalPointId: _extractThermalPointId(data),
        );
      } else {
        final db = await _databaseService.database;
        // Si existe sesión Firebase, prioriza perfil remoto para evitar rol local obsoleto.
        if (firebaseUser != null) {
          try {
            final remoteDoc = await _firestore
                .collection('users')
                .doc(effectiveUserId)
                .get();

            if (remoteDoc.exists) {
              final remote = remoteDoc.data()!;
              final remoteUser = User(
                id: effectiveUserId,
                name: remote['name'] ?? '',
                email: remote['email'] ?? effectiveEmail,
                passwordHash: remote['passwordHash'] ?? '',
                points: remote['points'] ?? 0,
                level: remote['level'] ?? 1,
                role: _resolveRoleFromProfile(remote),
                thermalPointId: _extractThermalPointId(remote),
                joinedDate:
                    (remote['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              );

              await db.insert('users', {
                'id': remoteUser.id,
                'name': remoteUser.name,
                'email': remoteUser.email,
                'passwordHash': remoteUser.passwordHash,
                'points': remoteUser.points,
                'level': remoteUser.level,
                'role': remoteUser.role.getValue(),
                'thermalPointId': remoteUser.thermalPointId,
                'profileImageUrl': remote['profileImageUrl'],
                'createdAt': (remote['createdAt'] as Timestamp?)
                        ?.millisecondsSinceEpoch ??
                    DateTime.now().millisecondsSinceEpoch,
                'updatedAt': (remote['updatedAt'] as Timestamp?)
                        ?.millisecondsSinceEpoch ??
                    DateTime.now().millisecondsSinceEpoch,
                'syncedWithFirebase': 1,
              }, conflictAlgorithm: ConflictAlgorithm.replace);

              return remoteUser;
            }
          } catch (_) {
            // Si falla remoto, se intenta recuperar sesión local.
          }
        }

        final local = await db.query(
          'users',
          where: 'id = ?',
          whereArgs: [effectiveUserId],
          limit: 1,
        );

        if (local.isEmpty) {
          await logout();
          return null;
        }

        return User.fromMap(Map<String, dynamic>.from(local.first));
      }
    } catch (_) {
      // En caso de error con SharedPreferences (especialmente en web), retornar null
      return null;
    }
  }

  Future<User> register({
    required String name,
    required String email,
    required String password,
    UserRole role = UserRole.user,
    required bool acceptedTerms,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final passwordHash = _hashPassword(password);
    final now = DateTime.now();

    if (name.trim().length < 2) {
      throw AuthException('El nombre debe tener al menos 2 caracteres.');
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(normalizedEmail)) {
      throw AuthException('El formato del email no es correcto.');
    }

    if (password.length < 6) {
      throw AuthException('La contraseña debe tener al menos 6 caracteres.');
    }

    if (!acceptedTerms) {
      throw AuthException('Debes aceptar los términos de uso para crear la cuenta.');
    }

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        throw AuthException('No se pudo crear la cuenta. Inténtalo de nuevo.');
      }

      final user = User(
        id: uid,
        name: name.trim(),
        email: normalizedEmail,
        passwordHash: passwordHash,
        points: 0,
        level: 1,
        joinedDate: now,
        role: role,
        badges: [],
      );

      await _firestore.collection('users').doc(uid).set({
        'name': user.name,
        'email': user.email,
        'passwordHash': user.passwordHash,
        'points': 0,
        'level': 1,
        'role': role.getValue(),
        'profileImageUrl': null,
        'createdAt': now,
        'updatedAt': now,
      }, SetOptions(merge: true));

      if (!kIsWeb) {
        final db = await _databaseService.database;
        await db.insert(
          'users',
          {
            'id': user.id,
            'name': user.name,
            'email': user.email,
            'passwordHash': user.passwordHash,
            'points': 0,
            'level': 1,
            'role': role.getValue(),
            'profileImageUrl': null,
            'createdAt': now.millisecondsSinceEpoch,
            'updatedAt': now.millisecondsSinceEpoch,
            'syncedWithFirebase': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await _saveSession(user.id, user.email);
      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw AuthException('Usuario ya existente.');
        case 'invalid-email':
          throw AuthException('El formato del email no es correcto.');
        case 'weak-password':
          throw AuthException('La contraseña es demasiado débil.');
        case 'network-request-failed':
          throw AuthException('Sin conexión. Revisa tu red e inténtalo de nuevo.');
        default:
          throw AuthException('Error inesperado al crear la cuenta.');
      }
    } on FirebaseException {
      throw AuthException('Error inesperado al crear la cuenta.');
    } catch (_) {
      throw AuthException('Error inesperado al crear la cuenta.');
    }
  }

  Future<User> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final passwordHash = _hashPassword(password);

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(normalizedEmail)) {
      throw AuthException('El formato del email no es correcto.');
    }

    if (password.isEmpty) {
      throw AuthException('Debes introducir tu contraseña.');
    }

    if (!kIsWeb) {
      // Escenario offline-first: primero validamos en SQLite.
      final db = await _databaseService.database;
      final localResult = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [normalizedEmail],
        limit: 1,
      );

      if (localResult.isNotEmpty) {
        final userMap = localResult.first;
        final localPasswordMatches =
            (userMap['passwordHash'] as String? ?? '') == passwordHash;

        final localUser = User.fromMap(Map<String, dynamic>.from(userMap));

        try {
          final credential = await _firebaseAuth.signInWithEmailAndPassword(
            email: normalizedEmail,
            password: password,
          );

          final uid = credential.user?.uid;
          if (uid != null) {
            final profileDoc = await _firestore.collection('users').doc(uid).get();
            if (profileDoc.exists) {
              final data = profileDoc.data()!;
              final remoteUser = User(
                id: uid,
                name: data['name'] ?? '',
                email: data['email'] ?? normalizedEmail,
                passwordHash: data['passwordHash'] ?? passwordHash,
                points: data['points'] ?? 0,
                level: data['level'] ?? 1,
                role: _resolveRoleFromProfile(data),
                thermalPointId: _extractThermalPointId(data),
                joinedDate:
                    (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              );

              await db.insert(
                'users',
                {
                  'id': remoteUser.id,
                  'name': remoteUser.name,
                  'email': remoteUser.email,
                  'passwordHash': remoteUser.passwordHash,
                  'points': remoteUser.points,
                  'level': remoteUser.level,
                  'role': remoteUser.role.getValue(),
                  'thermalPointId': remoteUser.thermalPointId,
                  'profileImageUrl': data['profileImageUrl'],
                  'createdAt': (data['createdAt'] as Timestamp?)
                          ?.millisecondsSinceEpoch ??
                      DateTime.now().millisecondsSinceEpoch,
                  'updatedAt': DateTime.now().millisecondsSinceEpoch,
                  'syncedWithFirebase': 1,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );

              await _saveSession(remoteUser.id, remoteUser.email);
              return remoteUser;
            }
          }
        } on firebase_auth.FirebaseAuthException catch (e) {
          if (!localPasswordMatches) {
            switch (e.code) {
              case 'invalid-credential':
              case 'wrong-password':
              case 'user-not-found':
                throw AuthException('Credenciales inválidas.');
              case 'network-request-failed':
                throw AuthException(
                  'Sin conexión y no existe una copia local válida para validar.',
                );
              default:
                throw AuthException('Error al iniciar sesión. Inténtalo de nuevo.');
            }
          }
        } catch (_) {
          if (!localPasswordMatches) {
            throw AuthException('Credenciales inválidas.');
          }
        }

        if (!localPasswordMatches) {
          throw AuthException('Credenciales inválidas.');
        }

        await _saveSession(localUser.id, localUser.email);
        return localUser;
      }
    }

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        throw AuthException('No se pudo iniciar sesión.');
      }

      final profileDoc = await _firestore.collection('users').doc(uid).get();
      if (!profileDoc.exists) {
        throw AuthException('Usuario no registrado.');
      }

      final data = profileDoc.data()!;
      final user = User(
        id: uid,
        name: data['name'] ?? '',
        email: data['email'] ?? normalizedEmail,
        passwordHash: data['passwordHash'] ?? passwordHash,
        points: data['points'] ?? 0,
        level: data['level'] ?? 1,
        role: _resolveRoleFromProfile(data),
        thermalPointId: _extractThermalPointId(data),
        joinedDate: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );

      if (!kIsWeb) {
        final db = await _databaseService.database;
        await db.insert(
          'users',
          {
            'id': user.id,
            'name': user.name,
            'email': user.email,
            'passwordHash': user.passwordHash,
            'points': user.points,
            'level': user.level,
            'role': user.role.getValue(),
            'thermalPointId': user.thermalPointId,
            'profileImageUrl': data['profileImageUrl'],
            'createdAt': (data['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
                DateTime.now().millisecondsSinceEpoch,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
            'syncedWithFirebase': 1,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await _saveSession(user.id, user.email);
      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
          throw AuthException('Credenciales inválidas.');
        case 'user-not-found':
          throw AuthException('Usuario no registrado.');
        case 'network-request-failed':
          throw AuthException(
            'Sin conexión y no existe una copia local para validar.',
          );
        default:
          throw AuthException('Error al iniciar sesión. Inténtalo de nuevo.');
      }
    } catch (_) {
      throw AuthException('Error al iniciar sesión. Inténtalo de nuevo.');
    }
  }

  Future<void> _refreshLocalUserFromFirebase({
    required String email,
    required String password,
    required String localPasswordHash,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) return;

      final profileDoc = await _firestore.collection('users').doc(uid).get();
      if (!profileDoc.exists || kIsWeb) return;

      final data = profileDoc.data()!;
      final db = await _databaseService.database;
      await db.insert(
        'users',
        {
          'id': uid,
          'name': data['name'] ?? '',
          'email': data['email'] ?? email,
          'passwordHash': data['passwordHash'] ?? localPasswordHash,
          'points': data['points'] ?? 0,
          'level': data['level'] ?? 1,
          'role': data['role'] ?? UserRole.user.getValue(),
          'thermalPointId': data['thermalPointId'],
          'profileImageUrl': data['profileImageUrl'],
          'createdAt': (data['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
              DateTime.now().millisecondsSinceEpoch,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
          'syncedWithFirebase': 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {
      // No bloquea el login offline exitoso.
    }
  }
}
