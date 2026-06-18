import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'add_cafe_screen.dart';
import 'favorite_screen.dart';
import 'profile_screen.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';
import '../services/language_service.dart';

// Widget layar utama yang memuat navigasi bar bawah (Bottom Navigation Bar) untuk berpindah halaman
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // Menyimpan indeks tab yang sedang aktif
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    await _notificationService.init();
    
    // Ambil preferensi pengguna dari Firestore untuk menyinkronkan notifikasi & bahasa
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            final notificationsEnabled = data['notificationsEnabled'] ?? true;
            final langCode = data['languageCode'] ?? 'id';
            
            // Set bahasa aktif aplikasi
            LanguageService.setLanguage(langCode);
            
            // Aktifkan listener notifikasi jika diizinkan
            if (notificationsEnabled) {
              _notificationService.startListeningToNewCafes();
            } else {
              _notificationService.stopListeningToNewCafes();
            }
            return;
          }
        }
      } catch (e) {
        print('Error memuat preferensi pengguna di MainScreen: $e');
      }
    }
    
    // Fallback default
    _notificationService.startListeningToNewCafes();
  }

  @override
  void dispose() {
    _notificationService.stopListeningToNewCafes();
    super.dispose();
  }

  // Daftar layar/halaman yang terhubung dengan bilah navigasi bawah
  final List<Widget> _screens = [
    const HomeScreen(),        // Tab 0: Halaman Beranda
    const SearchScreen(),      // Tab 1: Halaman Pencarian
    const AddCafeScreen(),     // Tab 2: Halaman Tambah Cafe Baru
    const FavoriteScreen(),    // Tab 3: Halaman Cafe Favorit
    const ProfileScreen(),     // Tab 4: Halaman Profil & Preferensi Kopi
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack digunakan agar state (kondisi scroll/data) dari setiap halaman tetap terjaga saat berpindah tab
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.cardBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 15,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i), // Mengubah tab aktif saat di-tap
          backgroundColor: AppTheme.cardBg,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textSecondary,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: t('beranda'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.search_outlined),
              activeIcon: const Icon(Icons.search),
              label: t('cari'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.add_circle_outline),
              activeIcon: const Icon(Icons.add_circle),
              label: t('tambah'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.favorite_border_rounded),
              activeIcon: const Icon(Icons.favorite_rounded),
              label: t('favorit'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: t('profil'),
            ),
          ],
        ),
      ),
    );
  }
}
