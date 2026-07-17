import 'package:flutter/material.dart';

/// Semantic color tokens. Screens should reference these, not raw hex
/// values, so light/dark stay in sync and meaning (income vs expense,
/// over-budget vs on-track) stays consistent everywhere.
class AppColors {
  AppColors._();

  static const Color seed = Color(0xFF3B5BFF);

  static const Color income = Color(0xFF16A34A);
  static const Color incomeDark = Color(0xFF4ADE80);

  static const Color expense = Color(0xFFDC2626);
  static const Color expenseDark = Color(0xFFF87171);

  static const Color warning = Color(0xFFD97706);
  static const Color warningDark = Color(0xFFFBBF24);

  static const List<Color> categoryPalette = [
    Color(0xFF3B5BFF),
    Color(0xFF16A34A),
    Color(0xFFD97706),
    Color(0xFFDB2777),
    Color(0xFF7C3AED),
    Color(0xFF0891B2),
    Color(0xFFEA580C),
    Color(0xFF4338CA),
    Color(0xFF059669),
    Color(0xFFB91C1C),
    Color(0xFF9333EA),
    Color(0xFF0D9488),
    Color(0xFF64748B),
  ];

  static Color categoryColor(String category) {
    final index = category.hashCode.abs() % categoryPalette.length;
    return categoryPalette[index];
  }
}
