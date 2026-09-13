import 'package:flutter/material.dart';

/// Brand palette. Royal blue leads, green confirms, white carries the surface.
abstract final class AppColors {
  static const Color primary = Color(0xFF0A6CFF);
  static const Color primaryDark = Color(0xFF0A4FBF);
  static const Color primaryLight = Color(0xFF5B9BFF);
  static const Color accent = Color(0xFF16A34A);
  static const Color accentDark = Color(0xFF0F7A37);

  static const Color white = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0B1220);
  static const Color inkMuted = Color(0xFF5A6675);

  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF6F8FB);
  static const Color outlineLight = Color(0xFFE3E8EF);

  static const Color surfaceDark = Color(0xFF141A22);
  static const Color backgroundDark = Color(0xFF0B1016);
  static const Color outlineDark = Color(0xFF263140);

  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color star = Color(0xFFFBBF24);
}
