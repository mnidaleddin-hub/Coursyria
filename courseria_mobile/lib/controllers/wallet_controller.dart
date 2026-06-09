import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/wallet_service.dart';
import '../models/wallet_transaction_model.dart';
import 'auth_controller.dart';
import 'system_controller.dart';

class WalletController extends GetxController {
  final WalletService _walletService = WalletService();
  final AuthController _authController = Get.find<AuthController>();
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  var balance = "0".obs;
  var isLoading = false.obs;
  var history = <WalletTransaction>[].obs;
  var selectedImagePath = "".obs;

  @override
  void onInit() {
    super.onInit();
    // 1. Sync token to service
    _walletService.setToken(_authController.token.value);

    // 2. Load data
    fetchWalletData();
  }

  Future<void> submitCharityRequest(String justification) async {
    try {
      isLoading.value = true;
      final systemController = Get.find<SystemController>();
      if (systemController.isOfflineMode.value) {
        await Future.delayed(const Duration(seconds: 1));
        Get.snackbar("تم الإرسال (وضع التجربة)", "تم استلام طلب الدعم المادي بنجاح وسيتم الرد عليك قريباً.",
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
      final response = await _authController.dio.post('/wallet/charity-request',
          data: {"justification": justification});
      Get.snackbar("تم الإرسال", response.data['message'],
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar("خطأ", "فشل إرسال الطلب",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitSupportTicket(
      String title, String message, String category) async {
    try {
      isLoading.value = true;
      final systemController = Get.find<SystemController>();
      if (systemController.isOfflineMode.value) {
        await Future.delayed(const Duration(seconds: 1));
        Get.snackbar("تم الإرسال (وضع التجربة)", "تم فتح تذكرة دعم فني جديدة برقم #MOCK-123",
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
      final response = await _authController.dio.post('/wallet/support-ticket',
          data: {"title": title, "message": message, "category": category});
      Get.snackbar("تم الإرسال", response.data['message'],
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar("خطأ", "فشل إرسال التذكرة",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchWalletBalance() => fetchWalletData();

  Future<void> fetchWalletData() async {
    try {
      isLoading.value = true;

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final systemController = Get.find<SystemController>();
      if (systemController.isOfflineMode.value) {
        await Future.delayed(const Duration(seconds: 1));
        balance.value = "75000";
        return;
      }

      // 1. Fetch real balance from Supabase directly if no custom backend API
      final walletResponse = await _supabase
          .from('wallets')
          .select('balance')
          .eq('user_id', userId)
          .maybeSingle();
      
      if (walletResponse != null) {
        balance.value = walletResponse['balance'].toString();
      } else {
        // Create wallet if it doesn't exist
        await _supabase.from('wallets').insert({'user_id': userId, 'balance': 0});
        balance.value = "0";
      }

      // 2. Fetch history from Supabase
      final transResponse = await _supabase
          .from('wallet_transactions')
          .select('*, wallets!inner(user_id)')
          .eq('wallets.user_id', userId)
          .order('created_at', ascending: false);
      
      history.assignAll((transResponse as List).map((e) => WalletTransaction.fromJson(e)).toList());
    } catch (e) {
      if (kDebugMode) debugPrint("Wallet fetch error: $e");
      Get.snackbar("خطأ", "فشل جلب بيانات المحفظة",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickReceiptImage() => pickImage();

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      selectedImagePath.value = image.path;
    }
  }

  Future<void> submitTopUpRequest({
    required String transactionId,
    required double amount,
    required String method,
    String? note,
  }) async {
    if (selectedImagePath.value.isEmpty) {
      Get.snackbar("تنبيه", "يرجى إرفاق صورة الإيصال",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    try {
      isLoading.value = true;
      
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // 1. Upload receipt to Supabase Storage
      final String? publicUrl = await _walletService.uploadReceipt(File(selectedImagePath.value), userId);
      if (publicUrl == null) throw "فشل رفع الصورة";

      // 2. Submit to backend
      await _walletService.submitRechargeRequest(
        userId: userId,
        amount: amount,
        paymentMethod: method,
        transactionId: transactionId,
        note: note ?? "",
        receiptUrl: publicUrl,
      );

      Get.snackbar("نجاح", "تم إرسال طلب الشحن بنجاح وهو قيد المراجعة",
          snackPosition: SnackPosition.BOTTOM);
      
      selectedImagePath.value = ""; // Clear for next time
      Get.back();
      fetchWalletData(); // Refresh history
    } catch (e) {
      Get.snackbar("خطأ", "فشل إرسال طلب الشحن: $e",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> usePromoCode(String code) async {
    try {
      isLoading.value = true;
      final response = await _authController.dio.post('/wallet/use-promo-code', data: {"code": code});
      
      if (response.statusCode == 200) {
        balance.value = response.data['new_balance'].toString();
        Get.snackbar("نجاح", response.data['message'], snackPosition: SnackPosition.BOTTOM);
        fetchWalletData();
      }
    } catch (e) {
      Get.snackbar("خطأ", "كود غير صالح أو مستخدم مسبقاً", snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  var referralCode = "".obs;
  Future<void> fetchReferralCode() async {
    try {
      final response = await _authController.dio.get('/wallet/referral-code');
      referralCode.value = response.data['referral_code'];
    } catch (e) {
      if (kDebugMode) debugPrint("Referral error: $e");
    }
  }
}
