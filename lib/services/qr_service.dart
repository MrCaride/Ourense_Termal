import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/active_qr_model.dart';

/// Servicio para validar y gestionar códigos QR
class QRService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Obtiene el QR activo para un punto termal
  Future<ActiveQR?> getActiveQR(String thermalPointId) async {
    try {
      final doc = await _firestore
          .collection('thermalPoints')
          .doc(thermalPointId)
          .collection('activeQR')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (doc.docs.isEmpty) {
        return null;
      }

      return ActiveQR.fromMap(doc.docs.first.data());
    } catch (_) {
      return null;
    }
  }

  /// Crea un nuevo QR para un punto termal (solo admin)
  Future<ActiveQR> generateNewQR(String thermalPointId) async {
    try {
      final now = DateTime.now();
      final qrCode =
          '$thermalPointId-${now.millisecondsSinceEpoch}'; // Código único

      final newQR = ActiveQR.create(
        thermalPointId: thermalPointId,
        code: qrCode,
      );

      // Guardar en Firestore
      await _firestore
          .collection('thermalPoints')
          .doc(thermalPointId)
          .collection('activeQR')
          .doc(newQR.id)
          .set(newQR.toMap());

      // Marcar QRs anteriores como expirados (actualizar expiresAt)
      final previousQRs = await _firestore
          .collection('thermalPoints')
          .doc(thermalPointId)
          .collection('activeQR')
          .orderBy('createdAt', descending: true)
          .get();

      // Actualizar el penúltimo QR para que expire ahora
      if (previousQRs.docs.length > 1) {
        await _firestore
            .collection('thermalPoints')
            .doc(thermalPointId)
            .collection('activeQR')
            .doc(previousQRs.docs[1].id)
            .update({
              'expiresAt': now.millisecondsSinceEpoch,
            });
      }

      return newQR;
    } catch (_) {
      rethrow;
    }
  }

  /// Valida un QR escaneado
  /// Retorna el ID del punto termal si el QR es válido, null si no
  Future<String?> validateQRCode(String scannedCode) async {
    try {
      // El código contiene el formato: thermalPointId-timestamp
      final parts = scannedCode.split('-');
      if (parts.length < 2) {
        return null;
      }

      final thermalPointId = parts[0];

      // Obtener QR activo
      final activeQR = await getActiveQR(thermalPointId);

      if (activeQR == null) {
        return null;
      }

      // Verificar si el código coincide y es válido
      if (activeQR.code == scannedCode && activeQR.isValid) {
        return thermalPointId;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Obtiene todos los QRs (actuales y anteriores) de un punto
  Future<List<ActiveQR>> getQRHistory(String thermalPointId) async {
    try {
      final docs = await _firestore
          .collection('thermalPoints')
          .doc(thermalPointId)
          .collection('activeQR')
          .orderBy('createdAt', descending: true)
          .get();

      return docs.docs.map((doc) => ActiveQR.fromMap(doc.data())).toList();
    } catch (_) {
      return [];
    }
  }
}
