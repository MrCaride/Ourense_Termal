class ThermalPoint {
  final String id;
  final String name;
  final String description;
  final String type; // 'fountain', 'pool', 'spa'
  final double temperature;
  final String address;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final String? price;
  final String? openingHours;
  final String accessibility; // 'high', 'medium', 'low'
  final List<String> properties; // propiedades del agua
  final List<String> safety; // consejos de seguridad

  ThermalPoint({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.temperature,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    this.price,
    this.openingHours,
    required this.accessibility,
    required this.properties,
    required this.safety,
  });

  String getTypeLabel() {
    switch (type) {
      case 'fountain':
        return 'Fuente Termal';
      case 'pool':
        return 'Poza Termal';
      case 'spa':
        return 'Balneario / Spa';
      default:
        return type;
    }
  }
}

class CheckIn {
  final String id;
  final String pointId;
  final DateTime timestamp;
  final int points;

  CheckIn({
    required this.id,
    required this.pointId,
    required this.timestamp,
    this.points = 50,
  });
}
