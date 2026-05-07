/// Enumeración que define los roles disponibles en la aplicación.
///
/// Los valores canónicos son `user`, `thermalManager` y `admin`.
enum UserRole {
  user,
  thermalManager,
  admin;

  /// Convierte un string a UserRole.
  ///
  /// Se mantiene compatibilidad con algunos valores antiguos para no romper
  /// usuarios ya guardados en Firebase o SQLite.
  static UserRole fromString(String value) {
    final normalized = value.trim().toLowerCase();

    if (normalized == 'user') {
      return UserRole.user;
    }

    if (normalized == 'thermalmanager') {
      return UserRole.thermalManager;
    }

    if (normalized == 'admin') {
      return UserRole.admin;
    }

    return UserRole.user;
  }
}

extension UserRoleExtension on UserRole {
  /// Obtiene el nombre del rol en formato legible
  String getDisplayName() {
    switch (this) {
      case UserRole.user:
        return 'user';
      case UserRole.thermalManager:
        return 'thermalManager';
      case UserRole.admin:
        return 'admin';
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
