import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa un código QR activo para un punto termal
class ActiveQR {
  final String id;
  final String thermalPointId;
  final String code; // El contenido del QR
  final DateTime createdAt;
  final DateTime expiresAt; // Expira al generar uno nuevo

  ActiveQR({
    required this.id,
    required this.thermalPointId,
    required this.code,
    required this.createdAt,
    required this.expiresAt,
  });

  /// Verifica si el QR aún es válido (no ha sido reemplazado)
  bool get isValid => DateTime.now().isBefore(expiresAt);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'thermalPointId': thermalPointId,
      'code': code,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
    };
  }

  factory ActiveQR.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value is num) {
        return DateTime.fromMillisecondsSinceEpoch(value.toInt());
      }
      if (value is String) {
        final asInt = int.tryParse(value);
        if (asInt != null) {
          return DateTime.fromMillisecondsSinceEpoch(asInt);
        }

        final asDate = DateTime.tryParse(value);
        if (asDate != null) {
          return asDate;
        }
      }

      return DateTime.now();
    }

    return ActiveQR(
      id: map['id'] as String,
      thermalPointId: map['thermalPointId'] as String,
      code: map['code'] as String,
      createdAt: parseDate(map['createdAt']),
      expiresAt: parseDate(map['expiresAt']),
    );
  }

  /// Crea un nuevo QR con código y expiry
  static ActiveQR create({
    required String thermalPointId,
    required String code,
  }) {
    final now = DateTime.now();
    return ActiveQR(
      id: 'qr_${thermalPointId}_${now.millisecondsSinceEpoch}',
      thermalPointId: thermalPointId,
      code: code,
      createdAt: now,
      // Expira cuando se genere otro (se actualiza en BD)
      expiresAt: now.add(const Duration(days: 365)), // Placeholder
    );
  }
}
