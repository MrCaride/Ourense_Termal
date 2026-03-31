import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import '../screens/home_screen.dart';
import '../screens/thermal_manager_screen.dart';
import '../screens/admin_screen.dart';

/// Widget que redirecciona a los usuarios a la pantalla correcta según su rol
class RoleBasedNavigator extends StatelessWidget {
  final User user;

  const RoleBasedNavigator({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    switch (user.role) {
      case UserRole.admin:
        return AdminScreen(user: user);
      case UserRole.thermalManager:
        return ThermalManagerScreen(user: user);
      case UserRole.user:
      default:
        return HomeScreen(user: user);
    }
  }
}
