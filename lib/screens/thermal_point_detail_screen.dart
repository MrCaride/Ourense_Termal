import 'package:flutter/material.dart';
import '../models/thermal_point_model.dart';
import '../models/user_model.dart';
import '../services/user_data_service.dart';
import 'qr_scanner_screen.dart';

class ThermalPointDetailScreen extends StatefulWidget {
  final ThermalPoint point;
  final bool hasCheckedIn;
  final String userId;
  final User? user; // Agregado para pasar a QR Scanner

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
  final bool _isLoading = false;
  final UserDataService _userDataService = UserDataService();

  @override
  void initState() {
    super.initState();
    _checkedIn = widget.hasCheckedIn;
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
          thermalPoint: widget.point,
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
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Imagen header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.point.imageUrl,
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
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          // Contenido
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Chip(
                    label: Text(widget.point.getTypeLabel()),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.point.name,
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
                          widget.point.address,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Info rápida
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
                        '${widget.point.temperature}°C',
                        Colors.orange,
                      ),
                      if (widget.point.openingHours != null)
                        _buildInfoCard(
                          '🕐',
                          'Horario',
                          widget.point.openingHours!,
                          Colors.blue,
                        ),
                      if (widget.point.price != null)
                        _buildInfoCard(
                          '💰',
                          'Precio',
                          widget.point.price!,
                          Colors.green,
                        ),
                      _buildInfoCard(
                        '♿',
                        'Accesibilidad',
                        widget.point.accessibility,
                        Colors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Descripción
                  const Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.point.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Propiedades
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
                    children: widget.point.properties
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
                  // Seguridad
                  const Text(
                    'Consejos de Seguridad',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...widget.point.safety
                      .map(
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
                      )
                      ,
                  const SizedBox(height: 24),
                  // Botón check-in
                  if (!_checkedIn)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _handleCheckIn,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.cyan[500],
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
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
