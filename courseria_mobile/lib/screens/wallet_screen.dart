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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBalanceCard(),
                  SizedBox(height: 32.h),
                  _buildActivityChart(),
                  SizedBox(height: 32.h),
                  _buildActionSection(),
                  SizedBox(height: 32.h),
                  _buildTransactionHistory(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      pinned: true,
      backgroundColor: AppColors.primaryNavy,
      title: Text("المحفظة الرقمية", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18.sp)),
      centerTitle: true,
      elevation: 0,
    );
  }

  Widget _buildActivityChart() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("نشاط المحفظة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: AppColors.textMain)),
              Text("آخر 7 أيام", style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted)),
            ],
          ),
          SizedBox(height: 24.h),
          SizedBox(
            height: 100.h,
            width: double.infinity,
            child: CustomPaint(
              painter: _SimpleLineChartPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryNavy, AppColors.secondaryNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32.r),
        boxShadow: [
          BoxShadow(
              color: AppColors.primaryNavy.withOpacity(0.3),
              blurRadius: 25,
              offset: const Offset(0, 12))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("الرصيد المتاح",
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500)),
              Icon(Icons.account_balance_wallet_rounded, color: AppColors.accentTeal.withOpacity(0.5), size: 24),
            ],
          ),
          SizedBox(height: 20.h),
          Obx(() => Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _controller.balance.value,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 40.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: 8.h, right: 8.w),
                child: Text("ل.س", style: TextStyle(color: Colors.white70, fontSize: 16.sp, fontWeight: FontWeight.bold)),
              ),
            ],
          )),
          SizedBox(height: 24.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.accentTeal, size: 14),
                SizedBox(width: 8.w),
                Text("محفظة تعليمية ذكية",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("عمليات سريعة",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18.sp, color: AppColors.textMain)),
        SizedBox(height: 20.h),
        Row(
          children: [
            _buildQuickAction(Icons.upload_file_rounded, "إرسال إيصال",
                () => _showDepositDialog(), Colors.blue),
            SizedBox(width: 16.w),
            _buildQuickAction(Icons.vpn_key_rounded, "كود تفعيل",
                () => _showPromoCodeDialog(), Colors.orange),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap, Color color) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24.r),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24.r),
              ),
              SizedBox(height: 12.h),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14.sp,
                      color: AppColors.textMain)),
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

  Widget _buildStatusBadge(TransactionStatus statusValue) {
    Color color;
    String label;
    switch (statusValue) {
      case TransactionStatus.approved:
        color = Colors.green;
        label = "مقبول";
        break;
      case TransactionStatus.rejected:
        color = Colors.red;
        label = "مرفوض";
        break;
      default:
        color = Colors.orange;
        label = "قيد المراجعة";
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10.sp, fontWeight: FontWeight.bold)),
    );
  }
}

class _SimpleLineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryNavy.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.primaryNavy.withOpacity(0.1), Colors.transparent],
      ).createShader(Rect.fromLTRB(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final points = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.2, size.height * 0.6),
      Offset(size.width * 0.4, size.height * 0.9),
      Offset(size.width * 0.6, size.height * 0.4),
      Offset(size.width * 0.8, size.height * 0.7),
      Offset(size.width, size.height * 0.2),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    fillPath.moveTo(points[0].dx, size.height);
    fillPath.lineTo(points[0].dx, points[0].dy);

    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
      fillPath.lineTo(points[i].dx, points[i].dy);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw dots
    final dotPaint = Paint()..color = AppColors.primaryNavy;
    for (final point in points) {
      canvas.drawCircle(point, 4, dotPaint);
      canvas.drawCircle(point, 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
