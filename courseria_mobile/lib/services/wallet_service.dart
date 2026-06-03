import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/constants.dart';

import '../models/wallet_transaction_model.dart';

class WalletService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch Balance from Backend
  Future<Map<String, dynamic>> fetchBalance() async {
    try {
      final response = await _dio.get('/wallet/balance');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Upload Receipt Image to Supabase Storage
  Future<String?> uploadReceipt(dynamic imageFile, String userId) async {
    try {
      final String fileName =
          'receipts/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      if (kIsWeb) {
        // For Web, imageFile should be Uint8List or XFile
        await _supabase.storage.from('payments').uploadBinary(fileName, imageFile);
      } else {
        // For Mobile, imageFile is File
        await _supabase.storage.from('payments').upload(fileName, imageFile as File);
      }

      final String publicUrl =
          _supabase.storage.from('payments').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      if (kDebugMode) debugPrint("Upload error: $e");
      return null;
    }
  }

  // Submit Recharge Request
  Future<Map<String, dynamic>> submitRechargeRequest({
    required String userId,
    required double amount,
    required String paymentMethod,
    required String transactionId,
    required String note,
    String? receiptUrl,
  }) async {
    try {
      final response = await _dio.post('/wallet/recharge', data: {
        'user_id': userId,
        'amount': amount,
        'payment_method': paymentMethod,
        'transaction_id': transactionId,
        'receipt_screenshot_url': receiptUrl,
        'note': note,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get Transaction History
  Future<List<WalletTransaction>> getTransactionHistory(String userId) async {
    try {
      final response = await _dio.get('/wallet/transactions');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((e) => WalletTransaction.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) debugPrint("Error fetching history: $e");
      return [];
    }
  }

  String _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionError) return "خطأ في الاتصال";
    return e.response?.data['detail'] ?? "حدث خطأ في معالجة الطلب";
  }
}
