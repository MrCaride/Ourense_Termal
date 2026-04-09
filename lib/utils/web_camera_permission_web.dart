import 'dart:html' as html;

Future<bool> requestWebCameraPermission() async {
  try {
    final mediaDevices = html.window.navigator.mediaDevices;
    if (mediaDevices == null) {
      return false;
    }

    // Solicitar acceso a cámara
    try {
      final stream = await mediaDevices.getUserMedia({'video': true});

      // Cerrar inmediatamente tras obtener permiso
      for (final track in stream.getTracks()) {
        track.stop();
      }

      return true;
    } catch (_) {
      return false;
    }
  } catch (_) {
    return false;
  }
}
