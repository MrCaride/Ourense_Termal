import 'package:cloud_firestore/cloud_firestore.dart';

class UserRouteProgress {
  final String id; // userId_routeId
  final String userId;
  final String routeId;
  final double progress; // 0.0 a 100.0
  final bool isCompleted;
  final List<String> completedPointIds; // IDs de puntos termales visitados en esta ruta
  final DateTime lastUpdated;
  final DateTime? completedAt;

  UserRouteProgress({
    required this.id,
    required this.userId,
    required this.routeId,
    required this.progress,
    required this.isCompleted,
    required this.completedPointIds,
    required this.lastUpdated,
    this.completedAt,
  });

  // Calcular progreso basado en puntos visitados
  static double calculateProgress(int completedPoints, int totalPoints) {
    if (totalPoints == 0) return 0.0;
    return (completedPoints / totalPoints * 100).clamp(0.0, 100.0);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'routeId': routeId,
      'progress': progress,
      'isCompleted': isCompleted,
      'completedPointIds': completedPointIds,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'routeId': routeId,
      'progress': progress,
      'isCompleted': isCompleted,
      'completedPointIds': completedPointIds,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  factory UserRouteProgress.fromMap(Map<String, dynamic> map) {
    return UserRouteProgress(
      id: map['id'] as String,
      userId: map['userId'] as String,
      routeId: map['routeId'] as String,
      progress: (map['progress'] as num).toDouble(),
      isCompleted: map['isCompleted'] == 1 || map['isCompleted'] == true,
      completedPointIds: (map['completedPointIds'] as String).split(',').where((s) => s.isNotEmpty).toList(),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'] as int),
      completedAt: map['completedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'] as int)
          : null,
    );
  }

  factory UserRouteProgress.fromFirestore(String docId, Map<String, dynamic> data) {
    return UserRouteProgress(
      id: docId,
      userId: data['userId'] as String,
      routeId: data['routeId'] as String,
      progress: (data['progress'] as num).toDouble(),
      isCompleted: data['isCompleted'] as bool,
      completedPointIds: List<String>.from(data['completedPointIds'] as List),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null 
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  UserRouteProgress copyWith({
    String? id,
    String? userId,
    String? routeId,
    double? progress,
    bool? isCompleted,
    List<String>? completedPointIds,
    DateTime? lastUpdated,
    DateTime? completedAt,
  }) {
    return UserRouteProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      routeId: routeId ?? this.routeId,
      progress: progress ?? this.progress,
      isCompleted: isCompleted ?? this.isCompleted,
      completedPointIds: completedPointIds ?? this.completedPointIds,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
