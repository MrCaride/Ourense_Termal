import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../screens/home_screen.dart';
import '../screens/thermal_manager_screen.dart';
import '../screens/admin_screen.dart';
import '../services/auth_service.dart';

/// Widget que redirecciona a los usuarios a la pantalla correcta según su rol
class RoleBasedNavigator extends StatefulWidget {
  final User user;

  const RoleBasedNavigator({super.key, required this.user});

  @override
  State<RoleBasedNavigator> createState() => _RoleBasedNavigatorState();
}

class _RoleBasedNavigatorState extends State<RoleBasedNavigator> {
  final AuthService _authService = AuthService();
  late User _resolvedUser;
  bool _isResolving = true;

  @override
  void initState() {
    super.initState();
    _resolvedUser = widget.user;
    _resolveCurrentUser();
  }

  Future<void> _resolveCurrentUser() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      if (!mounted) return;

      if (currentUser != null && currentUser.id == widget.user.id) {
        _resolvedUser = currentUser;
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResolving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isResolving) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    switch (_resolvedUser.role) {
      case UserRole.admin:
        return AdminScreen(user: _resolvedUser);
      case UserRole.thermalManager:
        return ThermalManagerScreen(user: _resolvedUser);
      case UserRole.user:
        return HomeScreen(user: _resolvedUser);
    }
  }
}
