import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../widgets/confetti_overlay.dart';

class ConfettiUtils {
  static void playConfetti() {
    final context = Get.context;
    if (context != null) {
      ConfettiOverlay.of(context)?.play();
    }
  }
}
