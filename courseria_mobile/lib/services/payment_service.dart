import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PaymentService extends GetxService {
  // Skeleton for Stripe/PayPal integration
  
  Future<bool> processPayment({
    required double amount,
    required String currency,
    required String method, // 'stripe' or 'paypal'
  }) async {
    try {
      debugPrint("Processing $amount $currency via $method...");
      
      // Mock processing delay
      await Future.delayed(const Duration(seconds: 2));
      
      // In real implementation:
      // 1. Call Backend to create payment intent
      // 2. Initialize Stripe/PayPal SDK
      // 3. Confirm payment
      
      return true;
    } catch (e) {
      debugPrint("Payment Error: $e");
      return false;
    }
  }

  void showPaymentBottomSheet({required double amount, required Function(bool) onComplete}) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF1D1E33),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "اختر وسيلة الدفع",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildPaymentOption(
              icon: Icons.credit_card,
              label: "بطاقة ائتمان (Stripe)",
              onTap: () async {
                final success = await processPayment(amount: amount, currency: "USD", method: "stripe");
                onComplete(success);
              },
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              icon: Icons.paypal,
              label: "PayPal",
              onTap: () async {
                final success = await processPayment(amount: amount, currency: "USD", method: "paypal");
                onComplete(success);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({required IconData icon, required String label, required VoidCallback onTap}) {
    return ListTile(
      onTap: () {
        Get.back();
        onTap();
      },
      leading: Icon(icon, color: const Color(0xFF009688)),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white24),
      tileColor: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    );
  }
}
