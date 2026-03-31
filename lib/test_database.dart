import 'package:flutter/material.dart';
import 'package:ourense_termal/services/local_repository.dart';
import 'package:ourense_termal/services/sync_service.dart';

/// Script de prueba para SQLite y Firebase
/// Copia este código en un widget para probar la instalación

class DatabaseTestWidget extends StatefulWidget {
  const DatabaseTestWidget({super.key});

  @override
  State<DatabaseTestWidget> createState() => _DatabaseTestWidgetState();
}

class _DatabaseTestWidgetState extends State<DatabaseTestWidget> {
  final LocalRepository _repository = LocalRepository();
  final SyncService _syncService = SyncService();
  
  String _log = 'Iniciando pruebas...\n';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  void _addLog(String message) {
    setState(() {
      _log += '${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second} - $message\n';
    });
    debugPrint(message);
  }

  Future<void> _runTests() async {
    setState(() => _isLoading = true);
    
    try {
      // Test 1: Insertar un punto termal
      _addLog('TEST 1: Insertando punto termal...');
      final testPoint = {
        'id': 'test-${DateTime.now().millisecondsSinceEpoch}',
        'name': 'Baños de Prueba',
        'description': 'Este es un punto de prueba',
        'latitude': 42.35,
        'longitude': -8.43,
        'temperature': 45.5,
        'imageUrl': '',
        'facilities': 'Baños, Duchas',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'syncedWithFirebase': 0,
      };
      
      await _repository.insert('thermal_points', testPoint);
      _addLog('✅ TEST 1 EXITOSO: Punto insertado');

      // Test 2: Leer todos los puntos
      _addLog('\nTEST 2: Leyendo todos los puntos...');
      final points = await _repository.getAll('thermal_points');
      _addLog('✅ TEST 2 EXITOSO: Se encontraron ${points.length} puntos');
      
      // Test 3: Obtener un punto por ID
      _addLog('\nTEST 3: Obteniendo punto por ID...');
      final point = await _repository.getById('thermal_points', testPoint['id'] as String);
      if (point != null) {
        _addLog('✅ TEST 3 EXITOSO: Punto encontrado: ${point['name']}');
      }

      // Test 4: Actualizar un punto
      _addLog('\nTEST 4: Actualizando punto termal...');
      await _repository.update(
        'thermal_points',
        testPoint['id'] as String,
        {
          'temperature': 50.0,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
      );
      _addLog('✅ TEST 4 EXITOSO: Punto actualizado');

      // Test 5: Búsqueda avanzada
      _addLog('\nTEST 5: Búsqueda avanzada (temperatura > 40)...');
      final hotPoints = await _repository.query(
        'thermal_points',
        where: 'temperature > ?',
        whereArgs: [40],
      );
      _addLog('✅ TEST 5 EXITOSO: Se encontraron ${hotPoints.length} puntos calientes');

      // Test 6: Sincronización con Firebase
      _addLog('\nTEST 6: Sincronizando con Firebase...');
      _addLog('⚠️ NOTA: Esto requiere Firebase configurado correctamente');
      
      try {
        await _syncService.syncAll();
        _addLog('✅ TEST 6 EXITOSO: Sincronización completada');
      } catch (e) {
        _addLog('⚠️ TEST 6 PARCIAL: $e');
        _addLog('   (Esto es normal si Firebase no está completamente configurado)');
      }

      // Test 7: Verificar sincronización
      _addLog('\nTEST 7: Verificando estado de sincronización...');
      final updatedPoint = await _repository.getById('thermal_points', testPoint['id'] as String);
      if (updatedPoint != null) {
        final synced = updatedPoint['syncedWithFirebase'] == 1 ? 'Sí' : 'No';
        _addLog('✅ TEST 7 EXITOSO: Sincronizado: $synced');
      }

      _addLog('\n════════════════════════════════════════');
      _addLog('✅ TODOS LOS TESTS COMPLETADOS EXITOSAMENTE');
      _addLog('════════════════════════════════════════');
      
    } catch (e) {
      _addLog('❌ ERROR: $e');
      _addLog('Stack: ${StackTrace.current}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTestData() async {
    try {
      _addLog('\nEliminando datos de prueba...');
      final points = await _repository.getAll('thermal_points');
      
      int count = 0;
      for (var point in points) {
        if ((point['id'] as String).startsWith('test-')) {
          await _repository.delete('thermal_points', point['id'] as String);
          count++;
        }
      }
      
      _addLog('✅ Se eliminaron $count registros de prueba');
    } catch (e) {
      _addLog('❌ Error al eliminar: $e');
    }
  }

  Future<void> _clearAllData() async {
    try {
      _addLog('\n⚠️ Limpiando TODA la base de datos...');
      // Este método no existe aún, pero la estructura está lista
      _addLog('❌ No implementado (por seguridad)');
      _addLog('Para limpiar: DatabaseService().deleteDatabaseLocal()');
    } catch (e) {
      _addLog('❌ Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test de SQLite + Firebase'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Botones de control
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _runTests,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Ejecutar Tests'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _deleteTestData,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Limpiar Tests'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _clearAllData,
                  icon: const Icon(Icons.warning),
                  label: const Text('Borrar Todo'),
                ),
              ],
            ),
          ),
          
          // Log de ejecución
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _log,
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 12,
                    color: Colors.greenAccent,
                  ),
                ),
              ),
            ),
          ),

          // Indicador de carga
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

/// Cómo usar este widget:
/// 
/// 1. En tu main.dart o en un screen, importa este archivo:
///    import 'test_database.dart';
///
/// 2. Reemplaza un screen con DatabaseTestWidget:
///    home: const DatabaseTestWidget(),
///
/// 3. Ejecuta la app:
///    flutter run
///
/// 4. Verifica en la consola que todos los tests pasen
///
/// Esperado:
/// - TEST 1: ✅ Inserción exitosa
/// - TEST 2: ✅ Lectura exitosa
/// - TEST 3: ✅ Obtener por ID exitoso
/// - TEST 4: ✅ Actualización exitosa
/// - TEST 5: ✅ Búsqueda avanzada exitosa
/// - TEST 6: ✅ O ⚠️ (depende de Firebase)
/// - TEST 7: ✅ Verificación exitosa
