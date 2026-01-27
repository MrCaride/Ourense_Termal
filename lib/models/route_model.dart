class Route {
  final String id;
  final String name;
  final String description;
  final String theme;
  final String type; // 'walking', 'driving', 'mixed'
  final String difficulty; // 'easy', 'moderate', 'hard'
  final double distance; // en km
  final String duration; // ej: "2h 30min"
  final List<String> thermalPointIds;
  final int points;

  Route({
    required this.id,
    required this.name,
    required this.description,
    required this.theme,
    required this.type,
    required this.difficulty,
    required this.distance,
    required this.duration,
    required this.thermalPointIds,
    required this.points,
  });

  String getDifficultyLabel() {
    switch (difficulty) {
      case 'easy':
        return 'Fácil';
      case 'moderate':
        return 'Moderado';
      case 'hard':
        return 'Difícil';
      default:
        return difficulty;
    }
  }
}
