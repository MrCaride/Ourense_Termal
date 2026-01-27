class Ruta {
  final String id;
  final String nombre;
  final String descripcion;
  final List<String> puntosTermalesIds;
  final int duracionEstimada; // en minutos
  final int distancia; // en km
  final int dificultad; // 1-5
  final int puntosRecompensa;
  bool completada;

  Ruta({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.puntosTermalesIds,
    required this.duracionEstimada,
    required this.distancia,
    required this.dificultad,
    required this.puntosRecompensa,
    this.completada = false,
  });
}
