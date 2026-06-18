import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';
import 'services/language_service.dart';

// Fungsi utama (main entry point) aplikasi Flutter
void main() async {
  // Memastikan binding widget Flutter sudah diinisialisasi sebelum Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Menginisialisasi Firebase berdasarkan opsi platform saat ini (Android/Web/Windows/dll)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Memulai eksekusi aplikasi CaféFinder
  runApp(const CafeFinderApp());
}

// Widget utama aplikasi (StatelessWidget)
class CafeFinderApp extends StatelessWidget {
  const CafeFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder mendengarkan perubahan tema gelap/terang secara dinamis
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeModeNotifier,
      builder: (context, currentMode, child) {
        // ValueListenableBuilder mendengarkan perubahan bahasa secara dinamis
        return ValueListenableBuilder<String>(
          valueListenable: LanguageService.languageNotifier,
          builder: (context, currentLang, child) {
            return MaterialApp(
              title: 'CaféFinder',
              debugShowCheckedModeBanner: false, // Menghilangkan banner debug
              theme: AppTheme.lightTheme,        // Tema terang
              darkTheme: AppTheme.theme,         // Tema gelap (default)
              themeMode: currentMode,            // Mode tema aktif saat ini
              
              // Mengarahkan tampilan awal berdasarkan status autentikasi Firebase Auth
              home: StreamBuilder<User?>(
                stream: FirebaseAuth.instance.authStateChanges(),
                builder: (context, snapshot) {
                  // Menampilkan loading screen jika status koneksi masih memeriksa login
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Scaffold(
                      backgroundColor: Color(0xFF1A1A2E),
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.coffee, size: 80, color: Color(0xFF6B3FA0)),
                            SizedBox(height: 20),
                            CircularProgressIndicator(color: Color(0xFF6B3FA0)),
                          ],
                        ),
                      ),
                    );
                  }
                  // Jika data user tersedia (sudah masuk/login), arahkan ke MainScreen
                  if (snapshot.hasData && snapshot.data != null) {
                    return const MainScreen();
                  }
                  // Jika belum login, arahkan ke halaman LoginScreen
                  return const LoginScreen();
                },
              ),
            );
          },
        );
      },
    );
  }
}
