import 'package:flutter/material.dart';

class AppColors {
  // الألوان الأساسية
  static const Color background = Color(0xFF0F172A); // أزرق ليلي عميق جداً
  static const Color primary = Color(0xFF3B82F6); // أزرق احترافي
  static const Color accent = Color(0xFFF59E0B); // ذهبي للفت الانتباه والتنبيهات
  
  // ألوان البطاقات والخلفيات الثانوية (ممتازة لتأثير الزجاج)
  static const Color cardColor = Color(0xFF1E293B); 
  static const Color borderWhite = Colors.white12;
  
  // ألوان النصوص
  static const Color textMain = Colors.white;
  static const Color textMuted = Color(0xFF94A3B8);

  // ألوان الحالات (للفواتير)
  static const Color success = Color(0xFF10B981); // أخضر للدفعات المسددة
  static const Color danger = Color(0xFFEF4444); // أحمر للديون المتأخرة
}