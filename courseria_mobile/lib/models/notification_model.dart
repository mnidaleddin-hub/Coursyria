class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final String? courseId;
  final String? courseTitle;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.courseId,
    this.courseTitle,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      courseId: json['course_id'] as String?,
      courseTitle: (json['course'] != null && json['course']['title'] != null)
          ? json['course']['title'] as String
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'course_id': courseId,
    };
  }
}
