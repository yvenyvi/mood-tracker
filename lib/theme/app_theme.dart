import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Soft Pastels
  static const Color pastelBlue = Color(0xFFC7CEEA);
  static const Color pastelPink = Color(0xFFFFDAC1);
  static const Color pastelGreen = Color(0xFFB2F7EF);
  static const Color cream = Color(0xFFFDFD96);
  static const Color lavender = Color(0xFFE0BBE4);
  static const Color background = Color(0xFFFDFDFD);
  static const Color darkText = Color(0xFF4A4A4A);
}

class AppTheme {
  // Pastel Palette
  static const Color mintGreen = Color(0xFFB2F7EF);
  static const Color softPeach = Color(0xFFFFDAC1);
  static const Color lavender = Color(
    0xFFE2F0CB,
  ); // Actually more of a light green/yellow mix in some palettes, let's go with a true lavender
  static const Color trueLavender = Color(0xFFE0BBE4);
  static const Color skyBlue = Color(0xFF957DAD); // A muted purple-blue
  static const Color lightSkyBlue = Color(0xFFC7CEEA);

  static const Color backgroundWhite = Color(0xFFFDFDFD);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF4A4A4A);
  static const Color textGrey = Color(0xFF8D8D8D);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundWhite,
      primaryColor: lightSkyBlue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: lightSkyBlue,
        primary: lightSkyBlue,
        secondary: softPeach,
        surface: surfaceWhite,
        error: Color(0xFFFFB7B2), // Pastel Red
        onPrimary: textDark,
        onSecondary: textDark,
        onSurface: textDark,
      ),

      // Text Theme
      textTheme: GoogleFonts.poppinsTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            color: textDark,
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
          titleLarge: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
          bodyLarge: TextStyle(color: textDark, fontSize: 16),
          bodyMedium: TextStyle(color: textGrey, fontSize: 14),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Color.fromRGBO(158, 158, 158, 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: lightSkyBlue, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textGrey),
      ),

      // ElevatedButton Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightSkyBlue,
          foregroundColor: textDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF121212),
      primaryColor: skyBlue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: skyBlue,
        brightness: Brightness.dark,
        primary: skyBlue,
        secondary: lavender,
        surface: const Color(0xFF1E1E1E),
        error: const Color(0xFFCF6679),
        onPrimary: Colors.white,
        onSecondary: textDark,
        onSurface: Colors.white,
      ),

      // Text Theme
      textTheme: GoogleFonts.poppinsTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
          titleLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
          bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
          bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: skyBlue, width: 1.5),
        ),
        hintStyle: const TextStyle(color: Colors.white38),
      ),

      // ElevatedButton Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: skyBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }
}
