# Ourense Termal 

Aplicación móvil gamificada para incentivar el turismo termal en la provincia de Ourense, Galicia.

## Descripción

Ourense Termal es una aplicación desarrollada en Flutter que permite a los usuarios descubrir y visitar puntos termales en Ourense mediante un sistema de gamificación. Los usuarios pueden hacer check-in en diferentes ubicaciones, completar rutas temáticas, ganar puntos y desbloquear insignias.

## Características principales

- **Autenticación de usuarios**: Registro e inicio de sesión con contraseñas hasheadas
- **Mapa interactivo**: Visualización de todos los puntos termales usando OpenStreetMap
- **Sistema de check-in**: Registro de visitas a puntos termales con recompensas (50 puntos por check-in)
- **Rutas temáticas**: Diferentes rutas para descubrir múltiples puntos termales
- **Sistema de niveles**: Progresión del usuario desde Novato Termal hasta Termal Master (cada 300 puntos = 1 nivel)
- **Insignias y logros**: Desbloqueo automático de medallas por logros (ej: "Primera Visita", "Nivel X Alcanzado")
- **Perfil de usuario**: Seguimiento de puntos, visitas, insignias y nivel conseguidos
- **Sincronización multiplataforma**: Datos sincronizados entre dispositivos usando Firestore y SQLite local

## Requisitos previos

- Flutter SDK (versión 3.0 o superior)
- Dart SDK
- Android Studio / VS Code con extensiones de Flutter
- Dispositivo Android/iOS o emulador configurado

## Instalación

1. Clonar el repositorio:

```bash
git clone [URL_DEL_REPOSITORIO]
cd Ourense_Termal
```

2. Instalar las dependencias:

```bash
flutter pub get
```

3. Verificar que Flutter está correctamente configurado:

```bash
flutter doctor
```

## Ejecución del proyecto

### En modo debug

```bash
flutter run
```

### Seleccionar dispositivo específico

```bash
# Listar dispositivos disponibles
flutter devices

# Ejecutar en un dispositivo específico
flutter run -d [DEVICE_ID]
```

### En modo release (para pruebas de rendimiento)

```bash
flutter run --release
```

## Dependencias principales

- `flutter_map`: Integración de mapas interactivos con OpenStreetMap
- `flutter_map_cancellable_tile_provider`: Optimización del rendimiento de tiles en web
- `latlong2`: Manejo de coordenadas geográficas
- `geolocator`: Acceso a la ubicación del dispositivo
- `firebase_core` & `cloud_firestore`: Backend con Firestore para sincronización en la nube
- `sqflite`: Base de datos local para móvil/desktop
- `crypto`: Hashing seguro de contraseñas con SHA-256
- Material Design 3: Sistema de diseño de la aplicación

## Arquitectura

### Estructura de carpetas

```
lib/
├── models/              # Modelos de datos (User, ThermalPoint, CheckIn, etc)
├── screens/             # Pantallas de la aplicación (Login, Home, Map, Profile, etc)
├── services/            # Servicios de negocio
│   ├── auth_service.dart        # Autenticación (login/registro)
│   ├── user_data_service.dart   # Gestión de datos del usuario
│   ├── database_service.dart    # Acceso a base de datos SQLite
│   └── sync_service.dart        # Sincronización con Firestore
├── widgets/             # Widgets reutilizables
├── utils/               # Funciones auxiliares
└── main.dart           # Punto de entrada de la aplicación
```

### Flujo de autenticación

1. **Login/Registro**: El usuario introduce sus credenciales
2. **Hash de contraseña**: Se hashea con SHA-256 usando el paquete `crypto`
3. **Validación**: Se verifica en Firestore (web) o SQLite (móvil)
4. **Inicio de sesión**: Se carga el usuario con sus datos personalizados
5. **Logout**: El usuario cierra sesión desde el perfil

### Vinculación de datos al usuario

Cada usuario tiene sus propios datos asociados:
- **Puntos**: Se suman al hacer check-in (50 puntos por defecto)
- **Nivel**: Se calcula automáticamente (cada 300 puntos = 1 nivel)
- **Check-ins**: Registro de visitas a puntos termales (vinculados por userId)
- **Insignias**: Medallas desbloqueadas automáticamente (ej: Primera Visita, Nivel X)

### Sincronización de datos

- **Web**: Todos los datos se guardan directamente en Firestore
- **Móvil/Desktop**: Los datos se guardan localmente en SQLite y se sincronizan con Firestore
- **Tablas SQLite principales**:
  - `users`: Información del usuario (nombre, email, passwordHash, points, level)
  - `check_ins`: Visitas registradas (userId, pointId, timestamp, points)
  - `badges`: Insignias desbloqueadas (userId, name, icon, earnedDate)

## Ejecución en web

Para ejecutar la aplicación en navegador web con mejor rendimiento:

```bash
flutter run -d chrome
```

O compilar para producción web:

```bash
flutter build web
```

## Configuración de Firebase

### Requisitos previos

1. Crear un proyecto en [Firebase Console](https://console.firebase.google.com)
2. Habilitar Firestore Database
3. Configurar las reglas de Firestore (ver sección siguiente)

### Reglas de Firestore

Para desarrollo, usar reglas permisivas en `firestore.rules`:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

⚠️ **IMPORTANTE**: Esta configuración es solo para desarrollo. Para producción, implementar autenticación Firebase y reglas más restrictivas.

## Flujo de usuario

### Registro (nuevo usuario)

1. El usuario accede a la pantalla de login
2. Selecciona pestaña "Registrarse"
3. Introduce nombre, email y contraseña
4. Sistema valida que el email no esté registrado
5. Se hashea la contraseña con SHA-256
6. Se crea el usuario en Firestore/SQLite con:
   - Puntos: 0
   - Nivel: 1
   - Insignias: ninguna
7. Se redirige automáticamente a la pantalla principal

### Inicio de sesión

1. El usuario introduce email y contraseña
2. Sistema hashea la contraseña y la valida en BD
3. Se cargan todos sus datos (puntos, nivel, insignias, check-ins)
4. Se redirige a la pantalla principal

### Realizar check-in

1. Usuario abre el mapa o la lista de puntos termales
2. Selecciona un punto y pulsa "Ver detalles"
3. Pulsa "Hacer Check-in"
4. Sistema registra el check-in en BD (vinculado a userId)
5. Se suman 50 puntos automáticamente
6. Si es el primer check-in, se desbloquea insignia "Primera Visita"
7. Los datos se actualizan en tiempo real en el perfil

### Cierre de sesión

1. Usuario abre el perfil (pestaña inferior)
2. Pulsa botón "Cerrar sesión" (rojo, al final)
3. Confirma la acción
4. Se elimina la sesión y vuelve a la pantalla de login
