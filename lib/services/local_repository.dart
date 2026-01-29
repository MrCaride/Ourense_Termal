import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

class LocalRepository {
  final DatabaseService _databaseService = DatabaseService();

  // Obtener todos los registros de una tabla
  Future<List<Map<String, dynamic>>> getAll(String tableName) async {
    final db = await _databaseService.database;
    return await db.query(tableName);
  }

  // Obtener un registro por ID
  Future<Map<String, dynamic>?> getById(String tableName, String id) async {
    final db = await _databaseService.database;
    final result = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Insertar un nuevo registro
  Future<void> insert(String tableName, Map<String, dynamic> data) async {
    final db = await _databaseService.database;
    await db.insert(
      tableName,
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Actualizar un registro
  Future<void> update(
    String tableName,
    String id,
    Map<String, dynamic> data,
  ) async {
    final db = await _databaseService.database;
    await db.update(
      tableName,
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Eliminar un registro
  Future<void> delete(String tableName, String id) async {
    final db = await _databaseService.database;
    await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Obtener registros con filtros personalizados
  Future<List<Map<String, dynamic>>> query(
    String tableName, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
  }) async {
    final db = await _databaseService.database;
    return await db.query(
      tableName,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
    );
  }

  // Ejecutar una transacción
  Future<T> transaction<T>(Future<T> Function(Transaction) operation) async {
    final db = await _databaseService.database;
    return await db.transaction(operation);
  }
}
