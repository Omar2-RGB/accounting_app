import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,
      brightness: Brightness.dark,
      
      // إعدادات الألوان العامة
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.cardColor,
      ),

      // إعدادات الخطوط لتعمل على كل التطبيق بخط كايرو
      textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme).copyWith(
        titleLarge: GoogleFonts.cairo(color: AppColors.textMain, fontWeight: FontWeight.bold),
        bodyLarge: GoogleFonts.cairo(color: AppColors.textMain),
        bodyMedium: GoogleFonts.cairo(color: AppColors.textMuted),
      ),

      // شكل موحد للحقول (TextFormFields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderWhite),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderWhite),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}