import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/thermal_point_model.dart';
import 'thermal_point_detail_screen.dart';

class MapScreen extends StatefulWidget {
  final List<ThermalPoint> thermalPoints;
  final User user;
  final List<CheckIn> checkIns;

  const MapScreen({
    Key? key,
    required this.thermalPoints,
    required this.user,
    required this.checkIns,
  }) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String _selectedFilter = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // Filtrar puntos termales
    final filteredPoints = widget.thermalPoints.where((point) {
      final matchesFilter = _selectedFilter == 'all' || point.type == _selectedFilter;
      final matchesSearch = point.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          point.description.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header con gradiente
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Mapa Termal'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.cyan[500]!, Colors.blue[500]!],
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
                // Mapa placeholder
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.cyan[100]!, Colors.blue[100]!],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map, size: 48, color: Colors.cyan[500]),
                        const SizedBox(height: 8),
                        const Text('Mapa interactivo'),
                        const Text('Ourense, Galicia', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Título lista
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Puntos Termales (${filteredPoints.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
                  child: _buildThermalPointCard(point, hasCheckedIn),
                );
              },
              childCount: filteredPoints.length,
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
        ],
      ),
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

  Widget _buildThermalPointCard(ThermalPoint point, bool hasCheckedIn) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ThermalPointDetailScreen(
                point: point,
                hasCheckedIn: hasCheckedIn,
              ),
            ),
          );
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
