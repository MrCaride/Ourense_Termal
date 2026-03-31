
class BadgesData {
  static List<BadgeDefinition> getBadgeDefinitions() {
    return [
      // INSIGNIAS DE INICIACIÓN
      BadgeDefinition(
        id: 'badge_first_visit',
        name: 'Primera Inmersión',
        description: 'Visita tu primera terma',
        icon: '💧',
        requirement: BadgeRequirement.checkInsCount,
        requiredValue: 1,
        points: 50,
      ),

      BadgeDefinition(
        id: 'badge_burgas',
        name: 'Guardián de As Burgas',
        description: 'Visita el icónico manantial de As Burgas',
        icon: '⛲',
        requirement: BadgeRequirement.specificPoint,
        requiredPointId: 'burgas_1',
        points: 100,
      ),

      BadgeDefinition(
        id: 'badge_mino_explorer',
        name: 'Explorador del Miño',
        description: 'Visita 3 termas del río Miño',
        icon: '🌊',
        requirement: BadgeRequirement.checkInsCount,
        requiredValue: 3,
        points: 150,
      ),

      // INSIGNIAS POR CANTIDAD DE VISITAS
      BadgeDefinition(
        id: 'badge_5_visits',
        name: 'Aficionado Termal',
        description: 'Visita 5 termas diferentes',
        icon: '🎯',
        requirement: BadgeRequirement.checkInsCount,
        requiredValue: 5,
        points: 200,
      ),

      BadgeDefinition(
        id: 'badge_10_visits',
        name: 'Entusiasta del Agua',
        description: 'Visita 10 termas diferentes',
        icon: '🏆',
        requirement: BadgeRequirement.checkInsCount,
        requiredValue: 10,
        points: 400,
      ),

      BadgeDefinition(
        id: 'badge_15_visits',
        name: 'Maestro Termal',
        description: 'Visita 15 termas diferentes',
        icon: '👑',
        requirement: BadgeRequirement.checkInsCount,
        requiredValue: 15,
        points: 600,
      ),

      BadgeDefinition(
        id: 'badge_20_visits',
        name: 'Leyenda de Ourense',
        description: 'Visita 20 termas diferentes - ¡Casi todas!',
        icon: '⭐',
        requirement: BadgeRequirement.checkInsCount,
        requiredValue: 20,
        points: 1000,
      ),

      // INSIGNIAS POR TIPO DE TERMA
      BadgeDefinition(
        id: 'badge_free_thermal',
        name: 'Cazador de Tesoros Gratuitos',
        description: 'Visita 5 termas de acceso gratuito',
        icon: '🎁',
        requirement: BadgeRequirement.freePointsCount,
        requiredValue: 5,
        points: 250,
      ),

      BadgeDefinition(
        id: 'badge_spa_lover',
        name: 'Amante del Spa',
        description: 'Visita 3 balnearios o spas premium',
        icon: '💎',
        requirement: BadgeRequirement.premiumPointsCount,
        requiredValue: 3,
        points: 300,
      ),

      BadgeDefinition(
        id: 'badge_natural_pools',
        name: 'Naturalista Termal',
        description: 'Visita 4 pozas termales naturales',
        icon: '🏞️',
        requirement: BadgeRequirement.naturalPoolsCount,
        requiredValue: 4,
        points: 250,
      ),

      // INSIGNIAS POR RUTAS
      BadgeDefinition(
        id: 'badge_first_route',
        name: 'Caminante Termal',
        description: 'Completa tu primera ruta termal',
        icon: '🚶',
        requirement: BadgeRequirement.routesCompleted,
        requiredValue: 1,
        points: 200,
      ),

      BadgeDefinition(
        id: 'badge_3_routes',
        name: 'Explorador de Rutas',
        description: 'Completa 3 rutas termales',
        icon: '🗺️',
        requirement: BadgeRequirement.routesCompleted,
        requiredValue: 3,
        points: 400,
      ),

      BadgeDefinition(
        id: 'badge_5_routes',
        name: 'Maestro de Caminos',
        description: 'Completa 5 rutas termales',
        icon: '🎖️',
        requirement: BadgeRequirement.routesCompleted,
        requiredValue: 5,
        points: 700,
      ),

      BadgeDefinition(
        id: 'badge_all_routes',
        name: 'Conquistador Total',
        description: 'Completa todas las rutas disponibles',
        icon: '🏅',
        requirement: BadgeRequirement.routesCompleted,
        requiredValue: 12,
        points: 1500,
      ),

      // INSIGNIAS TEMÁTICAS
      BadgeDefinition(
        id: 'badge_roman',
        name: 'Heredero Romano',
        description: 'Visita Aquis Querquennis y As Burgas',
        icon: '🏛️',
        requirement: BadgeRequirement.specificPoints,
        requiredPointIds: ['burgas_1', 'aquis_querquennis'],
        points: 300,
      ),

      BadgeDefinition(
        id: 'badge_luxury',
        name: 'VIP Termal',
        description: 'Visita los 3 balnearios más lujosos',
        icon: '💫',
        requirement: BadgeRequirement.specificPoints,
        requiredPointIds: ['lobios', 'mondariz', 'laias'],
        points: 500,
      ),

      BadgeDefinition(
        id: 'badge_urban',
        name: 'Urbanita Termal',
        description: 'Visita todas las termas del centro de Ourense',
        icon: '🏙️',
        requirement: BadgeRequirement.specificPoints,
        requiredPointIds: ['burgas_1', 'burga_muiño', 'outariz', 'chavasqueira', 'muiño_vella', 'reza'],
        points: 400,
      ),

      BadgeDefinition(
        id: 'badge_mountain',
        name: 'Montañero de Agua',
        description: 'Visita las termas de alta montaña',
        icon: '⛰️',
        requirement: BadgeRequirement.specificPoints,
        requiredPointIds: ['lobios', 'riocaldo', 'berducedo'],
        points: 450,
      ),

      // INSIGNIAS POR TEMPERATURA
      BadgeDefinition(
        id: 'badge_hot_water',
        name: 'Amante del Calor Extremo',
        description: 'Visita 3 termas con más de 60°C',
        icon: '🔥',
        requirement: BadgeRequirement.highTempPoints,
        requiredValue: 3,
        points: 350,
      ),

      BadgeDefinition(
        id: 'badge_mild_water',
        name: 'Relajación Templada',
        description: 'Visita 5 termas con temperatura moderada (35-45°C)',
        icon: '🌡️',
        requirement: BadgeRequirement.mildTempPoints,
        requiredValue: 5,
        points: 250,
      ),

      // INSIGNIAS SOCIALES
      BadgeDefinition(
        id: 'badge_early_bird',
        name: 'Madrugador Termal',
        description: 'Realiza 5 check-ins antes de las 9:00',
        icon: '🌅',
        requirement: BadgeRequirement.earlyCheckIns,
        requiredValue: 5,
        points: 200,
      ),

      BadgeDefinition(
        id: 'badge_night_owl',
        name: 'Búho Nocturno',
        description: 'Realiza 5 check-ins después de las 20:00',
        icon: '🦉',
        requirement: BadgeRequirement.lateCheckIns,
        requiredValue: 5,
        points: 200,
      ),

      BadgeDefinition(
        id: 'badge_weekend_warrior',
        name: 'Guerrero del Fin de Semana',
        description: 'Visita 10 termas en fines de semana',
        icon: '🎉',
        requirement: BadgeRequirement.weekendCheckIns,
        requiredValue: 10,
        points: 300,
      ),

      BadgeDefinition(
        id: 'badge_consecutive',
        name: 'Racha Termal',
        description: 'Visita termas durante 7 días consecutivos',
        icon: '📅',
        requirement: BadgeRequirement.consecutiveDays,
        requiredValue: 7,
        points: 400,
      ),

      // INSIGNIAS DE TEMPORADA
      BadgeDefinition(
        id: 'badge_winter',
        name: 'Valiente del Invierno',
        description: 'Visita 5 termas en invierno',
        icon: '❄️',
        requirement: BadgeRequirement.seasonalCheckIns,
        requiredSeason: 'winter',
        requiredValue: 5,
        points: 350,
      ),

      BadgeDefinition(
        id: 'badge_summer',
        name: 'Explorador de Verano',
        description: 'Visita 5 termas en verano',
        icon: '☀️',
        requirement: BadgeRequirement.seasonalCheckIns,
        requiredSeason: 'summer',
        requiredValue: 5,
        points: 250,
      ),

      // INSIGNIAS DE DISTANCIA
      BadgeDefinition(
        id: 'badge_traveler',
        name: 'Gran Viajero',
        description: 'Recorre más de 100 km visitando termas',
        icon: '🚗',
        requirement: BadgeRequirement.totalDistance,
        requiredValue: 100,
        points: 500,
      ),

      BadgeDefinition(
        id: 'badge_marathon',
        name: 'Maratoniano Termal',
        description: 'Recorre más de 200 km visitando termas',
        icon: '🏃',
        requirement: BadgeRequirement.totalDistance,
        requiredValue: 200,
        points: 800,
      ),

      // INSIGNIA MÁXIMA
      BadgeDefinition(
        id: 'badge_master',
        name: 'Gran Maestro Termal de Ourense',
        description: 'Visita TODAS las termas de la provincia',
        icon: '👑💎',
        requirement: BadgeRequirement.allPointsVisited,
        requiredValue: 1,
        points: 2000,
      ),
    ];
  }
}

enum BadgeRequirement {
  checkInsCount,
  specificPoint,
  specificPoints,
  routesCompleted,
  freePointsCount,
  premiumPointsCount,
  naturalPoolsCount,
  highTempPoints,
  mildTempPoints,
  earlyCheckIns,
  lateCheckIns,
  weekendCheckIns,
  consecutiveDays,
  seasonalCheckIns,
  totalDistance,
  allPointsVisited,
}

class BadgeDefinition {
  final String id;
  final String name;
  final String description;
  final String icon;
  final BadgeRequirement requirement;
  final int requiredValue;
  final String? requiredPointId;
  final List<String>? requiredPointIds;
  final String? requiredSeason;
  final int points;

  BadgeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.requirement,
    this.requiredValue = 0,
    this.requiredPointId,
    this.requiredPointIds,
    this.requiredSeason,
    required this.points,
  });
}
