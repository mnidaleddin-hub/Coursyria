import 'package:flutter/material.dart';
import 'package:countup/countup.dart';

class AnimatedCounter extends StatelessWidget {
  final double begin;
  final double end;
  final Duration duration;
  final TextStyle? style;
  final String? prefix;
  final String? suffix;
  final int precision;

  const AnimatedCounter({
    super.key,
    required this.begin,
    required this.end,
    this.duration = const Duration(seconds: 1),
    this.style,
    this.prefix,
    this.suffix,
    this.precision = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Countup(
      begin: begin,
      end: end,
      duration: duration,
      separator: ',',
      style: style,
      precision: precision,
      prefix: prefix ?? '',
      suffix: suffix ?? '',
    );
  }
}
