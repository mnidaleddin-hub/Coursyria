class QuizQuestion {
  final String id;
  final String quizId;
  final String questionText;
  final String questionType; // 'multiple_choice', 'true_false'
  final List<String> options;
  final String correctAnswer;
  final int points;
  final int orderIndex;
  final String? explanation;

  QuizQuestion({
    required this.id,
    required this.quizId,
    required this.questionText,
    required this.questionType,
    required this.options,
    required this.correctAnswer,
    required this.points,
    required this.orderIndex,
    this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'],
      quizId: json['quiz_id'],
      questionText: json['question_text'],
      questionType: json['question_type'] ?? 'multiple_choice',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correct_answer'],
      points: json['points'] ?? 10,
      orderIndex: json['order_index'] ?? 0,
      explanation: json['explanation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quiz_id': quizId,
      'question_text': questionText,
      'question_type': questionType,
      'options': options,
      'correct_answer': correctAnswer,
      'points': points,
      'order_index': orderIndex,
      'explanation': explanation,
    };
  }
}
