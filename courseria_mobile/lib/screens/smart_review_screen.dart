import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:animations/animations.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../core/constants/constants.dart';

class SmartReviewScreen extends StatefulWidget {
  const SmartReviewScreen({super.key});

  @override
  State<SmartReviewScreen> createState() => _SmartReviewScreenState();
}

class _SmartReviewScreenState extends State<SmartReviewScreen> {
  final List<Map<String, String>> _flashcards = [
    {'q': 'ما هو Flutter؟', 'a': 'إطار عمل من جوجل لبناء تطبيقات متعددة المنصات.'},
    {'q': 'ما هو GetX؟', 'a': 'مكتبة لإدارة الحالة والملاحة وتسهيل التطوير في Flutter.'},
    {'q': 'ما هو Dart؟', 'a': 'لغة برمجة محسنة للعميل، طورتها جوجل.'},
  ];

  int _currentIndex = 0;
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text("المراجعة الذكية", style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentIndex + 1) / _flashcards.length,
              backgroundColor: Colors.white10,
              color: AppColors.accentTeal,
              borderRadius: BorderRadius.circular(10),
            ),
            SizedBox(height: 10.h),
            Text("${_currentIndex + 1} من ${_flashcards.length}", style: TextStyle(color: Colors.white38, fontSize: 12.sp)),
            SizedBox(height: 40.h),
            Expanded(
              child: PageTransitionSwitcher(
                duration: const Duration(milliseconds: 500),
                reverse: false,
                transitionBuilder: (child, animation, secondaryAnimation) {
                  return SharedAxisTransition(
                    animation: animation,
                    secondaryAnimation: secondaryAnimation,
                    transitionType: SharedAxisTransitionType.horizontal,
                    fillColor: Colors.transparent,
                    child: child,
                  );
                },
                child: GestureDetector(
                  key: ValueKey<int>(_currentIndex),
                  onTap: () => setState(() => _showAnswer = !_showAnswer),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _showAnswer ? AppColors.accentTeal.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(30.r),
                      border: Border.all(color: _showAnswer ? AppColors.accentTeal : Colors.white10, width: 2),
                    ),
                    padding: EdgeInsets.all(32.r),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _showAnswer ? PhosphorIcons.lightbulb() : PhosphorIcons.question(),
                          color: _showAnswer ? AppColors.accentTeal : Colors.white24,
                          size: 60.sp,
                        ),
                        SizedBox(height: 30.h),
                        Text(
                          _showAnswer ? _flashcards[_currentIndex]['a']! : _flashcards[_currentIndex]['q']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 40.h),
                        Text(
                          _showAnswer ? "انقر لرؤية السؤال" : "انقر لرؤية الإجابة",
                          style: TextStyle(color: Colors.white38, fontSize: 12.sp),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 40.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavButton(
                  icon: Icons.arrow_back_ios,
                  label: "السابق",
                  onTap: _currentIndex > 0 ? () => setState(() { _currentIndex--; _showAnswer = false; }) : null,
                ),
                _buildNavButton(
                  icon: Icons.arrow_forward_ios,
                  label: "التالي",
                  onTap: _currentIndex < _flashcards.length - 1 ? () => setState(() { _currentIndex++; _showAnswer = false; }) : null,
                ),
              ],
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({required IconData icon, required String label, VoidCallback? onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16.sp),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
        disabledBackgroundColor: Colors.white.withOpacity(0.05),
      ),
    );
  }
}
