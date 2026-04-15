import 'package:flutter/material.dart';
import '../components/index.dart';
import '../services/auth_service.dart';
import '../widgets/role_based_navigator.dart';
import '../models/user_role.dart';
import '../theme/index.dart';

enum AuthMode { login, register }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  AuthMode _authMode = AuthMode.login;
  UserRole _selectedRole = UserRole.user;
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    // Entrada progresiva del formulario para una primera impresión más cuidada.
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (mounted) {
        setState(() {
          _showForm = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El email no tiene un formato válido')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.login(email: email, password: password);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => RoleBasedNavigator(user: user)),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error inesperado al iniciar sesión')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El email no tiene un formato válido')),
      );
      return;
    }

    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre debe tener al menos 2 caracteres')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.register(
        name: name,
        email: email,
        password: password,
        role: _selectedRole,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => RoleBasedNavigator(user: user)),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error inesperado al registrar el usuario')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _authMode == AuthMode.login ? 'Bienvenido de nuevo' : 'Crea tu cuenta';
    final subtitle = _authMode == AuthMode.login
        ? 'Explora Ourense, suma puntos y descubre nuevas rutas termales.'
        : 'Empieza tu viaje termal con recompensas y logros desde el primer check-in.';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF0F9FF),
              Color(0xFFE6F8F5),
              Colors.white,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -90,
              left: -30,
              child: _SoftOrb(
                size: 220,
                colors: const [Color(0x3314B8A6), Color(0x19F59E0B)],
              ),
            ),
            Positioned(
              top: 120,
              right: -70,
              child: _SoftOrb(
                size: 260,
                colors: const [Color(0x3314B8A6), Color(0x260EA5E9)],
              ),
            ),
            Positioned(
              bottom: -100,
              left: 20,
              child: _SoftOrb(
                size: 260,
                colors: const [Color(0x22EA6947), Color(0x15A855F7)],
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.96, end: 1),
                    duration: const Duration(milliseconds: 450),
                    curve: Curves.easeOutCubic,
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOut,
                      opacity: _showForm ? 1 : 0,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: CustomCard(
                          borderRadius: AppRadius.xl,
                          backgroundColor: Colors.white.withValues(alpha: 0.92),
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          shadows: AppShadows.elevation3,
                          border: Border.all(color: AppColors.borderLighter),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Hero(
                                    tag: 'ourense_app_mark',
                                    child: Container(
                                      width: 58,
                                      height: 58,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [AppColors.thermalCool, AppColors.accentBlue],
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 30),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Ourense Termal', style: AppTypography.titleLarge),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text('Turismo termal gamificado', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Text(title, style: AppTypography.displaySmall),
                              const SizedBox(height: AppSpacing.sm),
                              Text(subtitle, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                              const SizedBox(height: AppSpacing.xl),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOut,
                                padding: const EdgeInsets.all(AppSpacing.xs),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                ),
                                child: SegmentedButton<AuthMode>(
                                  segments: const [
                                    ButtonSegment(value: AuthMode.login, icon: Icon(Icons.login_rounded), label: Text('Entrar')),
                                    ButtonSegment(value: AuthMode.register, icon: Icon(Icons.person_add_alt_1_rounded), label: Text('Crear cuenta')),
                                  ],
                                  selected: {_authMode},
                                  onSelectionChanged: (value) {
                                    setState(() {
                                      _authMode = value.first;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                child: Column(
                                  key: ValueKey(_authMode),
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if (_authMode == AuthMode.register) ...[
                                      TextField(
                                        controller: _nameController,
                                        textInputAction: TextInputAction.next,
                                        decoration: const InputDecoration(
                                          labelText: 'Nombre completo',
                                          prefixIcon: Icon(Icons.person_outline_rounded),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      Text('Tipo de cuenta', style: AppTypography.labelLarge),
                                      const SizedBox(height: AppSpacing.sm),
                                      SegmentedButton<UserRole>(
                                        segments: const [
                                          ButtonSegment(value: UserRole.user, icon: Icon(Icons.person_rounded), label: Text('Usuario')),
                                          ButtonSegment(value: UserRole.thermalManager, icon: Icon(Icons.store_mall_directory_rounded), label: Text('Gerente')),
                                          ButtonSegment(value: UserRole.admin, icon: Icon(Icons.admin_panel_settings_rounded), label: Text('Admin')),
                                        ],
                                        selected: {_selectedRole},
                                        onSelectionChanged: (value) {
                                          setState(() {
                                            _selectedRole = value.first;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      InfoTile(
                                        icon: Icons.info_outline_rounded,
                                        title: 'Modo temporal activo',
                                        subtitle: 'Puedes registrar cuentas de admin desde aquí.',
                                        iconColor: AppColors.thermalGoldDark,
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                    ],
                                    TextField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                        labelText: 'Correo electrónico',
                                        prefixIcon: Icon(Icons.alternate_email_rounded),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    TextField(
                                      controller: _passwordController,
                                      obscureText: true,
                                      textInputAction: _authMode == AuthMode.register ? TextInputAction.next : TextInputAction.done,
                                      decoration: const InputDecoration(
                                        labelText: 'Contraseña',
                                        prefixIcon: Icon(Icons.lock_outline_rounded),
                                      ),
                                    ),
                                    if (_authMode == AuthMode.register) ...[
                                      const SizedBox(height: AppSpacing.md),
                                      TextField(
                                        controller: _confirmPasswordController,
                                        obscureText: true,
                                        textInputAction: TextInputAction.done,
                                        decoration: const InputDecoration(
                                          labelText: 'Confirmar contraseña',
                                          prefixIcon: Icon(Icons.verified_user_outlined),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOut,
                                transform: Matrix4.diagonal3Values(
                                  _isLoading ? 0.995 : 1.0,
                                  _isLoading ? 0.995 : 1.0,
                                  1.0,
                                ),
                                child: CustomButton(
                                  label: _authMode == AuthMode.login ? 'Acceder' : 'Crear cuenta',
                                  icon: _authMode == AuthMode.login ? Icons.login_rounded : Icons.person_add_alt_1_rounded,
                                  isLoading: _isLoading,
                                  onPressed: _isLoading ? () {} : (_authMode == AuthMode.login ? _handleLogin : _handleRegister),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Usamos tu ubicación para mostrar puntos termales cercanos y mejorar tus rutas.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftOrb extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _SoftOrb({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
    );
  }
}
