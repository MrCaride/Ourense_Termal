import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../models/thermal_point_model.dart';
import '../services/auth_service.dart';
import '../services/qr_service.dart';
import '../services/user_data_service.dart';
import '../screens/login_screen.dart';
import '../data/thermal_points_data.dart';
import '../components/index.dart';
import '../theme/index.dart';
import '../utils/app_theme.dart';

class AdminScreen extends StatefulWidget {
  final User user;

  const AdminScreen({super.key, required this.user});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 1;
  final QRService _qrService = QRService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Panel de Administración'),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _showPanelSwitcher,
            icon: const Icon(Icons.dashboard_outlined, color: Colors.white),
            label: const Text('Paneles'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
            ),
          ),
          if (_selectedIndex == 1) ...[
            IconButton(
              tooltip: 'Crear usuario',
              icon: const Icon(Icons.person_add_alt_1),
              onPressed: _showCreateUserDialog,
            ),
            IconButton(
              tooltip: 'Editar usuarios',
              icon: const Icon(Icons.edit),
              onPressed: _showUsersList,
            ),
            IconButton(
              tooltip: 'Eliminar usuarios',
              icon: const Icon(Icons.person_remove),
              onPressed: _showDeleteUserDialog,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Cerrar sesión',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Text('¿Deseas cerrar tu sesión?'),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            const SizedBox(width: 8),
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
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPanelSwitcher,
        icon: const Icon(Icons.dashboard_outlined),
        label: const Text('Cambiar panel'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Puntos Termales',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Usuarios',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildThermalPointsSection();
      case 1:
        return _buildUsersSection();
      default:
        return _buildThermalPointsSection();
    }
  }

  void _showPanelSwitcher() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Cambiar de panel',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPanelSwitcherTile(
                    icon: Icons.location_on,
                    title: 'Puntos Termales',
                    subtitle: 'QR, historial y gestión de puntos',
                    index: 0,
                  ),
                  _buildPanelSwitcherTile(
                    icon: Icons.people,
                    title: 'Usuarios',
                    subtitle: 'Crear, editar y borrar usuarios',
                    index: 1,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPanelSwitcherTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required int index,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.accentBlue),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.pop(context);
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildThermalPointsSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gestión de Puntos Termales',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildAdminCard(
            icon: Icons.qr_code_2,
            title: 'Generar QR Check-in',
            description: 'Crea un nuevo código QR válido para un punto termal',
            onTap: () => _showGenerateQRDialog(),
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            icon: Icons.history,
            title: 'Ver Historial de QR',
            description: 'Consulta QR anteriores y el estado de cada uno',
            onTap: () => _showQRHistoryDialog(),
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            icon: Icons.add_location,
            title: 'Crear Punto Termal',
            description: 'Añade un nuevo punto termal al sistema',
            onTap: _showCreateThermalPointDialog,
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            icon: Icons.edit_location,
            title: 'Editar Puntos Termales',
            description: 'Modifica la información de puntos termales',
            onTap: _showEditThermalPointsDialog,
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            icon: Icons.delete_outline,
            title: 'Eliminar Puntos Termales',
            description: 'Elimina puntos termales del sistema',
            onTap: _showDeleteThermalPointsDialog,
          ),
        ],
      ),
    );
  }

  CollectionReference<Map<String, dynamic>> get _thermalPointsCollection {
    return _firestore.collection('thermal_points');
  }

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }

  String _slugify(String text) {
    final normalized = text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s_]'), '')
        .replaceAll(RegExp(r'\s+'), '_');

    if (normalized.isEmpty) {
      return 'punto_termal';
    }
    return normalized;
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

  ThermalPoint _thermalPointFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return ThermalPoint(
      id: doc.id,
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

  Future<void> _ensureThermalPointsSeeded() async {
    final snapshot = await _thermalPointsCollection.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final batch = _firestore.batch();
    for (final point in ThermalPointsData.getThermalPoints()) {
      final ref = _thermalPointsCollection.doc(point.id);
      batch.set(ref, {
        ..._thermalPointToMap(point),
        'createdAt': DateTime.now(),
      });
    }
    await batch.commit();
  }

  Future<List<ThermalPoint>> _getThermalPointsForAdmin() async {
    await _ensureThermalPointsSeeded();
    final snapshot = await _thermalPointsCollection.orderBy('name').get();
    return snapshot.docs.map(_thermalPointFromDoc).toList();
  }

  Future<void> _showCreateThermalPointDialog() async {
    await _showThermalPointFormDialog();
  }

  Future<void> _showEditThermalPointsDialog() async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Editar Puntos Termales',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.maxFinite,
                height: 420,
                child: FutureBuilder<List<ThermalPoint>>(
                  future: _getThermalPointsForAdmin(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final points = snapshot.data ?? const [];
                    if (points.isEmpty) {
                      return const Center(child: Text('No hay puntos termales'));
                    }

                    return ListView.builder(
                      itemCount: points.length,
                      itemBuilder: (context, index) {
                        final point = points[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(point.name),
                            subtitle: Text(point.address),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                Navigator.pop(context);
                                _showThermalPointFormDialog(point: point);
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
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
    );
  }

  Future<void> _showDeleteThermalPointsDialog() async {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Eliminar Puntos Termales',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.maxFinite,
                height: 420,
                child: FutureBuilder<List<ThermalPoint>>(
                  future: _getThermalPointsForAdmin(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final points = snapshot.data ?? const [];
                    if (points.isEmpty) {
                      return const Center(child: Text('No hay puntos termales'));
                    }

                    return ListView.builder(
                      itemCount: points.length,
                      itemBuilder: (context, index) {
                        final point = points[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(point.name),
                            subtitle: Text(point.address),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showDeleteThermalPointConfirmation(point);
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
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
    );
  }

  Future<void> _showDeleteThermalPointConfirmation(ThermalPoint point) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Punto Termal'),
        content: Text('¿Seguro que deseas eliminar "${point.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _thermalPointsCollection.doc(point.id).delete();
                if (!context.mounted) return;
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✅ Punto "${point.name}" eliminado')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al eliminar: $e')),
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showThermalPointFormDialog({ThermalPoint? point}) async {
    final isEditing = point != null;
    final nameController = TextEditingController(text: point?.name ?? '');
    final descriptionController = TextEditingController(text: point?.description ?? '');
    final addressController = TextEditingController(text: point?.address ?? '');
    final imageUrlController = TextEditingController(text: point?.imageUrl ?? '');
    final temperatureController = TextEditingController(
      text: point != null ? point.temperature.toString() : '37.0',
    );
    double selectedLatitude = point?.latitude ?? 42.3403;
    double selectedLongitude = point?.longitude ?? -7.8639;
    final openingHoursController = TextEditingController(text: point?.openingHours ?? '');
    final priceController = TextEditingController(text: point?.price ?? '');
    final propertiesController = TextEditingController(
      text: point != null ? point.properties.join(', ') : 'Natural, Relajante, Mineral',
    );
    final safetyController = TextEditingController(
      text: point != null ? point.safety.join(', ') : 'Respeta la señalización, Mantén hidratación',
    );

    String selectedType = point?.type ?? 'pool';

    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                    isEditing ? 'Editar Punto Termal' : 'Crear Punto Termal',
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
                    value: selectedType,
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
                            label: Text(isEditing ? 'Relocalizar en mapa' : 'Seleccionar en mapa'),
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
                        onPressed: () => Navigator.pop(context),
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
                            ScaffoldMessenger.of(context).showSnackBar(
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
                            final id = point?.id ?? '${_slugify(name)}_${DateTime.now().millisecondsSinceEpoch}';
                            final thermalPoint = ThermalPoint(
                              id: id,
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
                              accessibility: point?.accessibility ?? 'estandar',
                              properties: properties.isEmpty ? const ['Natural'] : properties,
                              safety: safety.isEmpty ? const ['Respeta la señalización'] : safety,
                            );

                            final payload = <String, dynamic>{
                              ..._thermalPointToMap(thermalPoint),
                            };
                            if (point == null) {
                              payload['createdAt'] = DateTime.now();
                            }

                            await _thermalPointsCollection
                                .doc(id)
                                .set(payload, SetOptions(merge: true));

                            if (!context.mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEditing
                                      ? '✅ Punto termal actualizado'
                                      : '✅ Punto termal creado',
                                ),
                              ),
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error al guardar: $e')),
                            );
                          }
                        },
                        child: Text(isEditing ? 'Guardar cambios' : 'Crear'),
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
                      onTap: (tapPosition, point) {
                        setMapState(() {
                          selectedPoint = point;
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.ourense.termal',
                        tileProvider: CancellableNetworkTileProvider(),
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: selectedPoint,
                            width: 44,
                            height: 44,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, selectedPoint),
                        child: const Text('Usar esta ubicación'),
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

  void _showGenerateQRDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generar QR Check-in'),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<ThermalPoint>>(
            future: _getThermalPointsForAdmin(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 180,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return SizedBox(
                  height: 180,
                  child: Center(child: Text('Error: ${snapshot.error}')),
                );
              }

              final thermalPoints = snapshot.data ?? const [];
              if (thermalPoints.isEmpty) {
                return const SizedBox(
                  height: 180,
                  child: Center(child: Text('No hay puntos termales disponibles')),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: thermalPoints.length,
                itemBuilder: (context, index) {
                  final point = thermalPoints[index];
                  return ListTile(
                    title: Text(point.name),
                    subtitle: Text(point.address),
                    trailing: IconButton(
                      icon: const Icon(Icons.qr_code),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _generateAndShowQR(point.id, point.name);
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndShowQR(String thermalPointId, String pointName) async {
    try {
      final newQR = await _qrService.generateNewQR(thermalPointId);
      
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
                      data: newQR.code,
                      version: QrVersions.auto,
                      size: 250,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Código: ${newQR.code}',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  String? _extractThermalPointIdFromQrCode(dynamic rawCode) {
    if (rawCode is! String) return null;
    final code = rawCode.trim();
    if (code.isEmpty) return null;

    final separatorIndex = code.lastIndexOf('-');
    if (separatorIndex <= 0) return null;

    final pointId = code.substring(0, separatorIndex).trim();
    return pointId.isEmpty ? null : pointId;
  }

  Future<List<Map<String, String>>> _getQRHistoryEntriesForAdmin() async {
    final thermalPoints = await _getThermalPointsForAdmin();
    final pointsById = <String, ThermalPoint>{
      for (final point in thermalPoints) point.id: point,
    };

    final historySnapshot = await _firestore.collectionGroup('activeQR').get();
    final pointIdsWithHistory = <String>{};

    for (final doc in historySnapshot.docs) {
      final data = doc.data();
      final rawPointId = data['thermalPointId'];
      String? pointId;

      if (rawPointId is String && rawPointId.trim().isNotEmpty) {
        pointId = rawPointId.trim();
      } else {
        pointId = _extractThermalPointIdFromQrCode(data['code']);
      }

      if (pointId != null && pointId.isNotEmpty) {
        pointIdsWithHistory.add(pointId);
      }
    }

    final entries = pointIdsWithHistory.map((pointId) {
      final point = pointsById[pointId];
      return {
        'id': pointId,
        'name': point?.name ?? pointId,
        'subtitle': point?.address ?? 'Punto detectado por historial QR',
      };
    }).toList();

    entries.sort((a, b) =>
        (a['name'] ?? a['id'] ?? '').compareTo(b['name'] ?? b['id'] ?? ''));
    return entries;
  }

  void _showQRHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Historial de QR',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.maxFinite,
                height: 300,
                child: FutureBuilder<List<Map<String, String>>>(
                  future: _getQRHistoryEntriesForAdmin(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final historyEntries = snapshot.data ?? const [];
                    if (historyEntries.isEmpty) {
                      return const Center(child: Text('No hay historial QR disponible'));
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: historyEntries.length,
                      itemBuilder: (context, index) {
                        final entry = historyEntries[index];
                        final pointId = entry['id'] ?? '';
                        final pointName = entry['name'] ?? pointId;
                        final subtitle = entry['subtitle'] ?? '';
                        return ListTile(
                          title: Text(pointName),
                          subtitle: Text(subtitle),
                          trailing: IconButton(
                            icon: const Icon(Icons.list),
                            onPressed: () async {
                              Navigator.pop(context);
                              await _showQRHistoryList(pointId, pointName);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
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
    );
  }

  Future<void> _showQRHistoryList(String thermalPointId, String pointName) async {
    try {
      final qrHistory = await _qrService.getQRHistory(thermalPointId);
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Historial QR - $pointName',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.maxFinite,
                  height: 300,
                  child: qrHistory.isEmpty
                      ? const Center(
                          child: Text('No hay historial QR para este punto termal'),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: qrHistory.length,
                          itemBuilder: (context, index) {
                            final qr = qrHistory[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                title: Text('QR #${index + 1}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Creado: ${qr.createdAt.toString().substring(0, 19)}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    Text(
                                      qr.isValid ? '✅ Activo' : '❌ Expirado',
                                      style: TextStyle(
                                        color: qr.isValid ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
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
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Widget _buildUsersSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gestión de Usuarios',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          CustomCard(
            border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.2)),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Acciones rápidas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _showCreateUserDialog,
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text('Crear'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _showUsersList,
                          icon: const Icon(Icons.edit),
                          label: const Text('Editar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _showDeleteUserDialog,
                          icon: const Icon(Icons.person_remove),
                          label: const Text('Borrar'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accentRed,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildAdminCard(
            icon: Icons.person_add,
            title: 'Crear Usuario',
            description: 'Añade un nuevo usuario al sistema',
            onTap: _showCreateUserDialog,
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            icon: Icons.edit,
            title: 'Editar Usuarios',
            description: 'Modifica nombre, rol, puntos y nivel de un usuario',
            onTap: _showUsersList,
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            icon: Icons.list,
            title: 'Ver Todos los Usuarios',
            description: 'Administra usuarios y asigna puntos a gerentes',
            onTap: _showUsersList,
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            icon: Icons.location_on,
            title: 'Asignar Punto a Gerente',
            description: 'Selecciona un gerente y asígnale un punto termal',
            onTap: _showManagersToAssignList,
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            icon: Icons.mark_email_unread,
            title: 'Solicitudes de Gerentes',
            description: 'Revisa y acepta solicitudes de asignación de punto termal',
            onTap: _showManagerPointRequests,
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            icon: Icons.person_remove,
            title: 'Eliminar Usuarios',
            description: 'Elimina usuarios del sistema',
            onTap: _showDeleteUserDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.light.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.light.primaryColor,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showCreateUserDialog() {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    UserRole selectedRole = UserRole.user;

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
                  'Crear Nuevo Usuario',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                StatefulBuilder(
                  builder: (context, setRoleState) => SegmentedButton<UserRole>(
                    segments: const <ButtonSegment<UserRole>>[
                      ButtonSegment<UserRole>(
                        value: UserRole.user,
                        label: Text('usuario'),
                      ),
                      ButtonSegment<UserRole>(
                        value: UserRole.thermalManager,
                        label: Text('gerente'),
                      ),
                      ButtonSegment<UserRole>(
                        value: UserRole.admin,
                        label: Text('admin'),
                      ),
                    ],
                    selected: <UserRole>{selectedRole},
                    onSelectionChanged: (Set<UserRole> newSelection) {
                      setRoleState(() {
                        selectedRole = newSelection.first;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.isEmpty ||
                            emailController.text.isEmpty ||
                            passwordController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Por favor completa todos los campos'),
                            ),
                          );
                          return;
                        }

                        try {
                          await AuthService().register(
                            name: nameController.text,
                            email: emailController.text,
                            password: passwordController.text,
                            role: selectedRole,
                            acceptedTerms: true,
                          );

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Usuario creado exitosamente'),
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      },
                      child: const Text('Crear Usuario'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUsersList() async {
    final userDataService = UserDataService();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Administrar Usuarios',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.maxFinite,
                height: 400,
                child: FutureBuilder<List<User>>(
                  future: userDataService.getAllUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No hay usuarios'));
                    }

                    final users = snapshot.data!;
                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(user.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.email),
                                Text(
                                  'Rol: ${user.role.getDisplayName()}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (user.role == UserRole.thermalManager)
                                  IconButton(
                                    tooltip: 'Asignar punto termal',
                                    icon: const Icon(Icons.location_on),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _showAssignThermalPointDialog(
                                        user.id,
                                        user.name,
                                        user.thermalPointId,
                                      );
                                    },
                                  ),
                                IconButton(
                                  tooltip: 'Editar usuario',
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showEditUserDialog(user);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
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
    );
  }

  void _showManagerPointRequests() {
    final userDataService = UserDataService();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Solicitudes de Gerentes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.maxFinite,
                height: 420,
                child: FutureBuilder<List<ThermalPointAssignmentRequest>>(
                  future: userDataService.getPendingThermalPointRequests(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error al cargar solicitudes: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No hay solicitudes pendientes'));
                    }

                    final requests = snapshot.data!;

                    return ListView.builder(
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final request = requests[index];
                        final requestedPointName = ThermalPointsData.getThermalPoints()
                            .where((point) => point.id == request.thermalPointId)
                            .map((point) => point.name)
                            .cast<String?>()
                            .firstWhere((name) => name != null, orElse: () => null);

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(request.managerName),
                            subtitle: Text(
                              requestedPointName == null
                                  ? 'Solicita: ${request.thermalPointId}'
                                  : 'Solicita: $requestedPointName',
                            ),
                            trailing: ElevatedButton(
                              onPressed: () async {
                                await _approveManagerPointRequest(request);
                              },
                              child: const Text('Aceptar'),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
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
    );
  }

  Future<void> _approveManagerPointRequest(
    ThermalPointAssignmentRequest request,
  ) async {
    final userDataService = UserDataService();

    try {
      await userDataService.approveThermalPointRequest(
        managerId: request.managerId,
        thermalPointId: request.thermalPointId,
      );

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Solicitud aceptada y punto asignado'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al aceptar solicitud: $e')),
      );
    }
  }

  void _showManagersToAssignList() {
    final userDataService = UserDataService();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Asignar Punto a Gerente',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.maxFinite,
                height: 400,
                child: FutureBuilder<List<User>>(
                  future: userDataService.getAllUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No hay usuarios'));
                    }

                    final managers = snapshot.data!
                        .where((user) => user.role == UserRole.thermalManager)
                        .toList();

                    if (managers.isEmpty) {
                      return const Center(child: Text('No hay gerentes disponibles'));
                    }

                    return ListView.builder(
                      itemCount: managers.length,
                      itemBuilder: (context, index) {
                        final manager = managers[index];
                        final assignedName = ThermalPointsData.getThermalPoints()
                            .where((point) => point.id == manager.thermalPointId)
                            .map((point) => point.name)
                            .cast<String?>()
                            .firstWhere((name) => name != null, orElse: () => null);

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(manager.name),
                            subtitle: Text(
                              assignedName == null
                                  ? 'Sin punto asignado'
                                  : 'Asignado a: $assignedName',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit_location_alt),
                              onPressed: () {
                                Navigator.pop(context);
                                _showAssignThermalPointDialog(
                                  manager.id,
                                  manager.name,
                                  manager.thermalPointId,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
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
    );
  }

  void _showAssignThermalPointDialog(
    String managerId,
    String managerName,
    String? currentPointId,
  ) {
    final thermalPoints = ThermalPointsData.getThermalPoints();
    String? selectedPointId = currentPointId;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Asignar Punto Termal',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'thermalManager: $managerName',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.maxFinite,
                height: 300,
                child: StatefulBuilder(
                  builder: (context, setRadioState) => ListView.builder(
                    itemCount: thermalPoints.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return RadioListTile<String?>(
                          title: const Text('Sin asignar'),
                          value: null,
                          groupValue: selectedPointId,
                          onChanged: (value) {
                            setRadioState(() {
                              selectedPointId = value;
                            });
                          },
                        );
                      }

                      final point = thermalPoints[index - 1];
                      return RadioListTile<String?>(
                        title: Text(point.name),
                        subtitle: Text(point.address),
                        value: point.id,
                        groupValue: selectedPointId,
                        onChanged: (value) {
                          setRadioState(() {
                            selectedPointId = value;
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final userDataService = UserDataService();
                        await userDataService.assignThermalPointToManager(
                          managerId,
                          selectedPointId,
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Punto termal asignado'),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                    child: const Text('Asignar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditUserDialog(User user) {
    final userDataService = UserDataService();
    final nameController = TextEditingController(text: user.name);
    final pointsController = TextEditingController(text: user.points.toString());
    final levelController = TextEditingController(text: user.level.toString());
    UserRole selectedRole = user.role;
    String? selectedPointId = user.thermalPointId;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: StatefulBuilder(
          builder: (context, setDialogState) => SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Editar Usuario',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(user.email),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pointsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Puntos',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.stars_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: levelController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Nivel',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.workspace_premium),
                    ),
                  ),
                  const SizedBox(height: 12),
                  StatefulBuilder(
                    builder: (context, setRoleState) => SegmentedButton<UserRole>(
                      segments: const <ButtonSegment<UserRole>>[
                        ButtonSegment<UserRole>(
                          value: UserRole.user,
                          label: Text('user'),
                        ),
                        ButtonSegment<UserRole>(
                          value: UserRole.thermalManager,
                          label: Text('thermalManager'),
                        ),
                        ButtonSegment<UserRole>(
                          value: UserRole.admin,
                          label: Text('admin'),
                        ),
                      ],
                      selected: <UserRole>{selectedRole},
                      onSelectionChanged: (Set<UserRole> newSelection) {
                        setRoleState(() {
                          selectedRole = newSelection.first;
                          if (selectedRole != UserRole.thermalManager) {
                            selectedPointId = null;
                          }
                        });
                      },
                    ),
                  ),
                  if (selectedRole == UserRole.thermalManager) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: selectedPointId,
                      decoration: InputDecoration(
                        labelText: 'Punto termal',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Sin asignar'),
                        ),
                        ...ThermalPointsData.getThermalPoints().map(
                          (point) => DropdownMenuItem<String?>(
                            value: point.id,
                            child: Text(point.name),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedPointId = value;
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final parsedPoints = int.tryParse(pointsController.text.trim());
                          final parsedLevel = int.tryParse(levelController.text.trim());

                          if (nameController.text.trim().isEmpty ||
                              parsedPoints == null ||
                              parsedLevel == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Completa correctamente nombre, puntos y nivel'),
                              ),
                            );
                            return;
                          }

                          try {
                            await userDataService.updateUser(
                              userId: user.id,
                              name: nameController.text,
                              role: selectedRole,
                              thermalPointId: selectedPointId,
                              points: parsedPoints,
                              level: parsedLevel,
                            );

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Usuario actualizado'),
                                ),
                              );
                              setState(() {});
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
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

  void _showDeleteUserDialog() async {
    final userDataService = UserDataService();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Eliminar Usuarios',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.maxFinite,
                height: 400,
                child: FutureBuilder<List<User>>(
                  future: userDataService.getAllUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No hay usuarios'));
                    }

                    final users = snapshot.data!;
                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(user.name),
                            subtitle: Text(user.email),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showDeleteConfirmation(user.id, user.name);
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
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
    );
  }

  void _showDeleteConfirmation(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Confirmar eliminación',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                '¿Deseas eliminar a $userName?',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Esta acción no se puede deshacer',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final userDataService = UserDataService();
                        await userDataService.deleteUser(userId);

                        if (context.mounted) {
                          Navigator.pop(context);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✅ Usuario eliminado'),
                            ),
                          );
                          setState(() {}); // Refresh users list
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
