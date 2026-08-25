import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Core Color Palette
  static const Color background = Color(0xFFFFFDFA); // Warm paper off-white
  static const Color ink = Color(0xFF171514); // Primary black ink
  static const Color inkMuted = Color(0xFF6B6661); // Secondary text & metadata
  static const Color inkLight = Color(0xFFABA49C); // Inactive / placeholder
  static const Color inkFaint = Color(0xFFE8E3DA); // Subtle lines and borders
  static const Color peach = Color(0xFFF0CDBD); // Primary action accent
  static const Color sage = Color(0xFFD9E7CC); // Success / completed accent
  static const Color sand = Color(0xFFF6F2EB); // Neutral surface tint
  static const Color errorMuted = Color(0xFFC84B31); // Muted red for forfeit

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
}
