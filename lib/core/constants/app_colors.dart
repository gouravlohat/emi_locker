import 'package:flutter/material.dart';

abstract class AppColors {
  // Brand
  static const primary = Color(0xFF1565C0);
  static const primaryLight = Color(0xFF1E88E5);
  static const primaryDark = Color(0xFF0D47A1);
  static const secondary = Color(0xFF00897B);

  // Status
  static const success = Color(0xFF2E7D32);
  static const successLight = Color(0xFF4CAF50);
  static const warning = Color(0xFFF57C00);
  static const warningLight = Color(0xFFFF9800);
  static const error = Color(0xFFC62828);
  static const errorLight = Color(0xFFF44336);
  static const info = Color(0xFF0277BD);

  // EMI Status
  static const paid = Color(0xFF2E7D32);
  static const pending = Color(0xFFF57C00);
  static const overdue = Color(0xFFC62828);
  static const locked = Color(0xFFB71C1C);
  static const unlocked = Color(0xFF1B5E20);

  // Neutral
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const grey50 = Color(0xFFFAFAFA);
  static const grey100 = Color(0xFFF5F5F5);
  static const grey200 = Color(0xFFEEEEEE);
  static const grey300 = Color(0xFFE0E0E0);
  static const grey400 = Color(0xFFBDBDBD);
  static const grey500 = Color(0xFF9E9E9E);
  static const grey600 = Color(0xFF757575);
  static const grey700 = Color(0xFF616161);
  static const grey800 = Color(0xFF424242);
  static const grey900 = Color(0xFF212121);

  // Dark theme surfaces
  static const darkBg = Color(0xFF0A0E1A);
  static const darkSurface = Color(0xFF141828);
  static const darkCard = Color(0xFF1C2235);
  static const darkBorder = Color(0xFF2A3147);

  // Gradient pairs
  static const List<Color> primaryGradient = [Color(0xFF1565C0), Color(0xFF0D47A1)];
  static const List<Color> lockedGradient = [Color(0xFFB71C1C), Color(0xFF7F0000)];
  static const List<Color> unlockedGradient = [Color(0xFF1B5E20), Color(0xFF2E7D32)];
  static const List<Color> warningGradient = [Color(0xFFE65100), Color(0xFFF57C00)];
  static const List<Color> cardGradient = [Color(0xFF1565C0), Color(0xFF1E88E5)];
}
