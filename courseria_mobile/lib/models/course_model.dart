import '../core/constants/constants.dart';

class Lesson {
  final String id;
  final String title;
  final String? description; // New field
  final String? duration;
  final int durationSeconds; // New field
  final String? videoUrl;
  final bool isFree;
  final int? viewsCount; // New field
  final int? likesCount; // New field
  final String? thumbnailUrl; // New field
  final String? teacherId; // New field
  final List<LessonAsset> worksheets;
  final List<LessonAsset> solvedTests;
  final List<LessonAsset> unsolvedTests;
  final List<LessonAsset> examReviews;
  final List<QuizQuestion> quizQuestions;

  Lesson({
    required this.id,
    required this.title,
    this.description, // New field
    this.duration,
    this.durationSeconds = 0, // New field
    this.videoUrl,
    this.isFree = false,
    this.viewsCount = 0, // New field
    this.likesCount = 0, // New field
    this.thumbnailUrl, // New field
    this.teacherId, // New field
    this.worksheets = const [],
    this.solvedTests = const [],
    this.unsolvedTests = const [],
    this.examReviews = const [],
    this.quizQuestions = const [],
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(), // New field
      duration: json['duration']?.toString(),
      durationSeconds: (json['duration_seconds'] ?? 0) as int, // New field
      videoUrl: (json['video_url'] ?? json['content_path'])?.toString(),
      isFree: json['is_free'] ?? false,
      viewsCount: (json['views_count'] ?? 0) as int, // New field
      likesCount: (json['likes_count'] ?? 0) as int, // New field
      thumbnailUrl: (json['thumbnail_url'] ?? '').toString(), // New field
      teacherId: (json['teacher_id'] ?? '').toString(), // New field
      worksheets: (json['worksheets'] as List? ?? [])
          .map((e) => LessonAsset.fromJson(e))
          .toList(),
      solvedTests: (json['solved_tests'] as List? ?? [])
          .map((e) => LessonAsset.fromJson(e))
          .toList(),
      unsolvedTests: (json['unsolved_tests'] as List? ?? [])
          .map((e) => LessonAsset.fromJson(e))
          .toList(),
      examReviews: (json['exam_reviews'] as List? ?? [])
          .map((e) => LessonAsset.fromJson(e))
          .toList(),
      quizQuestions: (json['quiz_questions'] as List? ?? [])
          .map((e) => QuizQuestion.fromJson(e))
          .toList(),
    );
  }

  Lesson copyWith({
    String? id,
    String? title,
    String? description, // New field
    String? duration,
    String? videoUrl,
    bool? isFree,
    int? viewsCount, // New field
    int? likesCount, // New field
    String? thumbnailUrl, // New field
    String? teacherId, // New field
    List<LessonAsset>? worksheets,
    List<LessonAsset>? solvedTests,
    List<LessonAsset>? unsolvedTests,
    List<LessonAsset>? examReviews,
  }) {
    return Lesson(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description, // New field
      duration: duration ?? this.duration,
      videoUrl: videoUrl ?? this.videoUrl,
      isFree: isFree ?? this.isFree,
      viewsCount: viewsCount ?? this.viewsCount, // New field
      likesCount: likesCount ?? this.likesCount, // New field
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl, // New field
      teacherId: teacherId ?? this.teacherId, // New field
      worksheets: worksheets ?? this.worksheets,
      solvedTests: solvedTests ?? this.solvedTests,
      unsolvedTests: unsolvedTests ?? this.unsolvedTests,
      examReviews: examReviews ?? this.examReviews,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description, // New field
      'duration': duration,
      'video_url': videoUrl,
      'is_free': isFree,
      'views_count': viewsCount, // New field
      'likes_count': likesCount, // New field
      'thumbnail_url': thumbnailUrl, // New field
      'teacher_id': teacherId, // New field
      'worksheets': worksheets.map((e) => e.toJson()).toList(),
      'solved_tests': solvedTests.map((e) => e.toJson()).toList(),
      'unsolved_tests': unsolvedTests.map((e) => e.toJson()).toList(),
      'exam_reviews': examReviews.map((e) => e.toJson()).toList(),
    };
  }
}

class QuizQuestion {
  final String id;
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;
  final String? explanation;

  QuizQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: (json['id'] ?? '').toString(),
      questionText: (json['question_text'] ?? '').toString(),
      options:
          (json['options'] as List? ?? []).map((e) => e.toString()).toList(),
      correctOptionIndex: json['correct_option_index'] ?? 0,
      explanation: json['explanation']?.toString(),
    );
  }
}

class LessonAsset {
  final String id;
  final String title;
  final String assetType;
  final String fileUrl;
  final bool? isSolved;

  LessonAsset({
    required this.id,
    required this.title,
    required this.assetType,
    required this.fileUrl,
    this.isSolved,
  });

  factory LessonAsset.fromJson(Map<String, dynamic> json) {
    return LessonAsset(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      assetType: (json['asset_type'] ?? '').toString(),
      fileUrl: (json['file_url'] ?? '').toString(),
      isSolved: json['is_solved'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'asset_type': assetType,
      'file_url': fileUrl,
      'is_solved': isSolved,
    };
  }
}

class Course {
  final String id;
  final String title;
  final String instructor;
  final double price;
  final double rating;
  final String coverUrl;
  final String subject;
  final String description;
  final String? extendedDescription; // New field
  final String status; // New field: pending, approved
  final String? gradeLevel; // New field
  final String? generalNotes; // New field
  final int? viewsCount; // New field
  final int? likesCount; // New field
  final String? thumbnailUrl; // New field
  String get instructorName => instructor;
  final String? teacherId; // New field
  final List<Lesson> lessons;
  bool isPurchased;

  String get category => subject;
  int get lessonsCount => lessons.length;

  Course({
    required this.id,
    required this.title,
    required this.instructor,
    required this.price,
    required this.rating,
    required this.coverUrl,
    required this.subject,
    required this.description,
    this.extendedDescription, // New field
    this.status = 'pending', // New field
    this.gradeLevel, // New field
    this.generalNotes, // New field
    this.viewsCount = 0, // New field
    this.likesCount = 0, // New field
    this.thumbnailUrl, // New field
    this.teacherId, // New field
    required this.lessons,
    this.isPurchased = false,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    String coverUrl = (json['cover_url'] ?? '').toString();
    // Use a placeholder image if coverUrl is empty
    if (coverUrl.isEmpty) {
      coverUrl =
          "https://images.unsplash.com/photo-1635070041078-e363dbe005cb?q=80&w=500";
    } else if (coverUrl.startsWith('/')) {
      // Prepend baseUrl if it's a relative path from Supabase/Backend
      coverUrl = "${AppConstants.baseUrl}$coverUrl";
    }

    return Course(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      instructor:
          (json['instructor'] ?? json['teacher'] ?? 'أستاذ متميز').toString(),
      price: (json['price'] ?? 0).toDouble(),
      rating: (json['rating'] ?? 0).toDouble(),
      coverUrl: coverUrl,
      subject: (json['subject'] ?? '').toString(),
      description: (json['description'] ?? json['summary'] ?? '').toString(),
      extendedDescription:
          (json['extended_description'] ?? '').toString(), // New field
      status: (json['status'] ?? 'pending').toString(), // New field
      gradeLevel: json['grade_level']?.toString(), // New field
      generalNotes: json['general_notes']?.toString(), // New field
      viewsCount: (json['views_count'] ?? 0) as int, // New field
      likesCount: (json['likes_count'] ?? 0) as int, // New field
      thumbnailUrl: (json['thumbnail_url'] ?? '').toString(), // New field
      teacherId: (json['teacher_id'] ?? '').toString(), // New field
      lessons: (json['lessons'] as List? ?? [])
          .map((l) => Lesson.fromJson(l))
          .toList(),
      isPurchased: json['is_purchased'] ?? false,
    );
  }

  Course copyWith({
    String? id,
    String? title,
    String? instructor,
    double? price,
    double? rating,
    String? coverUrl,
    String? subject,
    String? description,
    String? extendedDescription, // New field
    String? status, // New field
    String? gradeLevel, // New field
    String? generalNotes, // New field
    int? viewsCount, // New field
    int? likesCount, // New field
    String? thumbnailUrl, // New field
    String? teacherId, // New field
    List<Lesson>? lessons,
    bool? isPurchased,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      instructor: instructor ?? this.instructor,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      coverUrl: coverUrl ?? this.coverUrl,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      extendedDescription:
          extendedDescription ?? this.extendedDescription, // New field
      status: status ?? this.status, // New field
      gradeLevel: gradeLevel ?? this.gradeLevel, // New field
      generalNotes: generalNotes ?? this.generalNotes, // New field
      viewsCount: viewsCount ?? this.viewsCount, // New field
      likesCount: likesCount ?? this.likesCount, // New field
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl, // New field
      teacherId: teacherId ?? this.teacherId, // New field
      lessons: lessons ?? this.lessons,
      isPurchased: isPurchased ?? this.isPurchased,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'instructor': instructor,
      'price': price,
      'rating': rating,
      'cover_url': coverUrl,
      'subject': subject,
      'description': description,
      'extended_description': extendedDescription, // New field
      'status': status, // New field
      'grade_level': gradeLevel, // New field
      'general_notes': generalNotes, // New field
      'views_count': viewsCount, // New field
      'likes_count': likesCount, // New field
      'thumbnail_url': thumbnailUrl, // New field
      'teacher_id': teacherId, // New field
      'lessons': lessons.map((l) => l.toJson()).toList(),
      'is_purchased': isPurchased,
    };
  }
}
