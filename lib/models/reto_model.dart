class Reto {
  final String id;
  final String nombre;
  final String descripcion;
  final int puntosRecompensa;
  final String tipo; // diario, semanal, especial
  bool completado;

  Reto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.puntosRecompensa,
    required this.tipo,
    this.completado = false,
  });
}
