import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../core/constants/constants.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? description;
  final String? lottieAsset;
  final VoidCallback? onRetry;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.description,
    this.lottieAsset,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (lottieAsset != null)
              Lottie.asset(
                lottieAsset!,
                width: 200.w,
                height: 200.w,
                repeat: true,
              )
            else
              Icon(Icons.inbox_rounded, size: 80.sp, color: Colors.white24),
            SizedBox(height: 24.h),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              SizedBox(height: 8.h),
              Text(
                description!,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentTeal,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: const Text("إعادة المحاولة"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
