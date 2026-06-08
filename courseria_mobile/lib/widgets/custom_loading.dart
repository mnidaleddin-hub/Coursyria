import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../core/theme/theme_controller.dart';

class CustomLoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const CustomLoadingIndicator({
    super.key,
    this.size = 35,
    this.strokeWidth = 3,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    final indicatorColor = color ?? themeController.currentPrimaryColor;

    return Center(
      child: SizedBox(
        width: size.r,
        height: size.r,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
          backgroundColor: indicatorColor.withOpacity(0.1),
        ),
      ),
    );
  }
}
