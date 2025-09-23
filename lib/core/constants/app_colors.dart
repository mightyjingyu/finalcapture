import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6B73FF);
  static const Color primaryLight = Color(0xFF9C9EFF);
  static const Color primaryDark = Color(0xFF3F51B5);
  
  // Secondary Colors
  static const Color secondary = Color(0xFFFF6B6B);
  static const Color secondaryLight = Color(0xFFFF9C9C);
  static const Color secondaryDark = Color(0xFFE53E3E);
  
  // Background Colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F4);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  // Status Colors
  static const Color success = Color(0xFF00C851);
  static const Color warning = Color(0xFFFFBB33);
  static const Color error = Color(0xFFFF4444);
  static const Color info = Color(0xFF33B5E5);
  
  // Category Colors
  static const List<Color> categoryColors = [
    Color(0xFF6B73FF), // 정보/참고용
    Color(0xFF00C851), // 대화/메시지
    Color(0xFFFFBB33), // 학습/업무 메모
    Color(0xFFFF6B6B), // 재미/밈/감정
    Color(0xFF33B5E5), // 일정/예약
    Color(0xFF9C27B0), // 증빙/거래
    Color(0xFFFF9800), // 옷
    Color(0xFF795548), // 제품
  ];
  
  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, surfaceVariant],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);
  static const Color shadowDark = Color(0x4D000000);
  
  // Border Colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF0F0F0);
  static const Color borderDark = Color(0xFFBDBDBD);
}
