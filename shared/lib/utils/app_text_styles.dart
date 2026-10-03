import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Every text style in the project lives here — no TextStyle literals in UI code.
///
/// Scale: Display 28sp · H1 24sp · H2 20sp · H3 17sp · Body 15sp ·
///        BodySmall 13sp · Caption 11sp · Label 12sp · Button 15sp
///
/// Weight progression: Display/H1/H2 → w700, H3/Label/Button → w600,
///                     Body → w400, BodySmall/Caption → w400.
abstract final class AppTextStyles {
  static const display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.slate900,
  );

  static const h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.slate900,
  );

  static const h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.slate900,
  );

  static const h3 = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.slate800,
  );

  static const body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    color: AppColors.slate800,
    height: 1.5,
  );

  static const bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    color: AppColors.slate600,
    height: 1.45,
  );

  static const caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    color: AppColors.slate500,
    height: 1.4,
  );

  /// Used for chip labels, tags, micro-badges.
  static const label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    color: AppColors.slate700,
  );

  static const button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );
}

/// 4pt base spacing system — all multiples of 4.
abstract final class Gap {
  static const s2 = 2.0;
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
  static const s40 = 40.0;
  static const s48 = 48.0;
}

/// Shared border-radius constants.
abstract final class Radii {
  static const sm = BorderRadius.all(Radius.circular(8));
  static const md = BorderRadius.all(Radius.circular(12));
  static const lg = BorderRadius.all(Radius.circular(16));
  static const xl = BorderRadius.all(Radius.circular(20));
  static const xxl = BorderRadius.all(Radius.circular(28));
  static const pill = BorderRadius.all(Radius.circular(100));
}
