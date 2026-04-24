import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/active_qr_model.dart';

/// Servicio para validar y gestionar códigos QR
class QRService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _activeQrCollection(
    String thermalPointId, {
    bool legacy = false,
  }) {
    final rootCollection = legacy ? 'thermalPoints' : 'thermal_points';
    return _firestore
        .collection(rootCollection)
        .doc(thermalPointId)
        .collection('activeQR');
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _historyDocsWithFallback(
    String thermalPointId,
  ) async {
    Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> loadDocs(
      bool legacy,
    ) async {
      try {
        final ordered = await _activeQrCollection(thermalPointId, legacy: legacy)
            .orderBy('createdAt', descending: true)
            .get();
        return ordered.docs;
      } catch (_) {
        final raw = await _activeQrCollection(thermalPointId, legacy: legacy).get();
        return raw.docs;
      }
    }

    final primary = await loadDocs(false);

    if (primary.isNotEmpty) {
      return primary;
    }

    final legacy = await loadDocs(true);

    return legacy;
  }

  /// Obtiene el QR activo para un punto termal
  Future<ActiveQR?> getActiveQR(String thermalPointId) async {
    try {
      final docs = await _historyDocsWithFallback(thermalPointId);

      if (docs.isEmpty) {
        return null;
      }

      return ActiveQR.fromMap(docs.first.data());
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
        await _activeQrCollection(thermalPointId).doc(newQR.id).set(newQR.toMap());

      // Marcar QRs anteriores como expirados (actualizar expiresAt)
        final previousQRs = await _activeQrCollection(thermalPointId)
          .orderBy('createdAt', descending: true)
          .get();

      // Actualizar el penúltimo QR para que expire ahora
      if (previousQRs.docs.length > 1) {
        await _activeQrCollection(thermalPointId)
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
      final docs = await _historyDocsWithFallback(thermalPointId);
      final parsed = <ActiveQR>[];
      for (final doc in docs) {
        try {
          parsed.add(ActiveQR.fromMap(doc.data()));
        } catch (_) {
          // Ignora documentos antiguos/mal formados en lugar de vaciar todo el historial.
        }
      }

      parsed.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return parsed;
    } catch (_) {
      return [];
    }
  }
}
