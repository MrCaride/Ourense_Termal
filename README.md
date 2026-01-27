# Ourense Termal

Aplicación móvil gamificada para incentivar el turismo termal en la provincia de Ourense, Galicia.

## Descripción

Ourense Termal es una aplicación desarrollada en Flutter que permite a los usuarios descubrir y visitar puntos termales en Ourense mediante un sistema de gamificación. Los usuarios pueden hacer check-in en diferentes ubicaciones, completar rutas temáticas, ganar puntos y desbloquear insignias.

## Características principales

- **Mapa interactivo**: Visualización de todos los puntos termales usando OpenStreetMap
- **Sistema de check-in**: Registro de visitas a puntos termales con recompensas
- **Rutas temáticas**: Diferentes rutas para descubrir múltiples puntos termales
- **Sistema de niveles**: Progresión del usuario desde Novato Termal hasta Termal Master
- **Insignias y logros**: Desbloqueo de medallas por completar objetivos
- **Perfil de usuario**: Seguimiento de puntos, visitas e insignias conseguidas

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
- Material Design 3: Sistema de diseño de la aplicación

## Arquitectura

## Ejecución en web

Para ejecutar la aplicación en navegador web con mejor rendimiento:

```bash
flutter run -d chrome
```

O compilar para producción web:

```bash
flutter build web
```

## Estado actual del desarrollo

