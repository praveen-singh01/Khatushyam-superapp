import 'package:flutter/material.dart';

/// Design tokens from the Khatu Shyam Baba mockups.
abstract final class AppColors {
  static const Color canvas = Color(0xFFFFF9F2);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color orange = Color(0xFFE67E22);
  static const Color orangeDeep = Color(0xFFD35400);
  static const Color orangeSoft = Color(0xFFFFF0E3);
  static const Color ink = Color(0xFF3D2914);
  static const Color inkMuted = Color(0xFF8A7460);
  static const Color line = Color(0xFFF0E4D6);
  static const Color success = Color(0xFF2E8B57);
  static const Color successSoft = Color(0xFFE8F6EE);
  static const Color error = Color(0xFFC0392B);
  static const Color gold = Color(0xFFD4A017);

  // Compatibility aliases used across older widgets.
  static const Color accent = orange;
  static const Color accentSoft = orangeSoft;
  static const Color saffron = orange;
  static const Color softSaffron = orangeSoft;
  static const Color sacredRed = orangeDeep;
  static const Color marigold = gold;
  static const Color indigo = ink;
  static const Color paper = canvas;
  static const Color onSaffron = Color(0xFFFFFFFF);
  static const Color onIndigo = Color(0xFFFFFFFF);
  static const Color mutedIndigo = inkMuted;
}
