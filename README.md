# Ourense Termal 

Aplicación móvil gamificada para incentivar el turismo termal en la provincia de Ourense, Galicia.

## Descripción

Ourense Termal es una aplicación desarrollada en Flutter que permite a los usuarios descubrir y visitar puntos termales en Ourense mediante un sistema de gamificación. Los usuarios pueden hacer check-in en diferentes ubicaciones, completar rutas temáticas, ganar puntos y desbloquear insignias.

## Características principales

- **Autenticación híbrida**: Firebase Auth + perfil en Firestore + sesión local con SharedPreferences
- **Mapa interactivo**: Visualización de todos los puntos termales usando OpenStreetMap
- **Sistema de check-in por QR**: Validación de códigos QR activos y recompensas (50 puntos por check-in)
- **Rutas temáticas**: Diferentes rutas para descubrir múltiples puntos termales
- **Sistema de niveles**: Progresión del usuario desde Novato Termal hasta Termal Master (cada 300 puntos = 1 nivel)
- **Insignias y logros**: Desbloqueo automático de medallas por logros (ej: "Primera Visita", "Nivel X Alcanzado")
- **Perfil de usuario**: Seguimiento de puntos, visitas, insignias y nivel conseguidos
- **Roles de usuario**: Usuario, gerente termal y administrador con navegación por rol
- **Panel de administración**: Gestión de puntos termales, usuarios, recompensas y QR
- **Sincronización multiplataforma**: Firestore en web y modelo offline-first con SQLite en móvil/desktop

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
- `firebase_core`, `firebase_auth`, `cloud_firestore`: Backend y autenticación en la nube
- `sqflite` + `sqflite_common_ffi`: Base de datos local para móvil/desktop
- `crypto`: Hashing seguro de contraseñas con SHA-256
- `shared_preferences`: Persistencia de sesión local
- `mobile_scanner` y `qr_flutter`: Escaneo y generación de códigos QR
- Material Design 3: Sistema de diseño de la aplicación

## Arquitectura

### Estructura de carpetas

```
lib/
├── components/          # Componentes UI reutilizables
├── data/                # Datos estáticos (rutas, recompensas, puntos termales)
├── models/              # Modelos de datos (User, ThermalPoint, CheckIn, etc.)
├── screens/             # Pantallas de la aplicación (Login, Home, Map, Profile, etc.)
├── services/            # Servicios de negocio
│   ├── auth_service.dart        # Autenticación (login/registro)
│   ├── user_data_service.dart   # Gestión de datos del usuario
│   ├── database_service.dart    # Acceso a base de datos SQLite
│   ├── sync_service.dart        # Sincronización con Firestore
│   ├── route_service.dart       # Progreso y lógica de rutas
│   ├── reward_service.dart      # Canje y gestión de recompensas
│   └── qr_service.dart          # Validación y gestión de QR
├── theme/               # Sistema de diseño (colores, tipografías, espaciado)
├── widgets/             # Navegación y widgets compartidos
├── utils/               # Funciones auxiliares
└── main.dart            # Punto de entrada de la aplicación
```

### Flujo de autenticación

1. **Login/Registro**: El usuario introduce sus credenciales
2. **Registro en Firebase Auth**: Se crea/valida identidad con email y contraseña
3. **Perfil de usuario**: Se crea/carga el documento del usuario en Firestore
4. **Persistencia local**: Se guarda sesión en SharedPreferences y, en móvil/desktop, también copia local SQLite
5. **Inicio por rol**: El usuario entra a Home, Thermal Manager o Admin según su rol
6. **Logout**: Se limpia la sesión local y se cierra sesión de Firebase

### Vinculación de datos al usuario

Cada usuario tiene sus propios datos asociados:
- **Puntos**: Se suman al hacer check-in (50 puntos por defecto)
- **Nivel**: Se calcula automáticamente (cada 300 puntos = 1 nivel)
- **Check-ins**: Registro de visitas a puntos termales (vinculados por userId)
- **Insignias**: Medallas desbloqueadas automáticamente (ej: Primera Visita, Nivel X)
- **Progreso de rutas**: Avance por ruta y puntos completados por usuario
- **Recompensas canjeadas**: Historial de cupones y estado de uso

### Sincronización de datos

- **Web**: Flujo directo contra Firestore (sin SQLite)
- **Móvil/Desktop**: Flujo offline-first con SQLite + sincronización bidireccional a Firestore
- **Resolución de conflictos**: Prioridad por timestamp de actualización más reciente
- **Tablas SQLite principales**:
  - `users`: Información del usuario (nombre, email, passwordHash, points, level)
  - `check_ins`: Visitas registradas (userId, pointId, timestamp, points)
  - `badges`: Insignias desbloqueadas (userId, name, icon, earnedDate)
  - `thermal_points`: Catálogo local de puntos termales
  - `user_route_progress`: Progreso de rutas por usuario
  - `user_redeemed_rewards`: Recompensas canjeadas por usuario

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

## Flujo de usuario

### Registro (nuevo usuario)

1. El usuario accede a la pantalla de login
2. Selecciona pestaña "Registrarse"
3. Introduce nombre, email y contraseña
4. Sistema valida formato y fortalezas mínimas
5. Se crea la cuenta en Firebase Auth
6. Se crea el perfil de usuario en Firestore (y SQLite en móvil/desktop) con:
    - Puntos: 0
    - Nivel: 1
    - Rol inicial: `user` (por defecto)
    - Insignias: ninguna
7. Se redirige automáticamente a la pantalla correspondiente por rol

### Inicio de sesión

1. El usuario introduce email y contraseña
2. Se valida credencial contra Firebase Auth
3. En móvil/desktop, si hay datos locales válidos puede iniciar sesión en modo offline
4. Se cargan datos de perfil, puntos, insignias y check-ins
5. Se redirige a la pantalla correspondiente por rol

### Realizar check-in

1. Usuario abre el mapa o la lista de puntos termales
2. Selecciona un punto y pulsa "Ver detalles"
3. Pulsa "Hacer Check-in" y valida QR del punto
4. Sistema verifica que el QR sea válido y corresponda al punto seleccionado
5. Se registra el check-in en BD (vinculado a userId)
6. Se suman 50 puntos automáticamente
7. Si es el primer check-in, se desbloquea insignia "Primera Visita"
8. Se actualiza también el progreso de rutas relacionadas
9. Los datos se reflejan en perfil y progreso

### Cierre de sesión

1. Usuario abre el perfil (pestaña inferior)
2. Pulsa botón "Cerrar sesión" (rojo, al final)
3. Confirma la acción
4. Se elimina la sesión y vuelve a la pantalla de login
