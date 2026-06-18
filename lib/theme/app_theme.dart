import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Kelas pengelola tema global aplikasi (Mendukung Dark Mode dan Light Mode)
class AppTheme {
  // Palet Warna Utama (Color Palette)
  static const Color primaryColor = Color(0xFF6B3FA0);    // Ungu (Warna Primer)
  static const Color secondaryColor = Color(0xFFE8A045);  // Oranye/Kuning (Warna Sekunder)
  static const Color accentColor = Color(0xFF4ECDC4);     // Toska (Warna Aksen)
  static const Color darkBg = Color(0xFF1A1A2E);          // Background Utama Mode Gelap
  static const Color cardBg = Color(0xFF16213E);          // Background Kartu Mode Gelap
  static const Color surfaceColor = Color(0xFF0F3460);     // Warna Permukaan Sekunder
  static const Color textPrimary = Color(0xFFF0F0F0);     // Warna Teks Utama (Gelap)
  static const Color textSecondary = Color(0xFFAAAAAA);   // Warna Teks Sekunder (Abu-abu)
  static const Color errorColor = Color(0xFFE74C3C);      // Warna Peringatan/Error
  static const Color successColor = Color(0xFF2ECC71);    // Warna Sukses/Berhasil
  static const Color starColor = Color(0xFFFFD700);       // Warna Bintang Rating (Emas)

  // Notifier untuk memantau status perubahan tema (default: Dark Mode)
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.dark);

  // Konfigurasi Tema Gelap (Dark Theme)
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: cardBg,
        error: errorColor,
      ),
      // Pengaturan gaya font teks Poppins untuk seluruh aplikasi
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          color: textPrimary,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: GoogleFonts.poppins(color: textPrimary),
        bodyMedium: GoogleFonts.poppins(color: textSecondary),
      ),
      // Pengaturan gaya bilah navigasi atas (AppBar)
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      // Pengaturan tombol utama (ElevatedButton)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      // Pengaturan dekorasi input teks (TextField)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: surfaceColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: surfaceColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(color: textSecondary),
        hintStyle: GoogleFonts.poppins(color: textSecondary),
      ),
      // Pengaturan tampilan kartu (Card)
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      // Pengaturan bilah navigasi bawah (BottomNavigationBar)
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardBg,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // Konfigurasi Tema Terang (Light Theme)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: Colors.white,
        error: errorColor,
      ),
      // Pengaturan teks tema terang
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          color: const Color(0xFF1E1E1E),
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: GoogleFonts.poppins(color: const Color(0xFF1E1E1E)),
        bodyMedium: GoogleFonts.poppins(color: const Color(0xFF555555)),
      ),
      // Pengaturan AppBar tema terang
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          color: const Color(0xFF1E1E1E),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1E1E1E)),
      ),
      // Pengaturan tombol tema terang
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      // Pengaturan dekorasi input teks tema terang
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(color: const Color(0xFF555555)),
        hintStyle: GoogleFonts.poppins(color: const Color(0xFF888888)),
      ),
      // Pengaturan Card tema terang
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      // Pengaturan BottomNavigationBar tema terang
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Color(0xFF888888),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
