import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color background = Color(0xFF06110F);
  static const Color cardColor = Color(0xFF11231E);
  static const Color goldAccent = Color(0xFFE6C594); // A rich gold/beige color
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8E9F9C);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: goldAccent,
      colorScheme: const ColorScheme.dark(
        primary: goldAccent,
        surface: cardColor,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        bodyMedium: GoogleFonts.outfit(color: textPrimary),
        bodySmall: GoogleFonts.outfit(color: textSecondary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: goldAccent,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
      ),
    );
  }
}
