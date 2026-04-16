import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../data/thermal_points_data.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_data_service.dart';
import '../screens/login_screen.dart';
import '../utils/app_theme.dart';

class ThermalManagerScreen extends StatefulWidget {
  final User user;

  const ThermalManagerScreen({super.key, required this.user});

  @override
  State<ThermalManagerScreen> createState() => _ThermalManagerScreenState();
}

class _ThermalManagerScreenState extends State<ThermalManagerScreen> {
  final UserDataService _userDataService = UserDataService();
  int _selectedIndex = 0;
  final List<String> _managerImages = [];
  final TextEditingController _imageUrlController = TextEditingController();
  String? _assignedThermalPointId;
  String? _pendingRequestedThermalPointId;
  String? _selectedRequestedThermalPointId;
  bool _isLoadingStatus = true;
  bool _isSubmittingRequest = false;

  @override
  void initState() {
    super.initState();
    _assignedThermalPointId = widget.user.thermalPointId;
    _loadManagerStatus();
  }

  @override
  void dispose() {
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadManagerStatus() async {
    setState(() {
      _isLoadingStatus = true;
    });

    try {
      final currentUser = await AuthService().getCurrentUser();
      final pendingRequestedPoint = await _userDataService
          .getManagerPendingThermalPointRequest(widget.user.id);

      if (!mounted) return;

      final assignedPoint = currentUser?.thermalPointId ?? _assignedThermalPointId;

      setState(() {
        _assignedThermalPointId = assignedPoint;
        _pendingRequestedThermalPointId = pendingRequestedPoint;
        _selectedRequestedThermalPointId ??=
            pendingRequestedPoint ?? ThermalPointsData.getThermalPoints().first.id;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _selectedRequestedThermalPointId ??=
            ThermalPointsData.getThermalPoints().first.id;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStatus = false;
        });
      }
    }
  }

  Future<void> _submitThermalPointRequest() async {
    final selectedPointId = _selectedRequestedThermalPointId;
    if (selectedPointId == null) return;

    setState(() {
      _isSubmittingRequest = true;
    });

    try {
      await _userDataService.submitThermalPointRequest(
        managerId: widget.user.id,
        managerName: widget.user.name,
        thermalPointId: selectedPointId,
      );

      if (!mounted) return;
      setState(() {
        _pendingRequestedThermalPointId = selectedPointId;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud enviada al administrador'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar la solicitud: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingRequest = false;
        });
      }
    }
  }

  String _getThermalPointName(String? pointId) {
    if (pointId == null) return 'Sin selección';
    final thermalPoints = ThermalPointsData.getThermalPoints();
    for (final point in thermalPoints) {
      if (point.id == pointId) {
        return point.name;
      }
    }
    return pointId;
  }

  void _generateQRCheckIn() {
    // Datos para el QR: ID del punto termal y timestamp
    final pointId = _assignedThermalPointId;
    if (pointId == null) {
      return;
    }

    final qrData = '$pointId-${DateTime.now().millisecondsSinceEpoch}';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR de Check-In'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 300,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              'Escanea este código para check-in',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _addImage() {
    if (_imageUrlController.text.isNotEmpty) {
      setState(() {
        _managerImages.add(_imageUrlController.text);
        _imageUrlController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagen añadida')),
      );
    }
  }

  void _deleteImage(int index) {
    setState(() {
      _managerImages.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Imagen eliminada')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Panel de Gerente'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualizar estado',
              onPressed: _loadManagerStatus,
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Cerrar sesión'),
                    content: const Text('¿Deseas cerrar tu sesión?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await AuthService().logout();
                          if (!context.mounted) return;
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        child: const Text('Cerrar sesión'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: _isLoadingStatus
            ? const Center(child: CircularProgressIndicator())
            : _assignedThermalPointId == null
                ? _buildAccessRequestSection()
                : (_selectedIndex == 0 ? _buildQRSection() : _buildImageSection()),
        bottomNavigationBar: _assignedThermalPointId == null
            ? null
            : BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.qr_code),
                    label: 'QR Check-in',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.image),
                    label: 'Galería',
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAccessRequestSection() {
    final thermalPoints = ThermalPointsData.getThermalPoints();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Acceso pendiente de asignación',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Necesitas un punto termal asociado para usar los servicios de gerente. Selecciona uno y envía la solicitud al administrador.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Selecciona el punto termal que quieres gestionar',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedRequestedThermalPointId,
            items: thermalPoints
                .map(
                  (point) => DropdownMenuItem<String>(
                    value: point.id,
                    child: Text(point.name),
                  ),
                )
                .toList(),
            onChanged: _isSubmittingRequest
                ? null
                : (value) {
                    setState(() {
                      _selectedRequestedThermalPointId = value;
                    });
                  },
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Punto termal',
            ),
          ),
          const SizedBox(height: 16),
          if (_pendingRequestedThermalPointId != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
              ),
              child: Text(
                'Solicitud pendiente: ${_getThermalPointName(_pendingRequestedThermalPointId)}',
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSubmittingRequest ? null : _submitThermalPointRequest,
              icon: _isSubmittingRequest
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(
                _pendingRequestedThermalPointId == null
                    ? 'Enviar solicitud'
                    : 'Actualizar solicitud',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAssignedPointBanner(),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.light.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.qr_code_2,
                  size: 48,
                  color: AppTheme.light.primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Generador de QR para Check-in',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Genera un código QR que los usuarios pueden escanear para hacer check-in en tu punto termal',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _generateQRCheckIn,
            icon: const Icon(Icons.qr_code),
            label: const Text('Generar QR'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: AppTheme.light.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAssignedPointBanner(),
          const SizedBox(height: 16),
          Text(
            'Galería de tu Punto Termal',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _imageUrlController,
            decoration: InputDecoration(
              hintText: 'URL de la imagen',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addImage,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (_managerImages.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.image_not_supported,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No hay imágenes aún',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _managerImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(_managerImages[index]),
                          fit: BoxFit.cover,
                          onError: (exception, stackTrace) {
                            // Imagen no disponible
                          },
                        ),
                        color: Colors.grey[200],
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _deleteImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAssignedPointBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tu punto termal: ${_getThermalPointName(_assignedThermalPointId)}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
