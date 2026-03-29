import 'package:flutter/material.dart';

class AppConfig {
  static const String apiBaseUrl = 'https://purl-production.up.railway.app';
}

class AppColors {
  static const Color bg = Color(0xFFF4F3F1);
  static const Color bgSecondary = Color(0xFFECEAE7);
  static const Color text = Color(0xFF2A2A2A);
  static const Color textSecondary = Color(0xFF636363);
  static const Color textMuted = Color(0xFF9C9C9C);
  static const Color accent = Color(0xFF8F847A);
  static const Color accentHover = Color(0xFF756B62);
  static const Color border = Color(0x0F000000);
  static const Color tonePositive = Color(0xFF5A8A6A);
  static const Color toneCritic = Color(0xFFC4644A);
  static const Color toneHold = Color(0xFF8A8A8A);

  // 밤하늘 테마 (궤적용)
  static const Color nightBg = Color(0xFF111318);
  static const Color nightText = Color(0xFFCCC9C4);
  static const Color nightTextSecondary = Color(0xFF8A8884);
  static const Color nightTextMuted = Color(0xFF5A5854);
  static const Color nightBorder = Color(0x0FFFFFFF);
  static const Color nightAccent = Color(0xFFA89E94);

  static Color toneColor(String tone) {
    switch (tone) {
      case 'positive':
        return tonePositive;
      case 'critic':
        return toneCritic;
      case 'hold':
        return toneHold;
      default:
        return toneHold;
    }
  }

  static String toneLabel(String tone) {
    switch (tone) {
      case 'positive':
        return '공감';
      case 'critic':
        return '비판';
      case 'hold':
        return '보류';
      default:
        return '보류';
    }
  }
}
