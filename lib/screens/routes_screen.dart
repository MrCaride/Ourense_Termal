import 'package:flutter/material.dart';

import '../components/index.dart';
import '../data/thermal_points_data.dart';
import '../models/route_model.dart' as route_model;
import '../models/user_model.dart';
import '../models/user_route_progress_model.dart';
import '../services/route_service.dart';
import '../theme/index.dart';

class RoutesScreen extends StatefulWidget {
  final User user;
  final VoidCallback? onCheckIn;

  const RoutesScreen({super.key, required this.user, this.onCheckIn});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  final RouteService _routeService = RouteService();

  List<route_model.Route> _routes = [];
  Map<String, UserRouteProgress> _progressMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant RoutesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    _routes = RouteService.getAvailableRoutes();
    _progressMap = await _routeService.getUserRouteProgress(widget.user.id);

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return AppColors.accentGreen;
      case 'moderate':
        return AppColors.thermalGold;
      case 'hard':
        return AppColors.accentRed;
      default:
        return AppColors.thermalCool;
    }
  }

  List<Color> _routeAccent(String difficulty) {
    switch (difficulty) {
      case 'easy':
        return const [AppColors.accentGreenDark, AppColors.accentGreenLight];
      case 'moderate':
        return const [AppColors.thermalGoldDark, AppColors.thermalGoldLight];
      case 'hard':
        return const [AppColors.accentRedDark, AppColors.accentRedLight];
      default:
        return const [AppColors.thermalCoolDark, AppColors.accentBlueLight];
    }
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _progressMap.values.where((p) => p.isCompleted).length;
    final completionRatio = _routes.isEmpty ? 0.0 : completedCount / _routes.length;
    final totalPoints = _routes.fold<int>(0, (sum, route) => sum + route.points);

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Rutas y retos'),
        centerTitle: true,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _isLoading
          ? const Center(child: LoadingSpinner())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: CustomCard(
                      borderRadius: 28,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.thermalWarmDark,
                          AppColors.thermalGoldDark,
                          AppColors.accentBlueDark,
                        ],
                      ),
                      shadows: AppShadows.elevation3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.route_rounded, color: Colors.white),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  'Explora recorridos curados, gana puntos y sigue tu avance en una sola vista.',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            children: [
                              Expanded(
                                child: StatTile(
                                  icon: Icons.flag_rounded,
                                  value: '$completedCount',
                                  label: 'Completadas',
                                  color: AppColors.background,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: StatTile(
                                  icon: Icons.stars_rounded,
                                  value: '${widget.user.points}',
                                  label: 'Puntos',
                                  color: AppColors.background,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: StatTile(
                                  icon: Icons.route_rounded,
                                  value: '${_routes.length}',
                                  label: 'Rutas',
                                  color: AppColors.background,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: CustomCard(
                      backgroundColor: AppColors.background,
                      border: Border.all(color: AppColors.borderLight),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Tu progreso de exploracion', style: AppTypography.titleMedium),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    '$completedCount de ${_routes.length} rutas completadas',
                                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              Text(
                                '${(completionRatio * 100).toStringAsFixed(0)}%',
                                style: AppTypography.labelLarge.copyWith(color: AppColors.thermalCool),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          CustomProgressBar(
                            progress: completionRatio,
                            foregroundColor: AppColors.thermalCool,
                            backgroundColor: AppColors.surface,
                            height: 12,
                            showPercentage: false,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Ganas $totalPoints puntos en total al completar todas las rutas.',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Rutas disponibles', style: AppTypography.titleLarge),
                        Text(
                          '${_routes.length} itinerarios',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (_routes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: EmptyState(
                        icon: Icons.route_rounded,
                        title: 'No hay rutas disponibles',
                        description:
                            'Cuando se publiquen nuevas rutas, apareceran aqui con su progreso y puntos.',
                      ),
                    )
                  else
                    ..._routes.asMap().entries.map((entry) {
                      final index = entry.key;
                      final route = entry.value;
                      final progress = _progressMap[route.id];

                      return AnimatedListItem(
                        index: index,
                        delay: Duration(milliseconds: index * 80),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: _buildRouteCard(context, route, progress),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  Widget _buildRouteCard(
    BuildContext context,
    route_model.Route route,
    UserRouteProgress? progress,
  ) {
    final difficultyColor = _difficultyColor(route.difficulty);
    final isCompleted = progress?.isCompleted ?? false;
    final routeProgress = progress?.progress ?? 0.0;
    final completedPoints = progress?.completedPointIds.length ?? 0;

    return CustomCard(
      onTap: () => _showRouteDetails(context, route),
      isClickable: true,
      padding: EdgeInsets.zero,
      borderRadius: 26,
      backgroundColor: AppColors.background,
      border: Border.all(
        color: isCompleted ? AppColors.accentGreen.withValues(alpha: 0.35) : AppColors.borderLight,
      ),
      shadows: AppShadows.elevation1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 10,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
              gradient: LinearGradient(colors: _routeAccent(route.difficulty)),
            ),
          ),
          if (isCompleted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: AppColors.accentGreen,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Ruta completada',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _RouteTag(
                      icon: Icons.filter_alt_outlined,
                      label: route.theme,
                      color: AppColors.thermalCool,
                    ),
                    _RouteTag(
                      icon: Icons.bolt_rounded,
                      label: route.getDifficultyLabel(),
                      color: difficultyColor,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(route.name, style: AppTypography.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  route.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _RouteInfoPill(icon: Icons.location_on_outlined, label: '${route.distance} km'),
                    _RouteInfoPill(icon: Icons.timer_outlined, label: route.duration),
                    _RouteInfoPill(
                      icon: Icons.pin_drop_outlined,
                      label: '${route.thermalPointIds.length} puntos',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progreso: $completedPoints/${route.thermalPointIds.length}',
                      style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
                    ),
                    Text(
                      '${routeProgress.toStringAsFixed(0)}%',
                      style: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                CustomProgressBar(
                  progress: routeProgress / 100,
                  foregroundColor: isCompleted ? AppColors.accentGreen : AppColors.thermalCool,
                  backgroundColor: AppColors.surface,
                  height: 10,
                  showPercentage: false,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.thermalGold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.thermalGold, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '+${route.points} puntos',
                            style: AppTypography.labelMedium.copyWith(color: AppColors.thermalGoldDark),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (!isCompleted)
                      CustomButton(
                        label: 'Ver mas',
                        icon: Icons.arrow_forward_rounded,
                        size: ButtonSize.medium,
                        width: 120,
                        onPressed: () => _showRouteDetails(context, route),
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

  void _showRouteDetails(BuildContext context, route_model.Route route) {
    final thermalPoints = ThermalPointsData.getThermalPoints();
    final routePoints = thermalPoints.where((p) => route.thermalPointIds.contains(p.id)).toList();
    final progress = _progressMap[route.id];
    final completedPointIds = progress?.completedPointIds ?? <String>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 52,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.borderLight,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(route.name, style: AppTypography.titleLarge),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              route.description,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.4,
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
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          icon: Icons.location_on_outlined,
                          value: '${route.distance} km',
                          label: 'Distancia',
                          color: AppColors.accentBlue,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: StatTile(
                          icon: Icons.timer_outlined,
                          value: route.duration,
                          label: 'Duracion',
                          color: AppColors.thermalWarm,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: StatTile(
                          icon: Icons.star_rounded,
                          value: '+${route.points}',
                          label: 'Puntos',
                          color: AppColors.thermalGold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  CustomCard(
                    backgroundColor: AppColors.surfaceAlt,
                    border: Border.all(color: AppColors.borderLight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Puntos de la ruta', style: AppTypography.titleSmall),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${completedPointIds.length}/${route.thermalPointIds.length} visitados',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CustomProgressBar(
                          progress: route.thermalPointIds.isEmpty
                              ? 0
                              : completedPointIds.length / route.thermalPointIds.length,
                          foregroundColor: AppColors.thermalCool,
                          backgroundColor: AppColors.surface,
                          height: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Puntos incluidos', style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  if (routePoints.isEmpty)
                    EmptyState(
                      icon: Icons.location_off_outlined,
                      title: 'No se encontraron puntos para esta ruta',
                      description:
                          'Puede que la ruta este en preparacion o que el catalogo de puntos haya cambiado.',
                    )
                  else
                    ListView.separated(
                      controller: scrollController,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: routePoints.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final point = routePoints[index];
                        final isCompleted = completedPointIds.contains(point.id);
                        return InfoTile(
                          icon: isCompleted ? Icons.check_circle : Icons.location_on_outlined,
                          title: point.name,
                          subtitle: point.address,
                          iconColor: isCompleted ? AppColors.accentGreen : AppColors.thermalCool,
                          trailing: _RoutePointChip(
                            label: isCompleted ? 'Visitado' : 'Pendiente',
                            color: isCompleted ? AppColors.accentGreen : AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _RouteTag({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.labelSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _RouteInfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RouteInfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.labelMedium),
        ],
      ),
    );
  }
}

class _RoutePointChip extends StatelessWidget {
  final String label;
  final Color color;

  const _RoutePointChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(color: color),
      ),
    );
  }
}
