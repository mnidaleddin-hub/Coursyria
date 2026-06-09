import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../controllers/wallet_controller.dart';
import '../core/constants/constants.dart';

class WalletRechargeScreen extends StatefulWidget {
  const WalletRechargeScreen({super.key});

  @override
  State<WalletRechargeScreen> createState() => _WalletRechargeScreenState();
}

class _WalletRechargeScreenState extends State<WalletRechargeScreen> {
  final WalletController _walletController = Get.find<WalletController>();
  late TextEditingController _transactionController;
  late TextEditingController _amountController;
  late TextEditingController _promoController;
  final String _shamCashWalletId = "72decb21f5b30a9e87b019cf1f9126ed";

  @override
  void initState() {
    super.initState();
    _transactionController = TextEditingController();
    _amountController = TextEditingController();
    _promoController = TextEditingController();
  }

  @override
  void dispose() {
    _transactionController.dispose();
    _amountController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryNavy,
      appBar: AppBar(
        title: Text("شحن المحفظة والمدفوعات", style: TextStyle(color: Colors.white, fontSize: 18.sp)),
        backgroundColor: AppColors.secondaryNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            // 1. Promo Code Section
            _buildPromoCodeSection(),
            SizedBox(height: 25.h),
            
            const Divider(color: Colors.white10),
            SizedBox(height: 10.h),

            // 2. Current Balance Card
            _buildBalanceCard(),
            SizedBox(height: 25.h),

            // 3. Platform Wallet ID Section
            _buildWalletIdSection(),
            SizedBox(height: 25.h),

            // 4. QR Code Section
            _buildQrSection(),
            SizedBox(height: 30.h),

            // 5. Transaction Form
            _buildTransactionForm(),
            SizedBox(height: 20.h),
            
            // 6. Receipt Upload
            _buildReceiptUpload(),
            SizedBox(height: 30.h),

            // 7. Submit Button
            _buildSubmitButton(),
            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCodeSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.goldAchievement.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.goldAchievement.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("تفعيل كود ترويجي", style: TextStyle(color: AppColors.goldAchievement, fontWeight: FontWeight.bold, fontSize: 16.sp)),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("أدخل الكود هنا", Icons.qr_code_scanner_rounded),
                ),
              ),
              SizedBox(width: 12.w),
              ElevatedButton(
                onPressed: () {
                  if (_promoController.text.isNotEmpty) {
                    _walletController.usePromoCode(_promoController.text);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.goldAchievement),
                child: const Text("تفعيل", style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptUpload() {
    return Obx(() => Column(
      children: [
        if (_walletController.selectedImagePath.value.isNotEmpty)
          Container(
            height: 150.h,
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 15.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              image: DecorationImage(
                image: FileImage(File(_walletController.selectedImagePath.value)),
                fit: BoxFit.cover,
              ),
            ),
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                onPressed: () => _walletController.selectedImagePath.value = "",
              ),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _walletController.pickReceiptImage(),
            icon: const Icon(Icons.image_search_rounded, color: AppColors.accentTeal),
            label: Text(_walletController.selectedImagePath.value.isEmpty ? "ارفق صورة الإيصال" : "تغيير الصورة", 
                style: const TextStyle(color: AppColors.accentTeal)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.accentTeal),
              padding: EdgeInsets.symmetric(vertical: 15.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    ));
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accentTeal, AppColors.lightTeal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentTeal.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text("رصيدك الحالي", style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
          SizedBox(height: 10.h),
          Obx(() => Text(
            "${_walletController.balance.value} ليرة سورية جديدة",
            style: TextStyle(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.bold),
          )),
        ],
      ),
    );
  }

  Widget _buildWalletIdSection() {
    return Container(
      padding: EdgeInsets.all(15.w),
      decoration: BoxDecoration(
        color: AppColors.secondaryNavy,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Text("معرف محفظة المنصة الرسمي", style: TextStyle(color: Colors.white70)),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _shamCashWalletId,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.accentTeal, fontSize: 12.sp, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: Colors.white54),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _shamCashWalletId));
                  Get.snackbar("تم النسخ", "تم نسخ معرف المحفظة بنجاح", 
                      backgroundColor: AppColors.accentTeal, colorText: Colors.white);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQrSection() {
    return Column(
      children: [
        const Text("امسح الرمز للشحن السريع", style: TextStyle(color: Colors.white54)),
        SizedBox(height: 15.h),
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: QrImageView(
            data: _shamCashWalletId,
            version: QrVersions.auto,
            size: 180.w,
            gapless: false,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionForm() {
    return Column(
      children: [
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration("المبلغ المرسل (ليرة سورية جديدة)", Icons.attach_money_rounded),
        ),
        SizedBox(height: 15.h),
        TextField(
          controller: _transactionController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration("رقم العملية / المعاملة", Icons.receipt_long_rounded),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: AppColors.accentTeal),
      filled: true,
      fillColor: AppColors.secondaryNavy,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accentTeal)),
    );
  }

  Widget _buildSubmitButton() {
    return Obx(() => SizedBox(
      width: double.infinity,
      height: 55.h,
      child: ElevatedButton(
        onPressed: _walletController.isLoading.value ? null : () {
          if (_amountController.text.isEmpty || _transactionController.text.isEmpty) {
            Get.snackbar("تنبيه", "يرجى ملء كافة الحقول");
            return;
          }
          _walletController.submitTopUpRequest(
            transactionId: _transactionController.text,
            amount: double.tryParse(_amountController.text) ?? 0,
            method: "sham_cash",
            note: "شحن عبر شام كاش",
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentTeal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _walletController.isLoading.value 
          ? const CircularProgressIndicator(color: Colors.white)
          : Text("تأكيد إرسال الطلب", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    ));
  }
}
