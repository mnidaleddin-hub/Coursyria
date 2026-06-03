import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../services/wallet_service.dart';
import '../models/wallet_transaction_model.dart';
import 'auth_controller.dart';

class WalletController extends GetxController {
  final WalletService _walletService = WalletService();
  final AuthController _authController = Get.find<AuthController>();
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

  Future<void> fetchWalletData() async {
    try {
      isLoading.value = true;

      // 1. Fetch real balance from Backend
      final response = await _walletService.fetchBalance();
      balance.value = response['balance'].toString();

      // 2. Fetch history
      final transactions = await _walletService
          .getTransactionHistory(_authController.userData['id'] ?? "");
      history.assignAll(transactions);
    } catch (e) {
      if (kDebugMode) debugPrint("Wallet fetch error: $e");
      Get.snackbar("خطأ", "فشل جلب بيانات المحفظة",
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickReceiptImage() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      if (kIsWeb) {
        // Handle web image picking (path is not accessible)
        Get.snackbar("تنبيه", "رفع الصور عبر الويب غير مدعوم حالياً في هذه النسخة");
      } else {
        selectedImagePath.value = image.path;
      }
    }
  }

  Future<void> submitTopUpRequest({
    required String transactionId,
    required double amount,
    required String method,
    required String note,
  }) async {
    try {
      isLoading.value = true;

      String? receiptUrl;
      if (selectedImagePath.value.isNotEmpty) {
        receiptUrl = await _walletService.uploadReceipt(
            File(selectedImagePath.value),
            _authController.userData['id'] ?? "unknown");
      }

      final result = await _walletService.submitRechargeRequest(
        userId: _authController.userData['id'] ?? "",
        amount: amount,
        paymentMethod: method,
        transactionId: transactionId,
        note: note,
        receiptUrl: receiptUrl,
      );

      Get.back(); // Close form
      Get.snackbar(
        "تم بنجاح",
        result['message'] ??
            "تم استلام طلبك، سيتم التأكد من الحوالة خلال دقائق",
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.BOTTOM,
      );

      fetchWalletData(); // Refresh list and balance
      selectedImagePath.value = ""; // Reset
    } catch (e) {
      Get.snackbar("خطأ", e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }
}
