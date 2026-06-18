import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cafe_model.dart';
import '../services/auth_service.dart';
import '../services/cafe_service.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cafe_image.dart';
import 'cafe_detail_screen.dart';

// Layar daftar cafe favorit pengguna (Favorite Screen) yang terhubung real-time dengan koleksi Firestore
class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService(); // Mengambil instance AuthService
    final cafeService = CafeService(); // Mengambil instance CafeService
    final user = authService.currentUser; // Pengguna saat ini yang masuk

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        title: Text(
          t('favorit'),
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        automaticallyImplyLeading: false, // Menghilangkan tombol back default
      ),
      body: user == null
          ? _buildNotLoggedIn(context) // Tampilan jika user belum masuk
          : StreamBuilder<List<String>>(
              // 1. Stream ID cafe favorit user dari koleksi user di Firestore
              stream: authService.getFavoriteCafeIds(user.uid),
              builder: (context, favSnap) {
                if (favSnap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.primaryColor),
                  );
                }

                final favoriteIds = favSnap.data ?? [];

                if (favoriteIds.isEmpty) {
                  return _buildEmpty(); // Tampilan jika daftar favorit kosong
                }

                return StreamBuilder<List<CafeModel>>(
                  // 2. Stream daftar lengkap seluruh cafe untuk dicocokkan dengan ID favorit
                  stream: cafeService.getCafes(),
                  builder: (context, cafeSnap) {
                    if (cafeSnap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primaryColor),
                      );
                    }

                    final allCafes = cafeSnap.data ?? [];
                    // Menyaring seluruh cafe yang ID-nya terdaftar di favorit user
                    final favoriteCafes = allCafes
                        .where((c) => favoriteIds.contains(c.id))
                        .toList();

                    if (favoriteCafes.isEmpty) {
                      return _buildEmpty();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                          child: Row(
                            children: [
                              Container(
                                  width: 4,
                                  height: 18,
                                  color: AppTheme.primaryColor),
                              const SizedBox(width: 10),
                              Text(
                                '${favoriteCafes.length} ${t('cafe_favorit')}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: favoriteCafes.length,
                            itemBuilder: (ctx, i) {
                              final cafe = favoriteCafes[i];
                              return _buildFavoriteCard(context, cafe,
                                  authService, user.uid);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildFavoriteCard(BuildContext context, CafeModel cafe,
      AuthService authService, String uid) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => CafeDetailScreen(cafe: cafe)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Gambar cafe
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: cafe.imageUrl.isNotEmpty
                  ? CafeImage(
                      imageUrl: cafe.imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderImage(),
                    )
                  : _placeholderImage(),
            ),
            // Info cafe
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cafe.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            cafe.category,
                            style: GoogleFonts.poppins(
                                color: AppTheme.primaryColor, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            cafe.address,
                            style: GoogleFonts.poppins(
                                color: AppTheme.textSecondary, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              cafe.reviewCount > 0 ? Icons.star : Icons.star_border,
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
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        // Tombol hapus favorit
                        GestureDetector(
                          onTap: () => authService.toggleFavorite(uid, cafe.id),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.favorite,
                                color: Colors.redAccent, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 100,
      height: 100,
      color: AppTheme.surfaceColor,
      child: const Icon(Icons.coffee, color: AppTheme.textSecondary, size: 36),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 80,
            color: AppTheme.textSecondary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            t('belum_ada_favorit'),
            style: GoogleFonts.poppins(
              color: AppTheme.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t('petunjuk_favorit'),
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppTheme.textSecondary.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedIn(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline,
              size: 70, color: AppTheme.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            t('login_untuk_favorit'),
            style: GoogleFonts.poppins(
                color: AppTheme.textSecondary, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
