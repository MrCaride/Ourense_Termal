import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static sqflite.Database? _database;

  // Versión de la base de datos
  static const int _version = 5;
  static const String _dbName = 'ourense_termal.db';

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  // Getter para acceder a la base de datos
  Future<sqflite.Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  // Inicializar la base de datos
  Future<sqflite.Database> _initDatabase() async {
    final dbPath = await sqflite.getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await sqflite.openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Crear las tablas en la primera ejecución
  Future<void> _onCreate(sqflite.Database db, int version) async {
    // Tabla de usuarios
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        passwordHash TEXT NOT NULL,
        points INTEGER DEFAULT 0,
        level INTEGER DEFAULT 1,
        role TEXT DEFAULT 'user',
        thermalPointId TEXT,
        profileImageUrl TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        syncedWithFirebase INTEGER DEFAULT 0
      )
    ''');

    // Tabla de check-ins
    await db.execute('''
      CREATE TABLE check_ins (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        pointId TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        points INTEGER DEFAULT 50,
        syncedWithFirebase INTEGER DEFAULT 0,
        FOREIGN KEY(userId) REFERENCES users(id)
      )
    ''');

    // Tabla de insignias
    await db.execute('''
      CREATE TABLE badges (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        icon TEXT NOT NULL,
        earnedDate INTEGER NOT NULL,
        syncedWithFirebase INTEGER DEFAULT 0,
        FOREIGN KEY(userId) REFERENCES users(id)
      )
    ''');

    // Tabla de puntos termales
    await db.execute('''
      CREATE TABLE thermal_points (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        temperature REAL,
        imageUrl TEXT,
        facilities TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        syncedWithFirebase INTEGER DEFAULT 0
      )
    ''');

    // Tabla de rutas
    await db.execute('''
      CREATE TABLE routes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        distance REAL,
        difficulty TEXT,
        estimatedTime INTEGER,
        waypoints TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        syncedWithFirebase INTEGER DEFAULT 0
      )
    ''');

    // Tabla de retos
    await db.execute('''
      CREATE TABLE challenges (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        objective TEXT,
        progress REAL DEFAULT 0,
        completed INTEGER DEFAULT 0,
        reward REAL DEFAULT 0,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        syncedWithFirebase INTEGER DEFAULT 0,
        FOREIGN KEY(userId) REFERENCES users(id)
      )
    ''');

    // Tabla de logros
    await db.execute('''
      CREATE TABLE achievements (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        badge TEXT,
        unlockedAt INTEGER,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        syncedWithFirebase INTEGER DEFAULT 0,
        FOREIGN KEY(userId) REFERENCES users(id)
      )
    ''');

    // Tabla de recompensas
    await db.execute('''
      CREATE TABLE rewards (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        points INTEGER NOT NULL,
        imageUrl TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        syncedWithFirebase INTEGER DEFAULT 0
      )
    ''');

    // Tabla de progreso de rutas por usuario
    await db.execute('''
      CREATE TABLE user_route_progress (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        routeId TEXT NOT NULL,
        progress REAL DEFAULT 0,
        isCompleted INTEGER DEFAULT 0,
        completedPointIds TEXT,
        lastUpdated INTEGER NOT NULL,
        completedAt INTEGER,
        syncedWithFirebase INTEGER DEFAULT 0,
        FOREIGN KEY(userId) REFERENCES users(id)
      )
    ''');

    // Tabla de recompensas canjeadas por usuarios
    await db.execute('''
      CREATE TABLE user_redeemed_rewards (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        reward_id TEXT NOT NULL,
        coupon_code TEXT NOT NULL,
        redeemed_date INTEGER NOT NULL,
        used INTEGER DEFAULT 0,
        syncedWithFirebase INTEGER DEFAULT 0,
        FOREIGN KEY(user_id) REFERENCES users(id)
      )
    ''');

  }

  // Manejar actualizaciones de esquema
  Future<void> _onUpgrade(sqflite.Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE users ADD COLUMN passwordHash TEXT NOT NULL DEFAULT ''");
      await db.execute('ALTER TABLE users ADD COLUMN points INTEGER DEFAULT 0');
      await db.execute('ALTER TABLE users ADD COLUMN level INTEGER DEFAULT 1');
      
      // Crear tablas de check-ins y badges
      await db.execute('''
        CREATE TABLE IF NOT EXISTS check_ins (
          id TEXT PRIMARY KEY,
          userId TEXT NOT NULL,
          pointId TEXT NOT NULL,
          timestamp INTEGER NOT NULL,
          points INTEGER DEFAULT 50,
          syncedWithFirebase INTEGER DEFAULT 0,
          FOREIGN KEY(userId) REFERENCES users(id)
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS badges (
          id TEXT PRIMARY KEY,
          userId TEXT NOT NULL,
          name TEXT NOT NULL,
          description TEXT NOT NULL,
          icon TEXT NOT NULL,
          earnedDate INTEGER NOT NULL,
          syncedWithFirebase INTEGER DEFAULT 0,
          FOREIGN KEY(userId) REFERENCES users(id)
        )
      ''');
    }
    
    if (oldVersion < 3) {
      // Agregar tabla de progreso de rutas por usuario
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_route_progress (
          id TEXT PRIMARY KEY,
          userId TEXT NOT NULL,
          routeId TEXT NOT NULL,
          progress REAL DEFAULT 0,
          isCompleted INTEGER DEFAULT 0,
          completedPointIds TEXT,
          lastUpdated INTEGER NOT NULL,
          completedAt INTEGER,
          syncedWithFirebase INTEGER DEFAULT 0,
          FOREIGN KEY(userId) REFERENCES users(id)
        )
      ''');
    }
    
    if (oldVersion < 4) {
      // Agregar tabla de recompensas canjeadas por usuarios
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_redeemed_rewards (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          reward_id TEXT NOT NULL,
          coupon_code TEXT NOT NULL,
          redeemed_date INTEGER NOT NULL,
          used INTEGER DEFAULT 0,
          syncedWithFirebase INTEGER DEFAULT 0,
          FOREIGN KEY(user_id) REFERENCES users(id)
        )
      ''');
    }

    if (oldVersion < 5) {
      // Agregar columnas de rol y punto termal asignado
      await db.execute("ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'user'");
      await db.execute("ALTER TABLE users ADD COLUMN thermalPointId TEXT");
    }
  }

  // Cerrar la base de datos
  Future<void> close() async {
    _database?.close();
    _database = null;
  }

  // Método para borrar toda la base de datos (útil para testing)
  Future<void> deleteDatabaseLocal() async {
    final dbPath = await sqflite.getDatabasesPath();
    final path = join(dbPath, _dbName);
    await sqflite.deleteDatabase(path);
    _database = null;
  }

  // Método unificado que usa SQLite en móvil/desktop y Firestore en web
  Future<List<Map<String, dynamic>>> getBalnearios() async {
    if (kIsWeb) {
      // En web, leer directamente de Firebase
      final snapshot = await FirebaseFirestore.instance
          .collection('balnearios')
          .get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } else {
      // En móvil/desktop, usar SQLite local
      final db = await database;
      return await db.query('balnearios');
    }
  }

  // Similar para otros métodos (getRutas, getPiscinas, etc.)
}
