import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Logs a custom event.
  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (kIsWeb) return;
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      debugPrint('❌ Analytics Error: $e');
    }
  }

  /// Logs user login.
  static Future<void> logLogin(String method) async {
    await logEvent(
      name: 'login',
      parameters: {'method': method},
    );
  }

  /// Logs course purchase.
  static Future<void> logCoursePurchase(String courseId, String courseTitle, double price) async {
    await logEvent(
      name: 'course_purchase',
      parameters: {
        'course_id': courseId,
        'course_title': courseTitle,
        'price': price,
        'currency': 'SYP',
      },
    );
  }

  /// Logs lesson completion.
  static Future<void> logLessonCompletion(String lessonId, String lessonTitle, String courseId) async {
    await logEvent(
      name: 'lesson_complete',
      parameters: {
        'lesson_id': lessonId,
        'lesson_title': lessonTitle,
        'course_id': courseId,
      },
    );
  }

  /// Logs quiz completion.
  static Future<void> logQuizCompletion(String quizId, int score, bool passed) async {
    await logEvent(
      name: 'quiz_complete',
      parameters: {
        'quiz_id': quizId,
        'score': score,
        'passed': passed ? 1 : 0,
      },
    );
  }

  /// Sets user ID for analytics.
  static Future<void> setUserId(String userId) async {
    if (kIsWeb) return;
    await _analytics.setUserId(id: userId);
  }
}
