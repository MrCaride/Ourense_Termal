import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../components/index.dart';
import '../models/thermal_point_model.dart';
import '../models/user_model.dart';
import '../theme/index.dart';
import 'thermal_point_detail_screen.dart';

class MapScreen extends StatefulWidget {
  final List<ThermalPoint> thermalPoints;
  final User user;
  final List<CheckIn> checkIns;
  final VoidCallback? onCheckIn;

  const MapScreen({
    super.key,
    required this.thermalPoints,
    required this.user,
    required this.checkIns,
    this.onCheckIn,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LatLng _ourenseCenter = LatLng(42.3376, -7.8653);

  String _selectedFilter = 'all';
  String _searchQuery = '';
  LatLng? _userLocation;
  bool _isLoadingLocation = true;
  bool _distanceSortFailed = false;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() => _isLoadingLocation = false);
        _showLocationServiceDialog();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!mounted) return;
          setState(() => _isLoadingLocation = false);
          _showPermissionDeniedSnackBar();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _isLoadingLocation = false);
        _showPermissionDeniedForeverDialog();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      _mapController.move(_userLocation!, 14.0);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingLocation = false);
      _showLocationErrorSnackBar();
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Servicios de ubicación deshabilitados'),
        content: const Text(
          'Activa la ubicación para ordenar los puntos por distancia y centrar el mapa en tu posición.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedForeverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permisos de ubicación denegados'),
        content: const Text(
          'Los permisos de ubicación están bloqueados. Actívalos desde la configuración de la app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: const Text('Configuración'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Permiso de ubicación denegado'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showLocationErrorSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error al obtener la ubicación'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  String _distanceLabel(double? distance) {
    if (distance == null) return 'Sin distancia';
    if (distance < 1000) return '${distance.round()} m';
    return '${(distance / 1000).toStringAsFixed(1)} km';
  }

  Color _typeColor(String type, bool hasCheckedIn) {
    if (hasCheckedIn) return AppColors.accentGreen;
    switch (type) {
      case 'fountain':
        return AppColors.thermalCool;
      case 'pool':
        return AppColors.accentBlue;
      case 'spa':
        return AppColors.accentPurple;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'fountain':
        return Icons.water_drop;
      case 'pool':
        return Icons.pool;
      case 'spa':
        return Icons.spa;
      default:
        return Icons.place;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'fountain':
        return 'Fuentes';
      case 'pool':
        return 'Pozas';
      case 'spa':
        return 'Balnearios';
      default:
        return 'Todos';
    }
  }

  void _openPointDetail(ThermalPoint point, bool hasCheckedIn) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ThermalPointDetailScreen(
          point: point,
          hasCheckedIn: hasCheckedIn,
          userId: widget.user.id,
          user: widget.user,
        ),
      ),
    );
  }

  void _showPointBottomSheet(
    BuildContext context,
    ThermalPoint point,
    bool hasCheckedIn,
    double? distance,
  ) {
    final pointColor = _typeColor(point.type, hasCheckedIn);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
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
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  pointColor.withValues(alpha: 0.18),
                                  pointColor.withValues(alpha: 0.06),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(_typeIcon(point.type), color: pointColor),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(point.name, style: AppTypography.titleLarge),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  point.address,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          _PillBadge(
                            icon: _typeIcon(point.type),
                            label: _typeLabel(point.type),
                            color: point.type == 'spa' ? AppColors.accentBlueDark : pointColor,
                          ),
                          _PillBadge(
                            icon: Icons.thermostat,
                            label: '${point.temperature.toStringAsFixed(0)}°C',
                            color: AppColors.thermalWarmDark,
                          ),
                          _PillBadge(
                            icon: Icons.social_distance,
                            label: _distanceLabel(distance),
                            color: AppColors.accentBlue,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (point.openingHours != null || point.price != null)
                        CustomCard(
                          backgroundColor: AppColors.surfaceAlt,
                          border: Border.all(color: AppColors.borderLight),
                          child: Column(
                            children: [
                              if (point.openingHours != null)
                                InfoTile(
                                  icon: Icons.schedule,
                                  title: 'Horario',
                                  subtitle: point.openingHours,
                                  iconColor: AppColors.accentBlue,
                                ),
                              if (point.openingHours != null && point.price != null)
                                const SizedBox(height: AppSpacing.sm),
                              if (point.price != null)
                                InfoTile(
                                  icon: Icons.payments_outlined,
                                  title: 'Precio',
                                  subtitle: point.price,
                                  iconColor: AppColors.thermalGold,
                                ),
                            ],
                          ),
                        ),
                      if (point.openingHours != null || point.price != null)
                        const SizedBox(height: AppSpacing.lg),
                      Text('Descripción', style: AppTypography.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        point.description,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Seguridad', style: AppTypography.titleMedium),
                      const SizedBox(height: AppSpacing.sm),
                      CustomCard(
                        backgroundColor: AppColors.surfaceAlt,
                        border: Border.all(color: AppColors.borderLight),
                        child: Column(
                          children: [
                            InfoTile(
                              icon: Icons.accessibility_new,
                              title: 'Accesibilidad',
                              subtitle: point.accessibility,
                              iconColor: AppColors.accentGreen,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ...point.safety.take(2).map(
                                  (safety) => Padding(
                                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.warning_amber_rounded,
                                          size: 18,
                                          color: AppColors.thermalGold,
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: Text(
                                            safety,
                                            style: AppTypography.bodySmall.copyWith(
                                              color: AppColors.textSecondary,
                                              height: 1.45,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CustomButton(
                        label: 'Ver detalle completo',
                        icon: Icons.open_in_new,
                        onPressed: () {
                          Navigator.pop(context);
                          _openPointDetail(point, hasCheckedIn);
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      CustomButton(
                        label: hasCheckedIn ? 'Ya registrado' : 'Cerrar',
                        variant: ButtonVariant.outline,
                        backgroundColor: pointColor,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;

    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedFilter = value;
        });
      },
      label: Text(label),
      avatar: Icon(
        value == 'all' ? Icons.grid_view_rounded : _typeIcon(value),
        size: 18,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
      labelStyle: AppTypography.labelMedium.copyWith(
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      selectedColor: AppColors.thermalCool,
      backgroundColor: AppColors.surfaceAlt,
      side: BorderSide(color: isSelected ? AppColors.thermalCool : AppColors.borderLight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }

  Widget _buildThermalPointCard(
    ThermalPoint point,
    bool hasCheckedIn,
    double? distance,
  ) {
    final pointColor = _typeColor(point.type, hasCheckedIn);

    return CustomCard(
      onTap: () => _showPointBottomSheet(context, point, hasCheckedIn, distance),
      isClickable: true,
      backgroundColor: AppColors.background,
      border: Border.all(
        color: hasCheckedIn ? AppColors.accentGreen.withValues(alpha: 0.45) : AppColors.borderLight,
      ),
      shadows: AppShadows.elevation1,
      padding: EdgeInsets.zero,
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Stack(
              children: [
                Image.network(
                  point.imageUrl,
                  height: 170,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 170,
                      width: double.infinity,
                      color: AppColors.surface,
                      child: const Icon(Icons.broken_image_outlined, size: 40),
                    );
                  },
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.56),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Row(
                    children: [
                      _PillBadge(
                        icon: _typeIcon(point.type),
                        label: point.getTypeLabel(),
                        color: point.type == 'spa' ? AppColors.accentBlueDark : pointColor,
                        compact: true,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _PillBadge(
                        icon: Icons.thermostat,
                        label: '${point.temperature.toStringAsFixed(0)}°C',
                        color: AppColors.thermalWarmDark,
                        compact: true,
                      ),
                    ],
                  ),
                ),
                if (hasCheckedIn)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _PillBadge(
                      icon: Icons.verified,
                      label: 'Visitado',
                      color: AppColors.accentGreen,
                      compact: true,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(point.name, style: AppTypography.titleMedium),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _distanceLabel(distance),
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        point.address,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  point.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        label: 'Ver detalle',
                        icon: Icons.arrow_forward_rounded,
                        size: ButtonSize.medium,
                        onPressed: () => _openPointDetail(point, hasCheckedIn),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _MapActionButton(
                      icon: Icons.near_me,
                      onTap: _userLocation == null
                          ? null
                          : () => _mapController.move(
                                LatLng(point.latitude, point.longitude),
                                15.5,
                              ),
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

  @override
  Widget build(BuildContext context) {
    final filteredPoints = widget.thermalPoints.where((point) {
      final matchesFilter = _selectedFilter == 'all' || point.type == _selectedFilter;
      final query = _searchQuery.toLowerCase();
      final matchesSearch = point.name.toLowerCase().contains(query) ||
          point.description.toLowerCase().contains(query) ||
          point.address.toLowerCase().contains(query);
      return matchesFilter && matchesSearch;
    }).toList();

    if (_userLocation != null) {
      try {
        filteredPoints.sort((a, b) {
          final distanceA = Geolocator.distanceBetween(
            _userLocation!.latitude,
            _userLocation!.longitude,
            a.latitude,
            a.longitude,
          );
          final distanceB = Geolocator.distanceBetween(
            _userLocation!.latitude,
            _userLocation!.longitude,
            b.latitude,
            b.longitude,
          );
          return distanceA.compareTo(distanceB);
        });
        _distanceSortFailed = false;
      } catch (_) {
        _distanceSortFailed = true;
      }
    }

    final visitedCount = widget.checkIns.length;
    final nearbyCount = _userLocation == null
        ? 0
        : filteredPoints.where((point) {
            final distance = Geolocator.distanceBetween(
              _userLocation!.latitude,
              _userLocation!.longitude,
              point.latitude,
              point.longitude,
            );
            return distance <= 5000;
          }).length;

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      appBar: AppBar(
        title: const Text('Mapa termal'),
        centerTitle: true,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _getUserLocation,
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
                    AppColors.thermalCoolDark,
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
                          child: const Icon(Icons.map_outlined, color: Colors.white),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'Explora fuentes, pozas y balnearios con una vista más clara y útil.',
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
                            icon: Icons.water,
                            value: '${filteredPoints.length}',
                            label: 'Puntos visibles',
                            color: AppColors.thermalCool,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: StatTile(
                            icon: Icons.near_me,
                            value: '$nearbyCount',
                            label: 'Cercanos',
                            color: AppColors.accentBlue,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: StatTile(
                            icon: Icons.verified,
                            value: '$visitedCount',
                            label: 'Visitados',
                            color: AppColors.accentGreen,
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
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Buscar puntos, calles o descripciones',
                    prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                    border: InputBorder.none,
                  ).copyWith(
                    hintStyle: const TextStyle(color: AppColors.textDisabled),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.lg,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'Todos'),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('fountain', 'Fuentes'),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('pool', 'Pozas'),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('spa', 'Balnearios'),
                  ],
                ),
              ),
            ),
            if (_distanceSortFailed) ...[
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CustomCard(
                  backgroundColor: AppColors.thermalGoldLight.withValues(alpha: 0.12),
                  border: Border.all(color: AppColors.thermalGold.withValues(alpha: 0.25)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.thermalGold),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'No se pudo calcular la distancia. La lista se muestra sin ordenar por proximidad.',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CustomCard(
                padding: EdgeInsets.zero,
                borderRadius: 28,
                backgroundColor: AppColors.background,
                shadows: AppShadows.elevation3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 330,
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _userLocation ?? _ourenseCenter,
                            initialZoom: _userLocation != null ? 14.0 : 13.0,
                            minZoom: 10.0,
                            maxZoom: 18.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.tfg.ourense_termal',
                              tileProvider: CancellableNetworkTileProvider(),
                            ),
                            if (_userLocation != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _userLocation!,
                                    width: 44,
                                    height: 44,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.accentBlue,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 3),
                                        boxShadow: AppShadows.elevation2,
                                      ),
                                      child: const Icon(Icons.person, color: Colors.white, size: 20),
                                    ),
                                  ),
                                ],
                              ),
                            MarkerLayer(
                              markers: filteredPoints.map((point) {
                                final hasCheckedIn = widget.checkIns.any((c) => c.pointId == point.id);
                                return Marker(
                                  point: LatLng(point.latitude, point.longitude),
                                  width: 54,
                                  height: 54,
                                  child: GestureDetector(
                                    onTap: () {
                                      final distance = _userLocation == null
                                          ? null
                                          : Geolocator.distanceBetween(
                                              _userLocation!.latitude,
                                              _userLocation!.longitude,
                                              point.latitude,
                                              point.longitude,
                                            );
                                      _showPointBottomSheet(context, point, hasCheckedIn, distance);
                                    },
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Icon(
                                          Icons.location_on,
                                          size: 52,
                                          color: Colors.black.withValues(alpha: 0.16),
                                        ),
                                        Icon(
                                          Icons.location_on,
                                          size: 46,
                                          color: _typeColor(point.type, hasCheckedIn),
                                        ),
                                        Positioned(
                                          top: 9,
                                          child: Icon(
                                            _typeIcon(point.type),
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 16,
                        top: 16,
                        child: Column(
                          children: [
                            _MapActionButton(
                              icon: Icons.my_location,
                              onTap: _userLocation == null
                                  ? null
                                  : () => _mapController.move(_userLocation!, 14.0),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _MapActionButton(
                              icon: Icons.home_outlined,
                              onTap: () => _mapController.move(_ourenseCenter, 13.0),
                            ),
                          ],
                        ),
                      ),
                      if (_isLoadingLocation)
                        Positioned.fill(
                          child: Container(
                            color: Colors.white.withValues(alpha: 0.55),
                            child: const Center(child: LoadingSpinner()),
                          ),
                        ),
                      Positioned(
                        left: 16,
                        bottom: 16,
                        child: CustomCard(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          backgroundColor: Colors.white.withValues(alpha: 0.9),
                          borderRadius: 18,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.accentGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                _userLocation == null ? 'Centro en Ourense' : 'Tu ubicación activa',
                                style: AppTypography.labelMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Puntos termales (${filteredPoints.length})', style: AppTypography.titleLarge),
                  Row(
                    children: [
                      if (_userLocation != null)
                        _MapActionButton(
                          icon: Icons.my_location,
                          onTap: () => _mapController.move(_userLocation!, 14.0),
                        ),
                      const SizedBox(width: AppSpacing.sm),
                      _MapActionButton(
                        icon: Icons.home_outlined,
                        onTap: () => _mapController.move(_ourenseCenter, 13.0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (filteredPoints.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: EmptyState(
                  icon: Icons.map_outlined,
                  title: 'No hay puntos disponibles',
                  description: 'Prueba con otro filtro o cambia la búsqueda para descubrir más puntos termales.',
                  action: CustomButton(
                    label: 'Limpiar filtros',
                    icon: Icons.restart_alt,
                    onPressed: () {
                      setState(() {
                        _selectedFilter = 'all';
                        _searchQuery = '';
                      });
                    },
                  ),
                ),
              )
            else
              ...filteredPoints.asMap().entries.map((entry) {
                final index = entry.key;
                final point = entry.value;
                final hasCheckedIn = widget.checkIns.any((c) => c.pointId == point.id);
                final distance = _userLocation == null
                    ? null
                    : Geolocator.distanceBetween(
                        _userLocation!.latitude,
                        _userLocation!.longitude,
                        point.latitude,
                        point.longitude,
                      );

                return AnimatedListItem(
                  index: index,
                  delay: Duration(milliseconds: index * 70),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _buildThermalPointCard(point, hasCheckedIn, distance),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _MapActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _MapActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: AppShadows.elevation2,
          ),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool compact;

  const _PillBadge({
    required this.icon,
    required this.label,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 7 : 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 14 : 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
