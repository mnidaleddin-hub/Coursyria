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
  Future<String?> uploadReceipt(File imageFile, String userId) async {
    try {
      final String fileName =
          'receipts/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _supabase.storage.from('payments').upload(fileName, imageFile);

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
      // In a real scenario, this would be an API call to FastAPI
      // For now, returning mock data using the new model
      await Future.delayed(const Duration(seconds: 1)); // Simulate network

      final mockData = [
        {
          "id": "1",
          "transaction_id": "TXN123456",
          "amount": 50000.0,
          "status": "approved",
          "created_at": "2026-05-01T10:00:00Z",
          "note": "User ID: $userId"
        },
        {
          "id": "2",
          "transaction_id": "TXN789012",
          "amount": 25000.0,
          "status": "pending",
          "created_at": "2026-05-08T15:30:00Z",
          "note": "User ID: $userId"
        },
      ];

      return mockData.map((e) => WalletTransaction.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  String _handleError(DioException e) {
    if (e.type == DioExceptionType.connectionError) return "خطأ في الاتصال";
    return e.response?.data['detail'] ?? "حدث خطأ في معالجة الطلب";
  }
}
