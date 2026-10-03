import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// Theme factory used by both apps.
/// Pass the brand primary colour (guruPrimary / trainerPrimary) and a
/// full Material 3 ThemeData is returned with consistent styling.
ThemeData wtfTheme(Color primary) {
  final scheme = ColorScheme.fromSeed(
    seedColor: primary,
    primary: primary,
    onPrimary: AppColors.white,
    secondary: primary.withValues(alpha: 0.12),
    onSecondary: primary,
    surface: AppColors.surface,
    onSurface: AppColors.slate900,
    error: AppColors.error,
    onError: AppColors.white,
    outline: AppColors.slate300,
    outlineVariant: AppColors.slate200,
    surfaceContainerHighest: AppColors.surfaceElevated,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,

    // ── Scaffold ──────────────────────────────────────────────────────────────
    scaffoldBackgroundColor: AppColors.surface,

    // ── AppBar ────────────────────────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceElevated,
      foregroundColor: AppColors.slate900,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: AppColors.slate200,
      centerTitle: false,
      titleTextStyle: AppTextStyles.h2,
      iconTheme: const IconThemeData(color: AppColors.slate700, size: 22),
      actionsIconTheme: const IconThemeData(
        color: AppColors.slate700,
        size: 22,
      ),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      toolbarHeight: 60,
    ),

    // ── Text ──────────────────────────────────────────────────────────────────
    textTheme: const TextTheme(
      displayMedium: AppTextStyles.display,
      headlineMedium: AppTextStyles.h1,
      titleLarge: AppTextStyles.h2,
      titleMedium: AppTextStyles.h3,
      bodyLarge: AppTextStyles.body,
      bodyMedium: AppTextStyles.bodySmall,
      bodySmall: AppTextStyles.caption,
      labelLarge: AppTextStyles.button,
      labelSmall: AppTextStyles.label,
    ),

    // ── ElevatedButton ────────────────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style:
          ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: AppColors.white,
            minimumSize: const Size.fromHeight(50),
            padding: const EdgeInsets.symmetric(
              horizontal: Gap.s24,
              vertical: 14,
            ),
            textStyle: AppTextStyles.button,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ).copyWith(
            overlayColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return AppColors.white.withValues(alpha: 0.15);
              }
              return null;
            }),
          ),
    ),

    // ── FilledButton ──────────────────────────────────────────────────────────
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: AppColors.white,
        minimumSize: const Size(64, 44),
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.s20,
          vertical: Gap.s12,
        ),
        textStyle: AppTextStyles.button,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    // ── OutlinedButton ────────────────────────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: BorderSide(color: primary, width: 1.5),
        minimumSize: const Size.fromHeight(50),
        padding: const EdgeInsets.symmetric(horizontal: Gap.s24, vertical: 14),
        textStyle: AppTextStyles.button,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),

    // ── TextButton ────────────────────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primary,
        textStyle: AppTextStyles.button,
        padding: const EdgeInsets.symmetric(
          horizontal: Gap.s12,
          vertical: Gap.s8,
        ),
      ),
    ),

    // ── IconButton ────────────────────────────────────────────────────────────
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: AppColors.slate600),
    ),

    // ── Input / TextField ─────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceElevated,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Gap.s16,
        vertical: Gap.s16,
      ),
      hintStyle: AppTextStyles.body.copyWith(color: AppColors.slate400),
      labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.slate500),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.slate200, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.slate200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
    ),

    // ── Chip ──────────────────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.slate100,
      selectedColor: primary.withValues(alpha: 0.14),
      disabledColor: AppColors.slate100,
      labelStyle: AppTextStyles.bodySmall,
      secondaryLabelStyle: AppTextStyles.bodySmall.copyWith(color: primary),
      padding: const EdgeInsets.symmetric(
        horizontal: Gap.s12,
        vertical: Gap.s8,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.slate200, width: 1),
      ),
      selectedShadowColor: Colors.transparent,
      shadowColor: Colors.transparent,
    ),

    // ── Card ──────────────────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: AppColors.surfaceElevated,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider, width: 1),
      ),
      shadowColor: Colors.transparent,
    ),

    // ── BottomSheet ───────────────────────────────────────────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceElevated,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      showDragHandle: true,
      dragHandleColor: AppColors.slate300,
      dragHandleSize: Size(40, 4),
    ),

    // ── ListTile ──────────────────────────────────────────────────────────────
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(
        horizontal: Gap.s16,
        vertical: Gap.s8,
      ),
      minLeadingWidth: 40,
    ),

    // ── Divider ───────────────────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      space: 1,
      thickness: 1,
    ),

    // ── FloatingActionButton ──────────────────────────────────────────────────
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: AppColors.white,
      elevation: 2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    // ── SnackBar ──────────────────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.slate800,
      contentTextStyle: AppTextStyles.body.copyWith(color: AppColors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
    ),

    // ── Badge ─────────────────────────────────────────────────────────────────
    badgeTheme: const BadgeThemeData(
      backgroundColor: AppColors.success,
      textColor: AppColors.white,
    ),

    // ── NavigationBar ─────────────────────────────────────────────────────────
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      indicatorColor: primary.withValues(alpha: 0.12),
      elevation: 0,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => AppTextStyles.label.copyWith(
          color: states.contains(WidgetState.selected)
              ? primary
              : AppColors.slate500,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected)
              ? primary
              : AppColors.slate500,
        ),
      ),
    ),

    // ── Progress / Loading ────────────────────────────────────────────────────
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primary,
      linearTrackColor: primary.withValues(alpha: 0.12),
    ),
  );
}
