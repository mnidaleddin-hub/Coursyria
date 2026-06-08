class QuizResult {
  final String id;
  final String userId;
  final String quizId;
  final int score;
  final int totalPoints;
  final double percentage;
  final bool isPassed;
  final DateTime completedAt;
  final int timeSpent; // In seconds

  QuizResult({
    required this.id,
    required this.userId,
    required this.quizId,
    required this.score,
    required this.totalPoints,
    required this.percentage,
    required this.isPassed,
    required this.completedAt,
    required this.timeSpent,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      id: json['id'],
      userId: json['user_id'],
      quizId: json['quiz_id'],
      score: json['score'] ?? 0,
      totalPoints: json['total_points'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
      isPassed: json['is_passed'] ?? false,
      completedAt: DateTime.parse(json['completed_at']),
      timeSpent: json['time_spent'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'quiz_id': quizId,
      'score': score,
      'total_points': totalPoints,
      'percentage': percentage,
      'is_passed': isPassed,
      'completed_at': completedAt.toIso8601String(),
      'time_spent': timeSpent,
    };
  }
}
