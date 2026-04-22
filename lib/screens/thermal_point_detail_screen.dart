import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/thermal_point_model.dart';
import '../models/user_model.dart';
import 'qr_scanner_screen.dart';

class ThermalPointDetailScreen extends StatefulWidget {
  final ThermalPoint point;
  final bool hasCheckedIn;
  final String userId;
  final User? user;

  const ThermalPointDetailScreen({
    super.key,
    required this.point,
    required this.hasCheckedIn,
    required this.userId,
    this.user,
  });

  @override
  State<ThermalPointDetailScreen> createState() => _ThermalPointDetailScreenState();
}

class _ThermalPointDetailScreenState extends State<ThermalPointDetailScreen> {
  late bool _checkedIn;
  bool _isLoadingPoint = true;
  late ThermalPoint _currentPoint;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkedIn = widget.hasCheckedIn;
    _currentPoint = widget.point;
    _loadLatestPoint();
  }

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }

  ThermalPoint _thermalPointFromData(String id, Map<String, dynamic> data) {
    return ThermalPoint(
      id: id,
      name: data['name'] as String? ?? 'Punto termal',
      description: data['description'] as String? ?? '',
      type: data['type'] as String? ?? 'pool',
      temperature: (data['temperature'] as num?)?.toDouble() ?? 37.0,
      address: data['address'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['imageUrl'] as String? ?? '',
      price: data['price'] as String?,
      openingHours: data['openingHours'] as String?,
      accessibility: data['accessibility'] as String? ?? 'estandar',
      properties: _asStringList(data['properties']),
      safety: _asStringList(data['safety']),
    );
  }

  Future<void> _loadLatestPoint() async {
    try {
      final doc = await _firestore.collection('thermal_points').doc(widget.point.id).get();
      if (!mounted) return;

      if (doc.exists && doc.data() != null) {
        setState(() {
          _currentPoint = _thermalPointFromData(doc.id, doc.data()!);
          _isLoadingPoint = false;
        });
        return;
      }
    } catch (_) {
      // Si falla Firestore, se mantiene el punto recibido por navegación.
    }

    if (!mounted) return;
    setState(() {
      _isLoadingPoint = false;
    });
  }

  Future<void> _handleCheckIn() async {
    if (_checkedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya has hecho check-in en este punto')),
      );
      return;
    }

    if (widget.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo identificar el usuario')),
      );
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          user: widget.user!,
          thermalPoint: _currentPoint,
        ),
      ),
    );

    if (result == true) {
      setState(() {
        _checkedIn = true;
      });

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in realizado correctamente')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPoint) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              color: Colors.white,
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _currentPoint.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.broken_image)),
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Chip(
                    label: Text(_currentPoint.getTypeLabel()),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentPoint.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _currentPoint.address,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      _buildInfoCard(
                        '🌡️',
                        'Temperatura',
                        '${_currentPoint.temperature}°C',
                        Colors.orange,
                      ),
                      if (_currentPoint.openingHours != null)
                        _buildInfoCard(
                          '🕐',
                          'Horario',
                          _currentPoint.openingHours!,
                          Colors.blue,
                        ),
                      if (_currentPoint.price != null)
                        _buildInfoCard(
                          '💰',
                          'Precio',
                          _currentPoint.price!,
                          Colors.green,
                        ),
                      _buildInfoCard(
                        '♿',
                        'Accesibilidad',
                        _currentPoint.accessibility,
                        Colors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentPoint.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Propiedades del Agua',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _currentPoint.properties
                        .map(
                          (prop) => Chip(
                            label: Text(prop),
                            backgroundColor: Colors.cyan[100],
                            labelStyle: TextStyle(color: Colors.cyan[700]),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Consejos de Seguridad',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._currentPoint.safety.map(
                    (safety) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('⚠️', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              safety,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!_checkedIn)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _handleCheckIn,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.cyan[500],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_2),
                            SizedBox(width: 8),
                            Text('Hacer Check-in (+50 puntos)'),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        border: Border.all(color: Colors.green[500]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[500], size: 48),
                          const SizedBox(height: 8),
                          Text(
                            '¡Check-in Realizado!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ya has visitado este punto termal hoy',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    String icon,
    String label,
    String value,
    Color color,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
