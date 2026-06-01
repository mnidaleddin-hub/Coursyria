import 'package:dio/dio.dart';
import '../core/constants/constants.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // Request OTP
  Future<Map<String, dynamic>> requestOTP(String contact, {String channel = 'whatsapp'}) async {
    try {
      final response = await _dio.post('/auth/send-otp', data: {
        'contact': contact,
        'channel': channel,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Verify OTP
  Future<Map<String, dynamic>> verifyOTP(String contact, String otp, {String? deviceId}) async {
    try {
      final response = await _dio.post('/auth/verify-otp', data: {
        'contact': contact,
        'otp': otp,
        'device_id': deviceId,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout) {
      return "خطأ في الاتصال بالإنترنت، يرجى المحاولة لاحقاً";
    }
    if (e.response != null && e.response?.data != null) {
      return e.response?.data['detail'] ?? "حدث خطأ غير متوقع";
    }
    return "فشل الاتصال بالسيرفر";
  }
}
