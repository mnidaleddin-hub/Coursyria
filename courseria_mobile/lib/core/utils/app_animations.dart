import 'package:flutter/material.dart';

class SlideTransitionBuilder extends PageRouteBuilder {
  final Widget page;
  SlideTransitionBuilder({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeOutQuart;
            var tweet = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(position: animation.drive(tweet), child: child);
          },
        );
}

class ScaleTransitionBuilder extends PageRouteBuilder {
  final Widget page;
  ScaleTransitionBuilder({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
              scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn),
              ),
              child: child,
            );
          },
        );
}

class FadeTransitionBuilder extends PageRouteBuilder {
  final Widget page;
  FadeTransitionBuilder({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
}

/// دالة مساعدة لإنشاء زر مع تأثير Scale و Fade مدمج عند الضغط
Widget animatedButton({
  required Widget child,
  required VoidCallback onTap,
  Duration duration = const Duration(milliseconds: 150),
}) {
  return GestureDetector(
    onTap: onTap,
    child: TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: 1.0),
      duration: duration,
      builder: (context, value, child) {
        return AnimatedContainer(
          duration: duration,
          curve: Curves.easeInOut,
          child: child,
        );
      },
      child: child,
    ),
  );
}
