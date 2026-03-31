/// Enumeración que define los roles disponibles en la aplicación
enum UserRole {
  user,           // Usuario normal con acceso a mapas, rutas y recompensas
  thermalManager, // Gerente de termas con acceso a QR check-in y gestión de imágenes
  admin,          // Administrador con acceso completo a gestión de termas, usuarios y recompensas

  ;

  /// Convierte un string a UserRole
  static UserRole fromString(String value) {
    switch (value) {
      case 'user':
        return UserRole.user;
      case 'thermalManager':
        return UserRole.thermalManager;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.user;
    }
  }
}

extension UserRoleExtension on UserRole {
  /// Obtiene el nombre del rol en formato legible
  String getDisplayName() {
    switch (this) {
      case UserRole.user:
        return 'Usuario';
      case UserRole.thermalManager:
        return 'Gerente de Termas';
      case UserRole.admin:
        return 'Administrador';
    }
  }

  /// Obtiene el valor string del rol para almacenamiento
  String getValue() {
    switch (this) {
      case UserRole.user:
        return 'user';
      case UserRole.thermalManager:
        return 'thermalManager';
      case UserRole.admin:
        return 'admin';
    }
  }
}
