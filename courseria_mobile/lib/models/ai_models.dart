class AIRequest {
  final String model;
  final String prompt;
  final int maxTokens;
  final double temperature;
  final List<Map<String, String>>? chatHistory;

  AIRequest({
    required this.model,
    required this.prompt,
    this.maxTokens = 1000,
    this.temperature = 0.7,
    this.chatHistory,
  });

  Map<String, dynamic> toJson() {
    return {
      "model": model,
      "messages": [
        if (chatHistory != null) ...chatHistory!,
        {"role": "user", "content": prompt},
      ],
      "max_tokens": maxTokens,
      "temperature": temperature,
    };
  }
}

class AIResponse {
  final bool success;
  final String content;
  final String? error;
  final Map<String, dynamic>? usage;

  AIResponse({
    required this.success,
    required this.content,
    this.error,
    this.usage,
  });

  factory AIResponse.success(String content, [Map<String, dynamic>? usage]) {
    return AIResponse(success: true, content: content, usage: usage);
  }

  factory AIResponse.failure(String error) {
    return AIResponse(success: false, content: "", error: error);
  }
}

class AISummary {
  final String lessonId;
  final String summaryText;
  final DateTime createdAt;

  AISummary({
    required this.lessonId,
    required this.summaryText,
    required this.createdAt,
  });

  factory AISummary.fromJson(Map<String, dynamic> json) {
    return AISummary(
      lessonId: json['lesson_id'],
      summaryText: json['summary_text'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lesson_id': lessonId,
      'summary_text': summaryText,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class AIRecommendation {
  final String courseId;
  final String reason;
  final double score;

  AIRecommendation({
    required this.courseId,
    required this.reason,
    required this.score,
  });

  factory AIRecommendation.fromJson(Map<String, dynamic> json) {
    return AIRecommendation(
      courseId: json['course_id'],
      reason: json['reason'],
      score: (json['score'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'course_id': courseId,
      'reason': reason,
      'score': score,
    };
  }
}
