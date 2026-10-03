import 'package:flutter/material.dart';

/// Every color in the project lives here — no color literals in UI code.
abstract final class AppColors {
  // ── Brand primaries ────────────────────────────────────────────────────────
  /// Guru: deep ocean teal — confident, professional, modern.
  static const guruPrimary = Color(0xFF0A7EA4);

  /// Guru accent: lighter teal used for gradients and highlights.
  static const guruAccent = Color(0xFF38B2CC);

  /// Trainer: vivid coral-red — energetic, bold.
  static const trainerPrimary = Color(0xFFE85D4A);

  /// Trainer accent: soft coral used for gradients and highlights.
  static const trainerAccent = Color(0xFFFF8C7A);

  // ── Status ─────────────────────────────────────────────────────────────────
  static const success = Color(0xFF0D9B6C);
  static const warning = Color(0xFFF5A623);
  static const error = Color(0xFFD94040);

  // ── Surface & background ───────────────────────────────────────────────────
  /// Page background — very slightly warm off-white.
  static const surface = Color(0xFFF5F7FA);

  /// Elevated surface for cards / bottom sheets.
  static const surfaceElevated = Color(0xFFFFFFFF);

  /// Subtle dividers and borders.
  static const divider = Color(0xFFE2E8F0);

  // ── Neutral slate scale ────────────────────────────────────────────────────
  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const slate800 = Color(0xFF1E293B);
  static const slate900 = Color(0xFF0F172A);

  static const white = Colors.white;
  static const black = Colors.black;

  // ── Chat bubbles ───────────────────────────────────────────────────────────
  static const memberBubble = guruPrimary;
  static const trainerBubble = trainerPrimary;

  // ── Legacy aliases (keeps existing call-sites compiling) ──────────────────
  static const grey50 = slate50;
  static const grey100 = slate100;
  static const grey200 = slate200;
  static const grey300 = slate300;
  static const grey500 = slate500;
  static const grey700 = slate700;
  static const grey900 = slate900;
}
