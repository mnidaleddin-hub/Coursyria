class Quiz {
  final String id;
  final String? courseId;
  final String? lessonId;
  final String title;
  final String description;
  final String quizType; // standard, mock_exam, custom, official_past_paper
  final String? grade; // 9th, bac_scientific, bac_literary
  final String? subject;
  final int? timeLimit; // In minutes
  final int passingScore;
  final int questionsCount;
  final bool isPublished;
  final DateTime createdAt;

  Quiz({
    required this.id,
    this.courseId,
    this.lessonId,
    required this.title,
    required this.description,
    this.quizType = 'standard',
    this.grade,
    this.subject,
    this.timeLimit,
    required this.passingScore,
    required this.questionsCount,
    required this.isPublished,
    required this.createdAt,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      courseId: json['course_id'],
      lessonId: json['lesson_id'],
      title: json['title'],
      description: json['description'] ?? '',
      quizType: json['quiz_type'] ?? 'standard',
      grade: json['grade'],
      subject: json['subject'],
      timeLimit: json['time_limit'],
      passingScore: json['passing_score'] ?? 60,
      questionsCount: json['questions_count'] ?? 0,
      isPublished: json['is_published'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'lesson_id': lessonId,
      'title': title,
      'description': description,
      'quiz_type': quizType,
      'grade': grade,
      'subject': subject,
      'time_limit': timeLimit,
      'passing_score': passingScore,
      'questions_count': questionsCount,
      'is_published': isPublished,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
