import 'package:flutter/material.dart';

// =============== DARK THEME COLORS ===============
class DarkThemeColors {
  // Primary Colors
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryVariant = Color(0xFF5A4FCF);
  static const Color secondary = Color(0xFFFF6B9D);
  static const Color secondaryVariant = Color(0xFFFF5788);

  // Background Colors
  static const Color background = Color(0xFF0F0F23);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceVariant = Color(0xFF16213E);
  static const Color cardBackground = Color(0xFF252547);

  // Text Colors
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFFE8E8E8);
  static const Color onSurface = Color(0xFFE8E8E8);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8CC);
  static const Color textHint = Color(0xFF6A6A8A);

  // Accent Colors
  static const Color accent1 = Color(0xFF00D4FF);
  static const Color accent2 = Color(0xFFFF9F43);
  static const Color accent3 = Color(0xFF32D74B);
  static const Color error = Color(0xFFFF453A);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color success = Color(0xFF30D158);

  // Border Colors
  static const Color border = Color(0xFF2D2D4A);
  static const Color borderLight = Color(0xFF3A3A5C);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFFFF6B9D), Color(0xFFFF8A80)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF5B73FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0F0F23), Color(0xFF1A1A2E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

// =============== LIGHT THEME COLORS ===============
class LightThemeColors {
  // Primary Colors
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryVariant = Color(0xFF5A4FCF);
  static const Color secondary = Color(0xFFFF6B9D);
  static const Color secondaryVariant = Color(0xFFFF5788);

  // Background Colors
  static const Color background = Color(0xFFFAFAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F6FA);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text Colors
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF1A1A2E);
  static const Color onSurface = Color(0xFF1A1A2E);
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textHint = Color(0xFF9DA4A8);

  // Accent Colors
  static const Color accent1 = Color(0xFF00B4D8);
  static const Color accent2 = Color(0xFFFF8C42);
  static const Color accent3 = Color(0xFF2ECC71);
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);
  static const Color success = Color(0xFF27AE60);

  // Border Colors
  static const Color border = Color(0xFFE0E6ED);
  static const Color borderLight = Color(0xFFF1F3F4);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFFFF6B9D), Color(0xFFFF8A80)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF5B73FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFFAFAFC), Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

// =============== THEME HELPER CLASS ===============
class AppColors {
  static bool _isDarkMode = true;

  static void setDarkMode(bool isDark) {
    _isDarkMode = isDark;
  }

  static bool get isDarkMode => _isDarkMode;

  // Dynamic colors based on theme
  static Color get primary =>
      _isDarkMode ? DarkThemeColors.primary : LightThemeColors.primary;
  static Color get primaryVariant => _isDarkMode
      ? DarkThemeColors.primaryVariant
      : LightThemeColors.primaryVariant;
  static Color get secondary =>
      _isDarkMode ? DarkThemeColors.secondary : LightThemeColors.secondary;
  static Color get background =>
      _isDarkMode ? DarkThemeColors.background : LightThemeColors.background;
  static Color get surface =>
      _isDarkMode ? DarkThemeColors.surface : LightThemeColors.surface;
  static Color get textPrimary =>
      _isDarkMode ? DarkThemeColors.textPrimary : LightThemeColors.textPrimary;
  static Color get textSecondary => _isDarkMode
      ? DarkThemeColors.textSecondary
      : LightThemeColors.textSecondary;
  static Color get textHint =>
      _isDarkMode ? DarkThemeColors.textHint : LightThemeColors.textHint;
  static Color get border =>
      _isDarkMode ? DarkThemeColors.border : LightThemeColors.border;
  static Color get error =>
      _isDarkMode ? DarkThemeColors.error : LightThemeColors.error;
  static Color get success =>
      _isDarkMode ? DarkThemeColors.success : LightThemeColors.success;
  static Color get cardBackground => _isDarkMode
      ? DarkThemeColors.cardBackground
      : LightThemeColors.cardBackground;

  // Dynamic gradients
  static LinearGradient get primaryGradient => _isDarkMode
      ? DarkThemeColors.primaryGradient
      : LightThemeColors.primaryGradient;
  static LinearGradient get secondaryGradient => _isDarkMode
      ? DarkThemeColors.secondaryGradient
      : LightThemeColors.secondaryGradient;
  static LinearGradient get accentGradient => _isDarkMode
      ? DarkThemeColors.accentGradient
      : LightThemeColors.accentGradient;
  static LinearGradient get backgroundGradient => _isDarkMode
      ? DarkThemeColors.backgroundGradient
      : LightThemeColors.backgroundGradient;
}

// Backward compatibility with old color names
const mainPurpleColor = Color(0xFF6C5CE7);
const mainOrangeColor = Color(0xFFFF6B9D);
const mainYellowColor = Color(0xFFFFD700);
const mainWhiteColor = Color(0xFFFFFFFF);
const gradientColor1 = LinearGradient(
  colors: [Color(0xFF6C5CE7), Color(0xFF74B9FF)],
);
