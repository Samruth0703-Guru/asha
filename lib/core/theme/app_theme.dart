import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // Color Palette as defined in the visual specs
  static const Color primaryColor = Color(0xff2563eb);       // Primary Royal Blue
  static const Color secondaryColor = Color(0xff10b981);     // Secondary Emerald Green
  static const Color warningColor = Color(0xfff59e0b);       // Warning Amber
  static const Color dangerColor = Color(0xffef4444);        // Danger Red
  static const Color successColor = Color(0xff10b981);       // Success Green

  // Light Theme Surfaces
  static const Color backgroundColor = Color(0xfff8fafc);    // Soft Slate Gray
  static const Color cardColor = Colors.white;
  static const double cardRadius = 24.0;

  // Dark Theme Surfaces
  static const Color darkBackgroundColor = Color(0xff0b0f19); // Sleek Slate Midnight
  static const Color darkCardColor = Color(0xff151e2e);       // Deep Charcoal Card

  static ThemeData get lightTheme {
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: const ColorScheme.light(
          primary: primaryColor,
          secondary: secondaryColor,
          error: dangerColor,
          surface: cardColor,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
      );
    }
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: dangerColor,
        surface: cardColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: const Color(0xff0f172a),
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: Color(0xff0f172a)),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xfff1f5f9), width: 1.5),
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: Color(0xffe2e8f0), width: 1.5),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18.0),
          borderSide: const BorderSide(color: Color(0xffe2e8f0), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18.0),
          borderSide: const BorderSide(color: Color(0xffe2e8f0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18.0),
          borderSide: const BorderSide(color: primaryColor, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18.0),
          borderSide: const BorderSide(color: dangerColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        labelStyle: GoogleFonts.inter(color: const Color(0xff64748b), fontSize: 14),
        floatingLabelStyle: GoogleFonts.inter(color: primaryColor, fontWeight: FontWeight.w600),
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme.copyWith(
          displayLarge: GoogleFonts.inter(fontSize: 34, fontWeight: FontWeight.w800, color: const Color(0xff0f172a), letterSpacing: -1.0),
          displayMedium: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: const Color(0xff0f172a), letterSpacing: -0.8),
          titleLarge: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xff0f172a), letterSpacing: -0.4),
          titleMedium: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xff0f172a), letterSpacing: -0.2),
          bodyLarge: GoogleFonts.inter(fontSize: 16, color: const Color(0xff0f172a), height: 1.5),
          bodyMedium: GoogleFonts.inter(fontSize: 14, color: const Color(0xff475569), height: 1.4),
          labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xff64748b)),
          labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xff64748b)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: primaryColor,
        scaffoldBackgroundColor: darkBackgroundColor,
        colorScheme: const ColorScheme.dark(
          primary: primaryColor,
          secondary: secondaryColor,
          error: dangerColor,
          surface: darkCardColor,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
      );
    }
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackgroundColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        error: dangerColor,
        surface: darkCardColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: darkCardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0xff1f2937), width: 1.5),
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Color(0xff374151), width: 1.5),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xff111827),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18.0),
          borderSide: const BorderSide(color: Color(0xff374151), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18.0),
          borderSide: const BorderSide(color: Color(0xff374151), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18.0),
          borderSide: const BorderSide(color: primaryColor, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18.0),
          borderSide: const BorderSide(color: dangerColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        labelStyle: GoogleFonts.inter(color: const Color(0xff9ca3af), fontSize: 14),
        floatingLabelStyle: GoogleFonts.inter(color: primaryColor, fontWeight: FontWeight.w600),
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: GoogleFonts.inter(fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1.0),
          displayMedium: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.8),
          titleLarge: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.4),
          titleMedium: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: -0.2),
          bodyLarge: GoogleFonts.inter(fontSize: 16, color: const Color(0xffe5e7eb), height: 1.5),
          bodyMedium: GoogleFonts.inter(fontSize: 14, color: const Color(0xff9ca3af), height: 1.4),
          labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xff9ca3af)),
          labelMedium: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xff9ca3af)),
        ),
      ),
    );
  }
}
