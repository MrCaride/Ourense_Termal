import 'dart:html' as html;

Future<bool> requestWebCameraPermission() async {
  try {
    final mediaDevices = html.window.navigator.mediaDevices;
    if (mediaDevices == null) {
      print('mediaDevices no disponible en este navegador');
      return false;
    }

    // Solicitar acceso a cámara
    try {
      final stream = await mediaDevices.getUserMedia({'video': true});

      // Cerrar inmediatamente tras obtener permiso
      for (final track in stream.getTracks()) {
        track.stop();
      }

      print('Permiso de cámara concedido correctamente');
      return true;
    } catch (permError) {
      print('Error al solicitar permiso: $permError');
      return false;
    }
  } catch (e) {
    print('Error crítico en requestWebCameraPermission: $e');
    return false;
  }
}
