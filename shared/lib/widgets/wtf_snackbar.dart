import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/app_colors.dart';
import '../utils/app_strings.dart';
import '../utils/app_text_styles.dart';

/// Error surfacing (spec §8): human copy + "Copy error" action that puts
/// the raw error on the clipboard for bug reports.
void showWtfError(BuildContext context, String human, String raw) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        human,
        style: AppTextStyles.body.copyWith(color: AppColors.white),
      ),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      action: SnackBarAction(
        label: AppStrings.copyError,
        textColor: AppColors.white.withValues(alpha: 0.9),
        onPressed: () => Clipboard.setData(ClipboardData(text: raw)),
      ),
    ),
  );
}
