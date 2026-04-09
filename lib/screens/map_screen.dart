import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user_model.dart';
import '../models/thermal_point_model.dart';
import 'thermal_point_detail_screen.dart';
import '../utils/app_theme.dart';

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
  String _selectedFilter = 'all';
  String _searchQuery = '';
  final MapController _mapController = MapController();
  
  // Centro del mapa en Ourense (fallback)
  final LatLng _ourenseCenter = LatLng(42.3376, -7.8653);
  LatLng? _userLocation;
  bool _isLoadingLocation = true;
  bool _distanceSortFailed = false;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  // Obtener ubicación del usuario
  Future<void> _getUserLocation() async {
    try {
      // Verificar si los servicios de ubicación están habilitados
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
        });
        _showLocationServiceDialog();
        return;
      }

      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingLocation = false;
          });
          _showPermissionDeniedSnackBar();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
        });
        _showPermissionDeniedForeverDialog();
        return;
      }

      // Obtener posición actual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      // Mover el mapa a la ubicación del usuario
      _mapController.move(_userLocation!, 14.0);
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      _showLocationErrorSnackBar();
    }
  }

  // Diálogo cuando los servicios de ubicación están deshabilitados
  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Servicios de ubicación deshabilitados'),
        content: const Text(
          'Por favor, habilita los servicios de ubicación para usar esta funcionalidad.',
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

  // Diálogo cuando los permisos están denegados permanentemente
  void _showPermissionDeniedForeverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permisos de ubicación denegados'),
        content: const Text(
          'Los permisos de ubicación están permanentemente denegados. '
          'Por favor, habilítalos desde la configuración de la aplicación.',
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

  // SnackBar cuando se deniegan permisos
  void _showPermissionDeniedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Permiso de ubicación denegado'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  // SnackBar cuando hay error obteniendo ubicación
  void _showLocationErrorSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error al obtener la ubicación'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filtrar puntos termales
    final filteredPoints = widget.thermalPoints.where((point) {
      final matchesFilter = _selectedFilter == 'all' || point.type == _selectedFilter;
      final matchesSearch = point.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          point.description.toLowerCase().contains(_searchQuery.toLowerCase());
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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header con gradiente
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Mapa Termal'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.brandTeal,
                      Color(0xFF0284C7),
                      Color(0xFF14B8A6),
                    ],
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 52),
                    child: Text(
                      'Explora fuentes, pozas y balnearios',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Contenido
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Buscador
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SearchBar(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    hintText: 'Buscar puntos termales...',
                    leading: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.search),
                    ),
                  ),
                ),
                // Filtros
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('all', 'Todos'),
                        const SizedBox(width: 8),
                        _buildFilterChip('fountain', 'Fuentes'),
                        const SizedBox(width: 8),
                        _buildFilterChip('pool', 'Pozas'),
                        const SizedBox(width: 8),
                        _buildFilterChip('spa', 'Balnearios'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_distanceSortFailed)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: const Text(
                        'No se pudo calcular la distancia. Se muestra la lista sin orden específico.',
                      ),
                    ),
                  ),
                if (_distanceSortFailed) const SizedBox(height: 12),
                // Mapa interactivo con flutter_map
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _userLocation ?? _ourenseCenter,
                            initialZoom: _userLocation != null ? 14.0 : 13.0,
                            minZoom: 10.0,
                            maxZoom: 18.0,
                          ),
                          children: [
                            // Capa de OpenStreetMap con proveedor optimizado
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.tfg.ourense_termal',
                              tileProvider: CancellableNetworkTileProvider(),
                            ),
                            // Marcador de ubicación del usuario
                            if (_userLocation != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: _userLocation!,
                                    width: 40,
                                    height: 40,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blue[600],
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            // Marcadores de puntos termales
                            MarkerLayer(
                              markers: filteredPoints.map((point) {
                                final hasCheckedIn = widget.checkIns.any((c) => c.pointId == point.id);
                                return Marker(
                                  point: LatLng(point.latitude, point.longitude),
                                  width: 50,
                                  height: 50,
                                  child: GestureDetector(
                                    onTap: () {
                                      _showPointBottomSheet(context, point, hasCheckedIn);
                                    },
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Sombra del marcador
                                        Icon(
                                          Icons.location_on,
                                          size: 50,
                                          color: Colors.black.withOpacity(0.3),
                                        ),
                                        // Marcador principal
                                        Icon(
                                          Icons.location_on,
                                          size: 45,
                                          color: _getMarkerColor(point.type, hasCheckedIn),
                                        ),
                                        // Icono del tipo
                                        Positioned(
                                          top: 8,
                                          child: Icon(
                                            _getTypeIcon(point.type),
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
                        // Indicador de carga
                        if (_isLoadingLocation)
                          Container(
                            color: Colors.black.withOpacity(0.3),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Título lista
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Puntos Termales (${filteredPoints.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          // Botón volver a mi ubicación
                          if (_userLocation != null)
                            IconButton(
                              icon: const Icon(Icons.my_location),
                              onPressed: () {
                                _mapController.move(_userLocation!, 14.0);
                              },
                              tooltip: 'Mi ubicación',
                            ),
                          // Botón centrar en Ourense
                          IconButton(
                            icon: const Icon(Icons.home_outlined),
                            onPressed: () {
                              _mapController.move(_ourenseCenter, 13.0);
                            },
                            tooltip: 'Centrar en Ourense',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          // Lista de puntos termales
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final point = filteredPoints[index];
                final hasCheckedIn = widget.checkIns.any((c) => c.pointId == point.id);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildThermalPointCard(
                    point,
                    hasCheckedIn,
                    _userLocation == null
                        ? null
                        : Geolocator.distanceBetween(
                            _userLocation!.latitude,
                            _userLocation!.longitude,
                            point.latitude,
                            point.longitude,
                          ),
                  ),
                );
              },
              childCount: filteredPoints.length,
            ),
          ),
          if (filteredPoints.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Center(
                  child: Text('No hay puntos disponibles'),
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
        ],
      ),
    );
  }

  // Obtener color del marcador según tipo y check-in
  Color _getMarkerColor(String type, bool hasCheckedIn) {
    if (hasCheckedIn) return Colors.green[600]!;
    
    switch (type) {
      case 'fountain':
        return Colors.cyan[600]!;
      case 'pool':
        return Colors.blue[600]!;
      case 'spa':
        return Colors.purple[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  // Obtener icono según tipo
  IconData _getTypeIcon(String type) {
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

  // Mostrar bottom sheet con info del punto
  void _showPointBottomSheet(BuildContext context, ThermalPoint point, bool hasCheckedIn) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Chip(
                    label: Text(point.getTypeLabel()),
                    backgroundColor: _getMarkerColor(point.type, hasCheckedIn).withOpacity(0.2),
                  ),
                  const SizedBox(width: 8),
                  if (hasCheckedIn)
                    const Chip(
                      label: Text('✓ Visitado'),
                      backgroundColor: Colors.green,
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                point.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                point.description,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.thermostat, size: 20, color: Colors.orange[600]),
                  const SizedBox(width: 4),
                  Text('${point.temperature}°C'),
                  const SizedBox(width: 16),
                  Icon(Icons.location_on, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      point.address,
                      style: TextStyle(color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
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
                    // Si se hizo check-in, refrescar datos
                    if (result == true && widget.onCheckIn != null) {
                      widget.onCheckIn!();
                    }
                  },
                  child: const Text('Ver detalles'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: isSelected ? Colors.cyan[500] : Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey[700],
      ),
    );
  }

  Widget _buildThermalPointCard(
    ThermalPoint point,
    bool hasCheckedIn,
    double? distanceInMeters,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () async {
          // Centrar mapa en el punto
          _mapController.move(LatLng(point.latitude, point.longitude), 15.0);
          
          final result = await Navigator.push(
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
          
          // Si se hizo check-in, refrescar datos
          if (result == true && widget.onCheckIn != null) {
            widget.onCheckIn!();
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            Stack(
              children: [
                Image.network(
                  point.imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 160,
                      color: Colors.grey[300],
                      child: const Center(child: Icon(Icons.broken_image)),
                    );
                  },
                ),
                if (hasCheckedIn)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '✓ Visitado',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
            // Contenido
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Chip(
                    label: Text(point.getTypeLabel()),
                    labelStyle: const TextStyle(fontSize: 11),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    point.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    point.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(
                        label: Text('🌡️ ${point.temperature}°C'),
                        labelStyle: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(width: 8),
                      if (distanceInMeters != null)
                        Chip(
                          label: Text('${(distanceInMeters / 1000).toStringAsFixed(1)} km'),
                          labelStyle: const TextStyle(fontSize: 11),
                        ),
                      if (distanceInMeters != null) const SizedBox(width: 8),
                      if (point.price != null)
                        Chip(
                          label: Text(point.price!),
                          labelStyle: const TextStyle(fontSize: 11),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
