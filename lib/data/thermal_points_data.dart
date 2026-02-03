import '../models/thermal_point_model.dart';

class ThermalPointsData {
  static const String _defaultImageUrl =
      'https://images.unsplash.com/photo-1500375592092-40eb2168fd21?auto=format&fit=crop&w=1200&q=80';

  static const List<String> _defaultSafety = [
    'Respeta las normas y señalización del recinto',
    'No permanezcas demasiado tiempo en agua muy caliente',
    'Mantén hidratación y evita cambios bruscos de temperatura',
  ];

  static String _mapType(String type) {
    switch (type) {
      case 'manantial':
        return 'fountain';
      case 'piscina_publica':
        return 'pool';
      case 'balneario':
        return 'spa';
      case 'sitio_historico':
        return 'fountain';
      default:
        return 'pool';
    }
  }

  static List<String> _defaultProperties(String mappedType) {
    switch (mappedType) {
      case 'fountain':
        return ['Mineral', 'Temperatura alta', 'Histórico'];
      case 'spa':
        return ['Terapéutica', 'Relajante', 'Servicios completos'];
      case 'pool':
      default:
        return ['Natural', 'Relajante', 'Mineral'];
    }
  }

  static ThermalPoint _buildPoint({
    required String id,
    required String name,
    required String description,
    required double latitude,
    required double longitude,
    required double temperature,
    required String type,
    List<String>? facilities,
    String? openingHours,
    String? price,
    String? address,
    String? imageUrl,
    String? accessibility,
    List<String>? properties,
    List<String>? safety,
  }) {
    final mappedType = _mapType(type);
    return ThermalPoint(
      id: id,
      name: name,
      description: description,
      type: mappedType,
      temperature: temperature,
      address: address ?? 'Provincia de Ourense',
      latitude: latitude,
      longitude: longitude,
      imageUrl: imageUrl ?? _defaultImageUrl,
      price: price,
      openingHours: openingHours,
      accessibility: accessibility ?? 'estandar',
      properties: properties ?? (facilities ?? _defaultProperties(mappedType)),
      safety: safety ?? _defaultSafety,
    );
  }

  static List<ThermalPoint> getThermalPoints() {
    return [
      // CENTRO DE OURENSE
      _buildPoint(
        id: 'burgas_1',
        name: 'As Burgas',
        description: 'Manantial termal histórico en el corazón de Ourense, con aguas que brotan a 67°C. Monumento histórico-artístico con tres fuentes principales.',
        latitude: 42.3403,
        longitude: -7.8639,
        temperature: 67.0,
        type: 'manantial',
        facilities: ['Acceso gratuito', 'Centro histórico', 'Zona peatonal'],
        openingHours: '24 horas',
        price: 'Gratis',
      ),
      
      _buildPoint(
        id: 'burga_muiño',
        name: 'Burga do Muiño',
        description: 'Situada junto al río Barbaña, esta terma pública ofrece pozas al aire libre con vistas naturales.',
        latitude: 42.3389,
        longitude: -7.8651,
        temperature: 60.0,
        type: 'piscina_publica',
        facilities: ['Acceso gratuito', 'Pozas al aire libre', 'Vestuarios'],
        openingHours: '24 horas',
        price: 'Gratis',
      ),

      // RÍO MIÑO
      _buildPoint(
        id: 'outariz',
        name: 'Termas de Outariz',
        description: 'Complejo termal moderno junto al río Miño con piscinas de diferentes temperaturas y zona de spa.',
        latitude: 42.3278,
        longitude: -7.8819,
        temperature: 41.0,
        type: 'balneario',
        facilities: ['Piscinas termales', 'Jacuzzi', 'Sauna', 'Vestuarios', 'Parking'],
        openingHours: '10:00 - 22:00',
        price: '3-5€',
      ),

      _buildPoint(
        id: 'chavasqueira',
        name: 'Termas de Chavasqueira',
        description: 'Pozas termales naturales junto al Miño, muy populares entre locales y turistas. Ambiente relajado y familiar.',
        latitude: 42.3256,
        longitude: -7.8897,
        temperature: 40.0,
        type: 'piscina_publica',
        facilities: ['Acceso gratuito', 'Pozas naturales', 'Vestuarios', 'Área recreativa'],
        openingHours: '24 horas',
        price: 'Gratis',
      ),

      _buildPoint(
        id: 'muiño_vella',
        name: 'Termas da Muiño da Vella',
        description: 'Piscina termal pública en un entorno natural privilegiado junto al río Miño.',
        latitude: 42.3245,
        longitude: -7.8935,
        temperature: 39.0,
        type: 'piscina_publica',
        facilities: ['Acceso gratuito', 'Piscina termal', 'Vestuarios'],
        openingHours: '24 horas',
        price: 'Gratis',
      ),

      _buildPoint(
        id: 'reza',
        name: 'Termas da Reza',
        description: 'Instalación termal con pozas al aire libre en un entorno natural junto al río.',
        latitude: 42.3198,
        longitude: -7.9012,
        temperature: 38.0,
        type: 'piscina_publica',
        facilities: ['Acceso gratuito', 'Pozas termales', 'Vestuarios', 'Parking'],
        openingHours: '24 horas',
        price: 'Gratis',
      ),

      // PROVINCIA DE OURENSE - BALNEARIOS
      _buildPoint(
        id: 'laias',
        name: 'Balneario de Laias',
        description: 'Histórico balneario con aguas minero-medicinales, spa completo y hotel. Situado en Cenlle.',
        latitude: 42.3678,
        longitude: -8.1234,
        temperature: 48.0,
        type: 'balneario',
        facilities: ['Hotel', 'Spa', 'Restaurante', 'Piscinas termales', 'Tratamientos'],
        openingHours: '9:00 - 21:00',
        price: '15-50€',
      ),

      _buildPoint(
        id: 'arnoia',
        name: 'Balneario de Arnoia',
        description: 'Balneario tradicional en el valle del Arnoia, conocido por sus aguas medicinales y tratamientos.',
        latitude: 42.2145,
        longitude: -8.1567,
        temperature: 52.0,
        type: 'balneario',
        facilities: ['Hotel', 'Spa', 'Piscinas', 'Tratamientos medicinales', 'Restaurante'],
        openingHours: '9:00 - 20:00',
        price: '20-60€',
      ),

      _buildPoint(
        id: 'carballino',
        name: 'Balneario de O Carballiño',
        description: 'Moderno balneario con aguas sulfuradas y tratamientos de salud y belleza.',
        latitude: 42.4289,
        longitude: -8.0789,
        temperature: 45.0,
        type: 'balneario',
        facilities: ['Spa', 'Piscinas termales', 'Gimnasio', 'Tratamientos', 'Cafetería'],
        openingHours: '10:00 - 21:00',
        price: '12-45€',
      ),

      _buildPoint(
        id: 'cortegada',
        name: 'Balneario de Cortegada',
        description: 'Balneario familiar en entorno rural con aguas medicinales y zona de relax.',
        latitude: 42.4156,
        longitude: -8.1423,
        temperature: 46.0,
        type: 'balneario',
        facilities: ['Piscinas', 'Tratamientos', 'Zona de relax', 'Cafetería', 'Parking'],
        openingHours: '10:00 - 20:00',
        price: '10-35€',
      ),

      _buildPoint(
        id: 'lobios',
        name: 'Balneario de Lobios',
        description: 'Moderno complejo termal en el Parque Natural Baixa Limia-Serra do Xurés, con hotel y spa.',
        latitude: 41.8756,
        longitude: -8.0923,
        temperature: 76.0,
        type: 'balneario',
        facilities: ['Hotel 5*', 'Spa luxury', 'Piscinas termales', 'Restaurante gourmet', 'Golf'],
        openingHours: '9:00 - 22:00',
        price: '25-80€',
      ),

      _buildPoint(
        id: 'bande',
        name: 'Termas de Bande',
        description: 'Aguas termales naturales cerca del embalse de As Conchas, en entorno natural privilegiado.',
        latitude: 42.0289,
        longitude: -7.9734,
        temperature: 42.0,
        type: 'piscina_publica',
        facilities: ['Acceso gratuito', 'Pozas naturales', 'Área recreativa', 'Parking'],
        openingHours: '24 horas',
        price: 'Gratis',
      ),

      // RÍO SIL
      _buildPoint(
        id: 'mondariz',
        name: 'Balneario de Mondariz',
        description: 'Prestigioso balneario modernista con más de 150 años de historia, spa de lujo y hotel.',
        latitude: 42.2334,
        longitude: -8.4623,
        temperature: 47.0,
        type: 'balneario',
        facilities: ['Hotel 4*', 'Spa premium', 'Piscinas', 'Tratamientos', 'Restaurante', 'Jardines'],
        openingHours: '9:00 - 21:00',
        price: '30-90€',
      ),

      _buildPoint(
        id: 'prexigueiro',
        name: 'Termas de Prexigueiro',
        description: 'Piscinas termales públicas en Ribadavia, junto al río Avia.',
        latitude: 42.2889,
        longitude: -8.1378,
        temperature: 40.0,
        type: 'piscina_publica',
        facilities: ['Acceso gratuito', 'Piscinas termales', 'Vestuarios', 'Parking'],
        openingHours: '10:00 - 20:00 (verano)',
        price: 'Gratis',
      ),

      _buildPoint(
        id: 'partovia',
        name: 'Balneario de Partovia',
        description: 'Balneario histórico en O Carballiño, conocido por sus aguas medicinales sulfuradas.',
        latitude: 42.4334,
        longitude: -8.0656,
        temperature: 49.0,
        type: 'balneario',
        facilities: ['Spa', 'Piscinas termales', 'Tratamientos', 'Cafetería', 'Jardines'],
        openingHours: '10:00 - 20:00',
        price: '15-40€',
      ),

      // RIBEIRA SACRA
      _buildPoint(
        id: 'aquis_querquennis',
        name: 'Aquis Querquennis',
        description: 'Antigua estación termal romana junto al campamento de Aquis Querquennis en Bande.',
        latitude: 42.0445,
        longitude: -7.9523,
        temperature: 41.0,
        type: 'sitio_historico',
        facilities: ['Ruinas romanas', 'Centro interpretación', 'Parking', 'Área recreativa'],
        openingHours: '10:00 - 18:00',
        price: '3€',
      ),

      _buildPoint(
        id: 'cacabelos',
        name: 'Termas de Cacabelos',
        description: 'Pequeñas termas rurales en el Bierzo ourensano con aguas naturales.',
        latitude: 42.0789,
        longitude: -7.8934,
        temperature: 38.0,
        type: 'piscina_publica',
        facilities: ['Acceso gratuito', 'Pozas naturales', 'Entorno rural'],
        openingHours: '24 horas',
        price: 'Gratis',
      ),

      // TERMAS RURALES
      _buildPoint(
        id: 'berducedo',
        name: 'Termas de Berducedo',
        description: 'Piscina termal en entorno rural de montaña, en la comarca de A Limia.',
        latitude: 42.0956,
        longitude: -7.8456,
        temperature: 37.0,
        type: 'piscina_publica',
        facilities: ['Acceso gratuito', 'Piscina termal', 'Vestuarios básicos'],
        openingHours: '24 horas',
        price: 'Gratis',
      ),

      _buildPoint(
        id: 'riocaldo',
        name: 'Termas de Riocaldo',
        description: 'Pozas termales naturales en Lobios, junto al río Caldo, en entorno de montaña.',
        latitude: 41.9123,
        longitude: -8.1034,
        temperature: 68.0,
        type: 'piscina_publica',
        facilities: ['Acceso gratuito', 'Pozas naturales', 'Entorno natural', 'Senderismo'],
        openingHours: '24 horas',
        price: 'Gratis',
      ),

      _buildPoint(
        id: 'caldas_partovia',
        name: 'Caldas de Partovia',
        description: 'Manantial termal histórico con propiedades medicinales en O Carballiño.',
        latitude: 42.4289,
        longitude: -8.0723,
        temperature: 50.0,
        type: 'manantial',
        facilities: ['Manantial histórico', 'Zona de paseo', 'Parking'],
        openingHours: '24 horas',
        price: 'Gratis',
      ),

      _buildPoint(
        id: 'tintores',
        name: 'Termas de Tintores',
        description: 'Pequeñas termas en la parroquia de Tintores, conocidas por sus aguas ferrosas.',
        latitude: 42.3567,
        longitude: -8.0234,
        temperature: 39.0,
        type: 'piscina_publica',
        facilities: ['Acceso gratuito', 'Poza termal', 'Entorno rural'],
        openingHours: '24 horas',
        price: 'Gratis',
      ),
    ];
  }
}
