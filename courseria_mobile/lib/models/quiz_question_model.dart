class QuizQuestion {
  final String id;
  final String quizId;
  final String questionText;
  final String questionType; // 'multiple_choice', 'true_false', 'essay'
  final List<String> options;
  final String correctAnswer;
  final int points;
  final int orderIndex;
  final String difficulty; // easy, medium, hard, exam
  final String skillType; // comprehension, application, analysis, synthesis
  final String? explanation;
  final String? videoExplanationUrl;
  final int? timestampStart;
  final int? timestampEnd;

  QuizQuestion({
    required this.id,
    required this.quizId,
    required this.questionText,
    required this.questionType,
    required this.options,
    required this.correctAnswer,
    required this.points,
    required this.orderIndex,
    this.difficulty = 'medium',
    this.skillType = 'comprehension',
    this.explanation,
    this.videoExplanationUrl,
    this.timestampStart,
    this.timestampEnd,
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
      difficulty: json['difficulty'] ?? 'medium',
      skillType: json['skill_type'] ?? 'comprehension',
      explanation: json['explanation'],
      videoExplanationUrl: json['video_explanation_url'],
      timestampStart: json['timestamp_start'],
      timestampEnd: json['timestamp_end'],
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
      'difficulty': difficulty,
      'skill_type': skillType,
      'explanation': explanation,
      'video_explanation_url': videoExplanationUrl,
      'timestamp_start': timestampStart,
      'timestamp_end': timestampEnd,
    };
  }
}
