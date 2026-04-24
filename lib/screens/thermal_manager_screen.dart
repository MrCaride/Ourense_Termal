import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import '../data/thermal_points_data.dart';
import '../models/thermal_point_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/qr_service.dart';
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
  final QRService _qrService = QRService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _selectedIndex = 0;
  final List<String> _managerImages = [];
  final TextEditingController _imageUrlController = TextEditingController();
  String? _assignedThermalPointId;
  String? _pendingRequestedThermalPointId;
  String? _selectedRequestedThermalPointId;
  bool _isLoadingStatus = true;
  bool _isSubmittingRequest = false;

  CollectionReference<Map<String, dynamic>> get _thermalPointsCollection {
    return _firestore.collection('thermal_points');
  }

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

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }

  Map<String, dynamic> _thermalPointToMap(ThermalPoint point) {
    return {
      'name': point.name,
      'description': point.description,
      'type': point.type,
      'temperature': point.temperature,
      'address': point.address,
      'latitude': point.latitude,
      'longitude': point.longitude,
      'imageUrl': point.imageUrl,
      'price': point.price,
      'openingHours': point.openingHours,
      'accessibility': point.accessibility,
      'properties': point.properties,
      'safety': point.safety,
      'updatedAt': DateTime.now(),
    };
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

  Future<ThermalPoint?> _getAssignedThermalPoint() async {
    final pointId = _assignedThermalPointId;
    if (pointId == null) return null;

    final doc = await _thermalPointsCollection.doc(pointId).get();
    if (doc.exists && doc.data() != null) {
      return _thermalPointFromData(doc.id, doc.data()!);
    }

    final fallback = ThermalPointsData.getThermalPoints().where((p) => p.id == pointId);
    if (fallback.isNotEmpty) {
      return fallback.first;
    }
    return null;
  }

  Future<void> _showEditAssignedThermalPointDialog() async {
    final pointId = _assignedThermalPointId;
    if (pointId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes un punto termal asignado')),
      );
      return;
    }

    try {
      final point = await _getAssignedThermalPoint();
      if (!mounted) return;

      if (point == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró tu punto termal para editar')),
        );
        return;
      }

      await _showThermalPointFormDialog(point: point);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar el punto termal: $e')),
      );
    }
  }

  Future<void> _showThermalPointFormDialog({required ThermalPoint point}) async {
    final nameController = TextEditingController(text: point.name);
    final descriptionController = TextEditingController(text: point.description);
    final addressController = TextEditingController(text: point.address);
    final imageUrlController = TextEditingController(text: point.imageUrl);
    final temperatureController = TextEditingController(
      text: point.temperature.toString(),
    );
    double selectedLatitude = point.latitude;
    double selectedLongitude = point.longitude;
    final openingHoursController = TextEditingController(text: point.openingHours ?? '');
    final priceController = TextEditingController(text: point.price ?? '');
    final propertiesController = TextEditingController(
      text: point.properties.join(', '),
    );
    final safetyController = TextEditingController(
      text: point.safety.join(', '),
    );

    String selectedType = point.type;

    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: StatefulBuilder(
              builder: (context, setDialogState) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Editar Punto Termal',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Descripción'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    items: const [
                      DropdownMenuItem(value: 'pool', child: Text('Poza Termal')),
                      DropdownMenuItem(value: 'fountain', child: Text('Fuente Termal')),
                      DropdownMenuItem(value: 'spa', child: Text('Balneario / Spa')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() {
                        selectedType = value;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Tipo'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Dirección'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: imageUrlController,
                    decoration: const InputDecoration(labelText: 'URL de imagen'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: temperatureController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Temperatura'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: priceController,
                          decoration: const InputDecoration(labelText: 'Precio (opcional)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ubicación seleccionada',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('Lat: ${selectedLatitude.toStringAsFixed(6)} · Lng: ${selectedLongitude.toStringAsFixed(6)}'),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final selected = await _pickLocationOnMap(
                                initialLatitude: selectedLatitude,
                                initialLongitude: selectedLongitude,
                              );

                              if (selected == null) return;

                              setDialogState(() {
                                selectedLatitude = selected.latitude;
                                selectedLongitude = selected.longitude;
                              });
                            },
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('Relocalizar en mapa'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: openingHoursController,
                    decoration: const InputDecoration(labelText: 'Horario (opcional)'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: propertiesController,
                    decoration: const InputDecoration(labelText: 'Propiedades (separadas por coma)'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: safetyController,
                    decoration: const InputDecoration(labelText: 'Consejos de seguridad (coma)'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final description = descriptionController.text.trim();
                          final address = addressController.text.trim();
                          final imageUrl = imageUrlController.text.trim();
                          final temp = double.tryParse(temperatureController.text.trim());

                          if (name.isEmpty || description.isEmpty || address.isEmpty || imageUrl.isEmpty ||
                              temp == null) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(content: Text('Completa todos los campos obligatorios')),
                            );
                            return;
                          }

                          final properties = propertiesController.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();

                          final safety = safetyController.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();

                          try {
                            final thermalPoint = ThermalPoint(
                              id: point.id,
                              name: name,
                              description: description,
                              type: selectedType,
                              temperature: temp,
                              address: address,
                              latitude: selectedLatitude,
                              longitude: selectedLongitude,
                              imageUrl: imageUrl,
                              price: priceController.text.trim().isEmpty
                                  ? null
                                  : priceController.text.trim(),
                              openingHours: openingHoursController.text.trim().isEmpty
                                  ? null
                                  : openingHoursController.text.trim(),
                              accessibility: point.accessibility,
                              properties: properties.isEmpty ? const ['Natural'] : properties,
                              safety: safety.isEmpty ? const ['Respeta la señalización'] : safety,
                            );

                            await _thermalPointsCollection
                                .doc(point.id)
                                .set(_thermalPointToMap(thermalPoint), SetOptions(merge: true));

                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('✅ Punto termal actualizado')),
                            );
                          } catch (e) {
                            if (!dialogContext.mounted) return;
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(content: Text('Error al guardar: $e')),
                            );
                          }
                        },
                        child: const Text('Guardar cambios'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<LatLng?> _pickLocationOnMap({
    required double initialLatitude,
    required double initialLongitude,
  }) async {
    LatLng selectedPoint = LatLng(initialLatitude, initialLongitude);

    return showDialog<LatLng>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: SizedBox(
          width: 860,
          height: 620,
          child: StatefulBuilder(
            builder: (context, setMapState) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Selecciona ubicación en el mapa',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      Text(
                        'Lat ${selectedPoint.latitude.toStringAsFixed(5)} · Lng ${selectedPoint.longitude.toStringAsFixed(5)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: selectedPoint,
                      initialZoom: 13,
                      onTap: (_, latLng) {
                        setMapState(() {
                          selectedPoint = latLng;
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.ourense_termal',
                        tileProvider: CancellableNetworkTileProvider(),
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: selectedPoint,
                            width: 42,
                            height: 42,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 42,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context, selectedPoint),
                        icon: const Icon(Icons.check),
                        label: const Text('Usar esta ubicación'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _generateQRCheckIn() async {
    final pointId = _assignedThermalPointId;
    if (pointId == null) {
      return;
    }

    try {
      final pointName = _getThermalPointName(pointId);
      final activeQr = await _qrService.generateNewQR(pointId);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'QR Generado - $pointName',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: QrImageView(
                      data: activeQr.code,
                      version: QrVersions.auto,
                      size: 250,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Código: ${activeQr.code}',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Este QR es ahora el válido.\nLos códigos anteriores expirarán.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ QR generado exitosamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _addImage() async {
    final imageUrl = _imageUrlController.text.trim();
    if (imageUrl.isEmpty) return;

    setState(() {
      _managerImages.add(imageUrl);
      _imageUrlController.clear();
    });

    final pointId = _assignedThermalPointId;
    if (pointId != null) {
      try {
        await _thermalPointsCollection.doc(pointId).set({
          'imageUrl': imageUrl,
          'updatedAt': DateTime.now(),
        }, SetOptions(merge: true));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imagen guardada en galería, pero no en el punto termal: $e')),
        );
        return;
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Imagen añadida y actualizada en el punto termal')),
    );
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
            initialValue: _selectedRequestedThermalPointId,
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
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showEditAssignedThermalPointDialog,
              icon: const Icon(Icons.edit_location_alt),
              label: const Text('Editar mi punto termal'),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.light.primaryColor.withValues(alpha: 0.1),
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
