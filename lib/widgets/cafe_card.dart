import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cafe_model.dart';
import '../theme/app_theme.dart';
import 'cafe_image.dart';

// Widget kartu visual untuk menampilkan sekilas informasi cafe (Nama, Gambar, Rating, Alamat, Kategori, Harga)
class CafeCard extends StatelessWidget {
  final CafeModel cafe;       // Objek model data cafe
  final VoidCallback onTap;   // Callback aksi ketika kartu di-klik

  const CafeCard({
    super.key,
    required this.cafe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Memicu callback navigasi ke halaman detail
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tampilan Gambar Cafe di bagian atas kartu
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: cafe.imageUrl.isNotEmpty
                    ? CafeImage(
                        imageUrl: cafe.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _placeholder(), // Fallback jika gambar gagal dimuat
                      )
                    : _placeholder(), // Placeholder jika URL gambar kosong
              ),
            ),
            
            // 2. Tampilan Informasi Detail di bawah gambar
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama Cafe dan Rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          cafe.name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Tampilan Rating Bintang
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: cafe.reviewCount > 0
                              ? AppTheme.starColor.withOpacity(0.15)
                              : AppTheme.textSecondary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
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
                                color: cafe.reviewCount > 0
                                    ? AppTheme.starColor
                                    : AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  
                  // Alamat Cafe
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: AppTheme.textSecondary, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          cafe.address,
                          style: GoogleFonts.poppins(
                              color: AppTheme.textSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // Kategori Cafe dan Estimasi Harga Terendah
                  Row(
                    children: [
                      // Kategori Badge (misal: Outdoor, Cozy, dll)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          cafe.category,
                          style: GoogleFonts.poppins(
                            color: AppTheme.primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Teks Harga Terendah
                      Text(
                        'Rp${cafe.priceMin.toInt()}+',
                        style: GoogleFonts.poppins(
                          color: AppTheme.secondaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
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
  }

  // Tampilan cadangan (Placeholder) jika gambar gagal dimuat
  Widget _placeholder() {
    return Container(
      color: AppTheme.surfaceColor,
      child: const Center(
        child: Icon(Icons.coffee, size: 50, color: AppTheme.textSecondary),
      ),
    );
  }
}
