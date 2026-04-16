import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../services/auth_service.dart';
import '../services/qr_service.dart';
import '../services/user_data_service.dart';
import '../screens/login_screen.dart';
import '../data/thermal_points_data.dart';
import '../utils/app_theme.dart';

class AdminScreen extends StatefulWidget {
  final User user;

  const AdminScreen({super.key, required this.user});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;
  final QRService _qrService = QRService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        elevation: 0,
        actions: [
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
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Recompensas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configuración',
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
      case 2:
        return _buildRewardsSection();
      case 3:
        return _buildSettingsSection();
      default:
        return _buildThermalPointsSection();
    }
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
            icon: Icons.mark_email_unread,
            title: 'Solicitudes de Gerentes',
            description: 'Revisa y acepta solicitudes de asignación',
            onTap: _showManagerPointRequests,
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            icon: Icons.add_location,
            title: 'Crear Punto Termal',
            description: 'Añade un nuevo punto termal al sistema',
            onTap: () {
              // TODO: Implementar creación de punto termal
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidad en desarrollo')),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            icon: Icons.edit_location,
            title: 'Editar Puntos Termales',
            description: 'Modifica la información de puntos termales',
            onTap: () {
              // TODO: Implementar edición de puntos termales
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidad en desarrollo')),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            icon: Icons.delete_outline,
            title: 'Eliminar Puntos Termales',
            description: 'Elimina puntos termales del sistema',
            onTap: () {
              // TODO: Implementar eliminación de puntos termales
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidad en desarrollo')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showGenerateQRDialog() {
    final thermalPoints = ThermalPointsData.getThermalPoints();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generar QR Check-in'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
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

  void _showQRHistoryDialog() {
    final thermalPoints = ThermalPointsData.getThermalPoints();
    
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
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: thermalPoints.length,
                  itemBuilder: (context, index) {
                    final point = thermalPoints[index];
                    return ListTile(
                      title: Text(point.name),
                      subtitle: Text(point.address),
                      trailing: IconButton(
                        icon: const Icon(Icons.list),
                        onPressed: () async {
                          Navigator.pop(context);
                          await _showQRHistoryList(point.id, point.name);
                        },
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
                  child: ListView.builder(
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
          _buildAdminCard(
            icon: Icons.person_add,
            title: 'Crear Usuario',
            description: 'Añade un nuevo usuario al sistema',
            onTap: _showCreateUserDialog,
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

  Widget _buildRewardsSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gestión de Recompensas',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildAdminCard(
            icon: Icons.card_giftcard,
            title: 'Crear Recompensa',
            description: 'Añade una nueva recompensa',
            onTap: () {
              // TODO: Implementar creación de recompensa
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidad en desarrollo')),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            icon: Icons.edit,
            title: 'Editar Recompensas',
            description: 'Modifica información de recompensas',
            onTap: () {
              // TODO: Implementar edición de recompensas
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidad en desarrollo')),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            icon: Icons.delete_outline,
            title: 'Eliminar Recompensas',
            description: 'Elimina recompensas del sistema',
            onTap: () {
              // TODO: Implementar eliminación de recompensas
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidad en desarrollo')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuración del Sistema',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildAdminCard(
            icon: Icons.settings,
            title: 'Parámetros de Juego',
            description: 'Configura puntos, niveles y progresión',
            onTap: () {
              // TODO: Implementar configuración de parámetros
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidad en desarrollo')),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            icon: Icons.analytics,
            title: 'Estadísticas',
            description: 'Ver estadísticas de la aplicación',
            onTap: () {
              // TODO: Implementar estadísticas
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidad en desarrollo')),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildAdminCard(
            icon: Icons.backup,
            title: 'Respaldo de Datos',
            description: 'Realiza copias de seguridad del sistema',
            onTap: () {
              // TODO: Implementar respaldo
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Funcionalidad en desarrollo')),
              );
            },
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
                        label: Text('Usuario'),
                      ),
                      ButtonSegment<UserRole>(
                        value: UserRole.thermalManager,
                        label: Text('Gerente'),
                      ),
                      ButtonSegment<UserRole>(
                        value: UserRole.admin,
                        label: Text('Admin'),
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
                            trailing: user.role == UserRole.thermalManager
                              ? IconButton(
                                  icon: const Icon(Icons.location_on),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showAssignThermalPointDialog(
                                      user.id,
                                      user.name,
                                      user.thermalPointId,
                                    );
                                  },
                                )
                              : null,
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
                'Gerente: $managerName',
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
