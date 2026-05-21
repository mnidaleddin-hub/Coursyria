import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/wallet_controller.dart';
import '../core/constants/constants.dart';
import '../models/wallet_transaction_model.dart';

class WalletScreen extends StatelessWidget {
  WalletScreen({super.key});

  final WalletController _controller = Get.find<WalletController>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _txIdController = TextEditingController();
  final RxString _selectedMethod = "شام كاش".obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvasStart,
      appBar: AppBar(
        title: Text("المحفظة الرقمية",
            style: AppTextStyles.header.copyWith(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            _buildBalanceCard(),
            SizedBox(height: 32.h),
            _buildActionSection(),
            SizedBox(height: 32.h),
            _buildTransactionHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(30.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryNavy, AppColors.secondaryNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: [
          BoxShadow(
              color: AppColors.primaryNavy.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20.r)),
            child: Text("رصيدك الاستثماري الحالي",
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600)),
          ),
          SizedBox(height: 20.h),
          Obx(() => Text(
                "${_controller.balance.value} ليرة سورية جديدة",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 38.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5),
              )),
          SizedBox(height: 10.h),
          Text("جاهز لتطوير مهاراتك",
              style: TextStyle(
                  color: AppColors.accentTeal.withOpacity(0.8),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("شحن الرصيد",
            style: AppTextStyles.header.copyWith(fontSize: 18.sp)),
        SizedBox(height: 16.h),
        Row(
          children: [
            _buildQuickAction(Icons.add_photo_alternate_rounded, "إرسال إيصال",
                () => _showDepositDialog()),
            SizedBox(width: 16.w),
            _buildQuickAction(Icons.qr_code_scanner_rounded, "كود تفعيل",
                () => _showPromoCodeDialog()),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppColors.accentTeal.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.accentTeal, size: 30.r),
              SizedBox(height: 8.h),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                      color: AppColors.primaryNavy)),
            ],
          ),
        ),
      ),
    );
  }

  void _showDepositDialog() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.r))),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("إرسال إيصال دفع",
                  style: AppTextStyles.header.copyWith(fontSize: 20.sp)),
              SizedBox(height: 24.h),
              _buildMethodSelector(),
              SizedBox(height: 16.h),
              TextField(
                controller: _txIdController,
                decoration: const InputDecoration(
                    labelText: "رقم المعاملة (Transaction ID)",
                    border: OutlineInputBorder()),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: "المبلغ المشحون", border: OutlineInputBorder()),
              ),
              SizedBox(height: 24.h),
              Obx(() => _controller.selectedImagePath.value.isEmpty
                  ? OutlinedButton.icon(
                      onPressed: () => _controller.pickReceiptImage(),
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text("إرفاق صورة الإيصال"),
                      style: OutlinedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50.h)),
                    )
                  : const Text("تم إرفاق الصورة ✅",
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold))),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () {
                  _controller.submitTopUpRequest(
                    transactionId: _txIdController.text,
                    amount: double.tryParse(_amountController.text) ?? 0,
                    method: _selectedMethod.value,
                    note: "طلب شحن رصيد",
                  );
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    minimumSize: Size(double.infinity, 56.h)),
                child: const Text("تأكيد الإرسال",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildMethodSelector() {
    final methods = ["شام كاش", "سيرياتيل كاش", "مركز معاذ الشيخ"];
    return Wrap(
      spacing: 8.w,
      children: methods
          .map((m) => Obx(() => ChoiceChip(
                label: Text(m),
                selected: _selectedMethod.value == m,
                onSelected: (val) => _selectedMethod.value = m,
                selectedColor: AppColors.accentTeal.withOpacity(0.2),
              )))
          .toList(),
    );
  }

  void _showPromoCodeDialog() {
    final TextEditingController codeController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text("تفعيل كود شحن"),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(hintText: "أدخل الكود هنا..."),
          textAlign: TextAlign.center,
          style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("إلغاء")),
          ElevatedButton(onPressed: () {}, child: const Text("تفعيل")),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("سجل المعاملات",
            style: AppTextStyles.header.copyWith(fontSize: 18.sp)),
        SizedBox(height: 16.h),
        Obx(() => _controller.history.isEmpty
            ? Center(
                child:
                    Text("لا يوجد معاملات سابقة", style: AppTextStyles.muted))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _controller.history.length,
                itemBuilder: (context, index) {
                  final tx = _controller.history[index];
                  return _buildTransactionItem(tx);
                },
              )),
      ],
    );
  }

  Widget _buildTransactionItem(WalletTransaction tx) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tx.transactionId,
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
              Text(tx.createdAt.toString().split('.')[0],
                  style: AppTextStyles.muted.copyWith(fontSize: 11.sp)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("+${tx.amount} ليرة سورية جديدة",
                  style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w900,
                      fontSize: 15.sp)),
              _buildStatusBadge(tx.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TransactionStatus status) {
    Color color;
    String label;
    switch (status) {
      case TransactionStatus.pending:
        color = Colors.orange;
        label = "قيد المراجعة";
        break;
      case TransactionStatus.approved:
        color = Colors.green;
        label = "تم الشحن";
        break;
      case TransactionStatus.rejected:
        color = Colors.red;
        label = "مرفوض";
        break;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6.r)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10.sp, fontWeight: FontWeight.bold)),
    );
  }
}
