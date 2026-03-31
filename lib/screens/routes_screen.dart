import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/route_model.dart' as route_model;
import '../models/user_route_progress_model.dart';
import '../services/route_service.dart';
import '../data/thermal_points_data.dart';
import '../utils/app_theme.dart';

class RoutesScreen extends StatefulWidget {
  final User user;
  final VoidCallback? onCheckIn;

  const RoutesScreen({super.key, required this.user, this.onCheckIn});

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

  @override
  void didUpdateWidget(RoutesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id) {
      _loadData();
    }
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
    final completionRatio = _routes.isEmpty ? 0.0 : completedCount / _routes.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Rutas & Retos')),
      backgroundColor: const Color(0xFFF6FAFD),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.brandTeal, Color(0xFF0284C7), Color(0xFF0EA5A4)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tu progreso de exploración',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$completedCount de ${_routes.length} rutas completadas',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 8,
                            value: completionRatio,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStat(Icons.flag_rounded, '$completedCount', 'Completadas'),
                            _buildStat(Icons.stars_rounded, '${widget.user.points}', 'Puntos'),
                            _buildStat(Icons.route_rounded, '${_routes.length}', 'Rutas'),
                          ],
                        ),
                      ],
                    ),
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

  Widget _buildStat(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 24),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              gradient: LinearGradient(colors: _routeAccent(route.difficulty)),
            ),
          ),
          if (isCompleted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green[500],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(0),
                  topRight: Radius.circular(0),
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
                      labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      backgroundColor: const Color(0xFFE6F4F1),
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
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Nombre y descripción
                Text(
                  route.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
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
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text('${route.distance} km', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(route.duration, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.pin_drop, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text('${route.thermalPointIds.length} pts', style: const TextStyle(fontSize: 12)),
                          ],
                        ),
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
                        onPressed: () {
                          _showRouteDetails(context, route);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.brandTeal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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

  List<Color> _routeAccent(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return const [Color(0xFF16A34A), Color(0xFF22C55E)];
      case 'moderate':
        return const [Color(0xFFD97706), Color(0xFFF59E0B)];
      case 'hard':
        return const [Color(0xFFDC2626), Color(0xFFEF4444)];
      default:
        return const [Color(0xFF0D9488), Color(0xFF06B6D4)];
    }
  }

  void _showRouteDetails(BuildContext context, route_model.Route route) {
    final thermalPoints = ThermalPointsData.getThermalPoints();
    final routePoints = thermalPoints
        .where((p) => route.thermalPointIds.contains(p.id))
        .toList();
    final progress = _progressMap[route.id];
    final completedPointIds = progress?.completedPointIds ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.name,
                          style: const TextStyle(
                            fontSize: 20,
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
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Stats
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Icon(Icons.location_on, color: Colors.blue[600]),
                        const SizedBox(height: 4),
                        Text(
                          '${route.distance} km',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.timer, color: Colors.blue[600]),
                        const SizedBox(height: 4),
                        Text(
                          route.duration,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Icon(Icons.star, color: Colors.amber[600]),
                        const SizedBox(height: 4),
                        Text(
                          '+${route.points}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Puntos termales
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        border: Border.all(color: Colors.blue[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Puntos termales que componen esta ruta',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${completedPointIds.length}/${route.thermalPointIds.length} visitados',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (routePoints.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            'No se encontraron puntos termales para esta ruta',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: routePoints.length,
                          itemBuilder: (context, index) {
                            final point = routePoints[index];
                            final isCompleted = completedPointIds.contains(point.id);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isCompleted
                                      ? Colors.green[500]
                                      : Colors.grey[300],
                                  child: Icon(
                                    isCompleted ? Icons.check : Icons.location_on,
                                    color: isCompleted
                                        ? Colors.white
                                        : Colors.grey[600],
                                  ),
                                ),
                                title: Text(point.name),
                                subtitle: Text(point.address),
                                trailing: isCompleted
                                    ? const Chip(
                                        label: Text('Visitado'),
                                        backgroundColor: Color(0xFF4ade80),
                                        labelStyle: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
