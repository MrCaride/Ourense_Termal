import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/role_based_navigator.dart';
import '../models/user_role.dart';
import '../utils/app_theme.dart';

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
    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppTheme.heroGradient)),
          Positioned(
            top: -80,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.13),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [AppTheme.brandTeal, AppTheme.brandCyan],
                              ),
                            ),
                            child: const Icon(Icons.water_drop, color: Colors.white, size: 28),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ourense Termal',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.brandSlate,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _authMode == AuthMode.login
                            ? 'Vuelve a sumergirte en la experiencia termal'
                            : 'Crea tu cuenta y empieza tu ruta de bienestar',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.black.withValues(alpha: 0.62),
                            ),
                      ),
                      const SizedBox(height: 24),
                      SegmentedButton<AuthMode>(
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            AppTheme.brandTeal.withValues(alpha: 0.08),
                          ),
                        ),
                        segments: const [
                          ButtonSegment(
                            value: AuthMode.login,
                            label: Text('Entrar'),
                            icon: Icon(Icons.login),
                          ),
                          ButtonSegment(
                            value: AuthMode.register,
                            label: Text('Crear cuenta'),
                            icon: Icon(Icons.person_add_alt_1),
                          ),
                        ],
                        selected: {_authMode},
                        onSelectionChanged: (value) {
                          setState(() {
                            _authMode = value.first;
                          });
                        },
                      ),
                      const SizedBox(height: 18),
                      if (_authMode == AuthMode.register) ...[
                        TextField(
                          controller: _nameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Nombre completo',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        Text(
                          'Tipo de cuenta',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SegmentedButton<UserRole>(
                          style: ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll(
                              AppTheme.brandTeal.withValues(alpha: 0.08),
                            ),
                          ),
                          segments: const [
                            ButtonSegment(
                              value: UserRole.user,
                              label: Text('Usuario'),
                              icon: Icon(Icons.person),
                            ),
                            ButtonSegment(
                              value: UserRole.thermalManager,
                              label: Text('Gerente'),
                              icon: Icon(Icons.manage_accounts),
                            ),
                            ButtonSegment(
                              value: UserRole.admin,
                              label: Text('Admin'),
                              icon: Icon(Icons.admin_panel_settings),
                            ),
                          ],
                          selected: {_selectedRole},
                          onSelectionChanged: (value) {
                            setState(() {
                              _selectedRole = value.first;
                            });
                          },
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Modo temporal: puedes crear cuentas admin desde este formulario.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.orange[800],
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 14),
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
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        textInputAction: _authMode == AuthMode.register
                            ? TextInputAction.next
                            : TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: Icon(Icons.lock_outline_rounded),
                        ),
                      ),
                      if (_authMode == AuthMode.register) ...[
                        const SizedBox(height: 14),
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
                      const SizedBox(height: 22),
                      FilledButton(
                        onPressed: _isLoading
                            ? null
                            : (_authMode == AuthMode.login
                                ? _handleLogin
                                : _handleRegister),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                _authMode == AuthMode.login
                                    ? 'Acceder'
                                    : 'Crear cuenta',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Usamos tu ubicación para ordenar puntos termales por cercanía y mejorar la experiencia.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.black.withValues(alpha: 0.56),
                              height: 1.45,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
