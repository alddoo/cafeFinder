import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cafe_model.dart';
import '../services/auth_service.dart';
import '../services/cafe_service.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cafe_card.dart';
import '../widgets/cafe_image.dart';
import 'cafe_detail_screen.dart';
import 'search_screen.dart';

// Halaman Beranda (Dashboard) aplikasi yang berisi banner selamat datang, rekomendasi terpersonalisasi, filter kategori, dan daftar cafe terbaru
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService(); // Service autentikasi
  final _cafeService = CafeService(); // Service cafe
  String _selectedCategory =
      'Semua'; // Menyimpan kategori filter yang dipilih user
  List<CafeModel> _recommendations = []; // Menyimpan daftar cafe rekomendasi

  // Daftar kategori utama untuk filter beranda
  final List<String> _categories = [
    'Semua',
    'Kopi & Espresso',
    'Teh & Herbal',
    'Dessert & Kue',
    'Makan Siang',
    'Sarapan',
    'Outdoor',
    'Cozy & Nyaman',
    'Instagramable',
  ];

  @override
  void initState() {
    super.initState();
    // Memulai proses seeder database default dan memuat data user
    _seedAndLoad();
  }

  // Melakukan seeder awal database cafe Palembang dan memuat rekomendasi
  Future<void> _seedAndLoad() async {
    try {
      // Memasukkan data seeder cafe Palembang jika data masih kosong
      await _cafeService.seedPalembangCafes();
    } catch (e) {
      debugPrint('Error seeding Palembang cafes: $e');
    }
    await _loadUserData();
  }

  // Mengambil informasi preferensi pengguna untuk menghitung data rekomendasi cafe
  Future<void> _loadUserData() async {
    final user = _authService.currentUser;
    if (user != null) {
      final userData = await _authService.getUserData(user.uid);
      if (userData != null && mounted) {
        // Mengambil cafe rekomendasi berdasarkan kategori kesukaan pengguna
        final recs = await _cafeService.getRecommendations(
          userData.favoriteCategories,
        );
        if (mounted) setState(() => _recommendations = recs);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService
        .currentUser; // Mengambil user aktif dari service autentikasi

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: CustomScrollView(
        // Menggunakan CustomScrollView agar seluruh komponen halaman (appbar, list rekomendasi, filter, dan list cafe) bisa discroll bersamaan
        slivers: [
          // 1. Bagian Banner Header / App Bar (Profil Singkat User & Input Hint Pencarian)
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryColor, AppTheme.surfaceColor],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row Profil: Menampilkan sapaan nama pengguna dan inisial foto profil bulat
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${t('halo')} ${user?.displayName ?? 'Pengguna'} 👋',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            t('cari_cafe'),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      CircleAvatar(
                        backgroundColor: AppTheme.secondaryColor,
                        radius: 24,
                        child: Text(
                          (user?.displayName ?? 'U')[0].toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Bar Hint Pencarian: Widget interaktif yang mengarahkan user ke halaman SearchScreen saat di-tap
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            color: Colors.white70,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            t('cari_cafe_placeholder'),
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Bagian Rekomendasi Cafe (Hanya tampil jika ada cafe rekomendasi yang cocok dengan preferensi kopi user)
          if (_recommendations.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      t('rekomendasi_untukmu'),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Horisontal List View untuk menampilkan kartu-kartu cafe rekomendasi
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _recommendations.length,
                  itemBuilder: (ctx, i) {
                    final cafe = _recommendations[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CafeDetailScreen(cafe: cafe),
                        ),
                      ),
                      child: Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 14, bottom: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppTheme.cardBg, AppTheme.surfaceColor],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: cafe.imageUrl.isNotEmpty
                                  ? CafeImage(
                                      imageUrl: cafe.imageUrl,
                                      height: 100,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _placeholderImage(100),
                                    )
                                  : _placeholderImage(100),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cafe.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        cafe.reviewCount > 0
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: cafe.reviewCount > 0
                                            ? AppTheme.starColor
                                            : AppTheme.textSecondary,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        cafe.reviewCount > 0
                                            ? cafe.rating.toStringAsFixed(1)
                                            : '-',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // 3. Bagian Filter Kategori (Chips Kategori Horisontal)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    t('semua_cafe'),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (ctx, i) {
                  final cat = _categories[i];
                  final selected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(
                      () => _selectedCategory = cat,
                    ), // Mengubah filter kategori aktif
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primaryColor
                            : AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? AppTheme.primaryColor
                              : AppTheme.surfaceColor,
                        ),
                      ),
                      child: Text(
                        t(cat),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: selected
                              ? Colors.white
                              : AppTheme.textSecondary,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 4. Bagian Daftar Cafe Terdekat/Terbaru (SliverList dengan StreamBuilder Real-time dari Firestore)
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: StreamBuilder<List<CafeModel>>(
              stream: _cafeService
                  .getCafes(), // Mengalirkan data cafe real-time
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Text(
                        t('gagal_memuat'),
                        style: GoogleFonts.poppins(color: AppTheme.errorColor),
                      ),
                    ),
                  );
                }

                var cafes = snapshot.data ?? [];

                // Melakukan filter di sisi klien berdasarkan kategori yang dipilih
                if (_selectedCategory != 'Semua') {
                  cafes = cafes
                      .where((c) => c.category == _selectedCategory)
                      .toList();
                }

                if (cafes.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.coffee,
                              size: 60,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              t('belum_ada_cafe'),
                              style: GoogleFonts.poppins(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // Render list kartu cafe menggunakan widget CafeCard kustom
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: CafeCard(
                        cafe: cafes[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CafeDetailScreen(cafe: cafes[i]),
                          ),
                        ),
                      ),
                    ),
                    childCount: cafes.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget pembantu untuk merender placeholder gambar jika data URL gambar kosong
  Widget _placeholderImage(double height) {
    return Container(
      height: height,
      width: double.infinity,
      color: AppTheme.surfaceColor,
      child: const Icon(Icons.coffee, color: AppTheme.textSecondary, size: 30),
    );
  }
}
