import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/route_model.dart' as route_model;
import '../models/user_route_progress_model.dart';
import '../services/route_service.dart';

class RoutesScreen extends StatefulWidget {
  final User user;

  const RoutesScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  final RouteService _routeService = RouteService();
  late List<route_model.Route> _routes;
  Map<String, UserRouteProgress> _progressMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Cargar rutas disponibles (ahora es método estático)
    _routes = RouteService.getAvailableRoutes();

    // Cargar progreso del usuario
    _progressMap = await _routeService.getUserRouteProgress(widget.user.id);

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Calcular estadísticas
    final completedCount = _progressMap.values.where((p) => p.isCompleted).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rutas & Retos'),
        elevation: 0,
        backgroundColor: Colors.purple[500],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header con stats
                Container(
                  color: Colors.purple[500],
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('🏆', '$completedCount', 'Completadas'),
                      _buildStat('📍', '${widget.user.points}', 'Puntos'),
                      _buildStat('🗺️', '${_routes.length}', 'Rutas'),
                    ],
                  ),
                ),
                // Rutas
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _routes.length,
                      itemBuilder: (context, index) {
                        final route = _routes[index];
                        final progress = _progressMap[route.id];
                        return _buildRouteCard(route, progress);
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStat(String icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildRouteCard(route_model.Route route, UserRouteProgress? progress) {
    final difficultyColor = _getDifficultyColor(route.difficulty);
    final isCompleted = progress?.isCompleted ?? false;
    final routeProgress = progress?.progress ?? 0.0;
    final completedPoints = progress?.completedPointIds.length ?? 0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCompleted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green[500],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    '¡Ruta Completada!',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tags
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: Text(route.theme),
                      labelStyle: const TextStyle(fontSize: 11),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: difficultyColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        route.getDifficultyLabel(),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Nombre y descripción
                Text(
                  route.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  route.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                // Detalles
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            '${route.distance} km',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer, size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            route.duration,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pin_drop, size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            '${route.thermalPointIds.length} puntos',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress bar con texto
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progreso: $completedPoints/${route.thermalPointIds.length} puntos',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${routeProgress.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: routeProgress / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation(
                          isCompleted ? Colors.green[500] : Colors.cyan[500],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber[600], size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '+${route.points} puntos',
                          style: TextStyle(
                            color: Colors.amber[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (!isCompleted)
                      FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green[500],
                        ),
                        child: const Text('Ver más'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return Colors.green[100]!;
      case 'moderate':
        return Colors.yellow[100]!;
      case 'hard':
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }
}
