import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'database_service.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthService {
  final DatabaseService _databaseService = DatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _userIdKey = 'logged_user_id';
  static const String _userEmailKey = 'logged_user_email';

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // Guardar sesión del usuario
  Future<void> _saveSession(String userId, String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, userId);
      await prefs.setString(_userEmailKey, email);
    } catch (e) {
      debugPrint('Error al guardar sesión: $e');
      // No lanzar error, solo registrar
    }
  }

  // Eliminar sesión del usuario
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
      await prefs.remove(_userEmailKey);
    } catch (e) {
      debugPrint('Error al cerrar sesión: $e');
      // No lanzar error, solo registrar
    }
  }

  // Obtener usuario de sesión guardada
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_userIdKey);
      final email = prefs.getString(_userEmailKey);

      if (userId == null || email == null) {
        return null;
      }

      if (kIsWeb) {
        final doc = await _firestore.collection('users').doc(userId).get();
        if (!doc.exists) {
          await logout();
          return null;
        }

        final data = doc.data()!;
        return User(
          id: doc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? email,
          passwordHash: data['passwordHash'] ?? '',
          points: data['points'] ?? 0,
          level: data['level'] ?? 1,
          joinedDate: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      } else {
        final db = await _databaseService.database;
        final result = await db.query(
          'users',
          where: 'id = ?',
          whereArgs: [userId],
          limit: 1,
        );

        if (result.isEmpty) {
          await logout();
          return null;
        }

        return User.fromMap(Map<String, dynamic>.from(result.first));
      }
    } catch (e) {
      debugPrint('Error al recuperar sesión: $e');
      // En caso de error con SharedPreferences (especialmente en web), retornar null
      return null;
    }
  }

  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final passwordHash = _hashPassword(password);
    final now = DateTime.now();

    if (kIsWeb) {
      try {
        final existing = await _firestore
            .collection('users')
            .where('email', isEqualTo: normalizedEmail)
            .limit(1)
            .get();
        if (existing.docs.isNotEmpty) {
          throw AuthException('Este email ya está registrado.');
        }

        final docRef = _firestore.collection('users').doc();
        final user = User(
          id: docRef.id,
          name: name.trim(),
          email: normalizedEmail,
          passwordHash: passwordHash,
          points: 0,
          level: 1,
          joinedDate: now,
          badges: [],
        );

        await docRef.set({
          'name': user.name,
          'email': user.email,
          'passwordHash': user.passwordHash,
          'points': 0,
          'level': 1,
          'profileImageUrl': null,
          'createdAt': now,
          'updatedAt': now,
        });

        // Guardar sesión
        await _saveSession(user.id, user.email);

        return user;
      } on FirebaseException catch (e) {
        throw AuthException(e.message ?? 'Error al registrar en Firebase.');
      }
    }

    final db = await _databaseService.database;
    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [normalizedEmail],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      throw AuthException('Este email ya está registrado.');
    }

    final user = User(
      id: now.millisecondsSinceEpoch.toString(),
      name: name.trim(),
      email: normalizedEmail,
      passwordHash: passwordHash,
      points: 0,
      level: 1,
      joinedDate: now,
      badges: [],
    );

    await db.insert('users', {
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'passwordHash': user.passwordHash,
      'points': 0,
      'level': 1,
      'profileImageUrl': null,
      'createdAt': now.millisecondsSinceEpoch,
      'updatedAt': now.millisecondsSinceEpoch,
      'syncedWithFirebase': 0,
    });

    // Guardar sesión
    await _saveSession(user.id, user.email);

    return user;
  }

  Future<User> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final passwordHash = _hashPassword(password);

    if (kIsWeb) {
      try {
        final snapshot = await _firestore
            .collection('users')
            .where('email', isEqualTo: normalizedEmail)
            .limit(1)
            .get();

        if (snapshot.docs.isEmpty) {
          throw AuthException('Credenciales incorrectas.');
        }

        final data = snapshot.docs.first.data();
        if ((data['passwordHash'] ?? '') != passwordHash) {
          throw AuthException('Credenciales incorrectas.');
        }

        final user = User(
          id: snapshot.docs.first.id,
          name: data['name'] ?? '',
          email: data['email'] ?? normalizedEmail,
          passwordHash: data['passwordHash'] ?? '',
          points: data['points'] ?? 0,
          level: data['level'] ?? 1,
          joinedDate: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );

        // Guardar sesión
        await _saveSession(user.id, user.email);

        return user;
      } on FirebaseException catch (e) {
        throw AuthException(e.message ?? 'Error al iniciar sesión en Firebase.');
      }
    }

    final db = await _databaseService.database;
    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [normalizedEmail],
      limit: 1,
    );

    if (result.isEmpty) {
      throw AuthException('Credenciales incorrectas.');
    }

    final userMap = result.first;
    if ((userMap['passwordHash'] as String? ?? '') != passwordHash) {
      throw AuthException('Credenciales incorrectas.');
    }

    final user = User.fromMap(Map<String, dynamic>.from(userMap));

    // Guardar sesión
    await _saveSession(user.id, user.email);

    return user;
  }
}
