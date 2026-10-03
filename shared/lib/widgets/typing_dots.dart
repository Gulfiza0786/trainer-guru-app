import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

/// Three-dot typing indicator, 900ms loop (spec §3B).
class TypingDots extends StatefulWidget {
  const TypingDots({super.key});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: Gap.s4),
        padding: const EdgeInsets.symmetric(horizontal: Gap.s16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.slate100,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.slate900.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.slate400.withValues(
                        alpha: _dotOpacity(i),
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  double _dotOpacity(int index) {
    final t = (_controller.value * 3 - index).clamp(0.0, 1.0);
    return 0.25 + 0.75 * (t < 0.5 ? t * 2 : (1 - t) * 2);
  }
}
