import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

/// Shared empty-state placeholder: icon illustration + title + optional CTA.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? ctaLabel;
  final VoidCallback? onCta;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Gap.s40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container — layered circles for depth
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.slate200,
                    shape: BoxShape.circle,
                  ),
                ),
                Icon(icon, size: 32, color: AppColors.slate500),
              ],
            ),

            const SizedBox(height: Gap.s20),

            Text(title, style: AppTextStyles.h3, textAlign: TextAlign.center),

            if (subtitle != null) ...[
              const SizedBox(height: Gap.s8),
              Text(
                subtitle!,
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],

            if (ctaLabel != null) ...[
              const SizedBox(height: Gap.s24),
              FilledButton(onPressed: onCta, child: Text(ctaLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
