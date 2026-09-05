import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light Palette (Warm paper off-white)
  static const Color background = Color(0xFFFFFDFA);
  static const Color ink = Color(0xFF171514);
  static const Color inkMuted = Color(0xFF6B6661);
  static const Color inkLight = Color(0xFFABA49C);
  static const Color inkFaint = Color(0xFFE8E3DA);
  static const Color peach = Color(0xFFF0CDBD);
  static const Color sage = Color(0xFFD9E7CC);
  static const Color sand = Color(0xFFF6F2EB);
  static const Color errorMuted = Color(0xFFC84B31);

  // Dark Palette (Tactile slate paper)
  static const Color darkBackground = Color(0xFF141312);
  static const Color darkInk = Color(0xFFF5F2EC);
  static const Color darkInkMuted = Color(0xFFA8A29A);
  static const Color darkInkLight = Color(0xFF6E6962);
  static const Color darkInkFaint = Color(0xFF2C2926);
  static const Color darkPeach = Color(0xFFE09F85);
  static const Color darkSage = Color(0xFF8DAF7B);
  static const Color darkSand = Color(0xFF22201E);
  static const Color darkErrorMuted = Color(0xFFE05D43);

  // Hard offset shadow for tactile buttons
  static const List<BoxShadow> tactileShadow = [
    BoxShadow(color: ink, offset: Offset(3, 3), blurRadius: 0, spreadRadius: 0),
  ];

  static const List<BoxShadow> smallTactileShadow = [
    BoxShadow(color: ink, offset: Offset(2, 2), blurRadius: 0, spreadRadius: 0),
  ];

  // Typography Styles
  static TextStyle serifHeading({
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w600,
    Color color = ink,
    double letterSpacing = -0.5,
    double? height,
  }) {
    return GoogleFonts.fraunces(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle serifTimer({
    double fontSize = 54,
    FontWeight fontWeight = FontWeight.w700,
    Color color = ink,
    double letterSpacing = -1.0,
  }) {
    return GoogleFonts.fraunces(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle sansBody({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = ink,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle sansLabel({
    double fontSize = 11,
    FontWeight fontWeight = FontWeight.w600,
    Color color = inkMuted,
    double letterSpacing = 1.0,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: ink,
      colorScheme: const ColorScheme.light(
        primary: ink,
        secondary: peach,
        tertiary: sage,
        surface: background,
        onSurface: ink,
        error: errorMuted,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      dividerTheme: const DividerThemeData(
        color: inkFaint,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: darkInk,
      colorScheme: const ColorScheme.dark(
        primary: darkInk,
        secondary: darkPeach,
        tertiary: darkSage,
        surface: darkBackground,
        onSurface: darkInk,
        error: darkErrorMuted,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      dividerTheme: const DividerThemeData(
        color: darkInkFaint,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
    );
  }
}
