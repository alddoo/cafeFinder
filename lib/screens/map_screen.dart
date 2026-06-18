import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cafe_model.dart';
import '../services/cafe_service.dart';
import '../theme/app_theme.dart';
import 'cafe_detail_screen.dart';

// Layar Peta (Map Screen) untuk menampilkan pin cafe terdekat secara simulasi koordinat geospasial
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _cafeService = CafeService();                                // Service cafe
  List<CafeModel> _cafes = [];                                       // List penampung semua cafe dengan lokasi valid
  bool _isLoading = true;                                            // Status loading database
  CafeModel? _selectedCafe;                                          // Cafe yang sedang dipilih pin-nya

  @override
  void initState() {
    super.initState();
    _loadCafes(); // Memuat cafe dari Firestore
  }

  // Mengalirkan cafe dan menyaring cafe yang memiliki data koordinat latitude/longitude valid
  Future<void> _loadCafes() async {
    _cafeService.getCafes().listen((cafes) {
      if (mounted) {
        setState(() {
          _cafes = cafes.where((c) => c.latitude != 0 && c.longitude != 0).toList();
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Text(
          'Peta Cafe',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : Column(
              children: [
                // Map Placeholder (Google Maps memerlukan API key)
                Container(
                  height: 320,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.surfaceColor),
                  ),
                  child: Stack(
                    children: [
                      // Map background
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          color: const Color(0xFF1A2C3D),
                          child: GridPaper(
                            color: AppTheme.surfaceColor.withOpacity(0.3),
                            divisions: 2,
                            subdivisions: 3,
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                      // Cafe pins
                      ..._cafes.take(10).map((cafe) {
                        // Posisi relative (simulasi)
                        final index = _cafes.indexOf(cafe);
                        final x = 50.0 + (index % 3) * 100.0;
                        final y = 60.0 + (index ~/ 3) * 80.0;
                        return Positioned(
                          left: x,
                          top: y,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedCafe = cafe),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _selectedCafe?.id == cafe.id
                                        ? AppTheme.secondaryColor
                                        : AppTheme.primaryColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor.withOpacity(0.5),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.coffee, color: Colors.white, size: 16),
                                ),
                                Container(
                                  width: 0,
                                  height: 0,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      left: const BorderSide(color: Colors.transparent, width: 5),
                                      right: const BorderSide(color: Colors.transparent, width: 5),
                                      top: BorderSide(
                                        color: _selectedCafe?.id == cafe.id
                                            ? AppTheme.secondaryColor
                                            : AppTheme.primaryColor,
                                        width: 8,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      // Map label
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.info_outline, color: Colors.white70, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                '${_cafes.length} Cafe Ditemukan',
                                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Selected cafe card
                if (_selectedCafe != null)
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CafeDetailScreen(cafe: _selectedCafe!),
                      ),
                    ),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.surfaceColor],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.coffee, color: Colors.white, size: 30),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedCafe!.name,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  _selectedCafe!.address,
                                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      _selectedCafe!.reviewCount > 0 ? Icons.star : Icons.star_border,
                                      color: _selectedCafe!.reviewCount > 0 ? AppTheme.starColor : AppTheme.textSecondary,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _selectedCafe!.reviewCount > 0
                                          ? _selectedCafe!.rating.toStringAsFixed(1)
                                          : '-',
                                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
                // Cafe List (scrollable)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(width: 4, height: 16, color: AppTheme.accentColor),
                      const SizedBox(width: 10),
                      Text(
                        'Daftar Cafe dengan Lokasi',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _cafes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.map_outlined, size: 60, color: AppTheme.textSecondary),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada cafe dengan data lokasi',
                                style: GoogleFonts.poppins(color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _cafes.length,
                          itemBuilder: (ctx, i) {
                            final cafe = _cafes[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.cardBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                onTap: () {
                                  setState(() => _selectedCafe = cafe);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CafeDetailScreen(cafe: cafe),
                                    ),
                                  );
                                },
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.coffee, color: AppTheme.primaryColor, size: 24),
                                ),
                                title: Text(
                                  cafe.name,
                                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  '${cafe.latitude.toStringAsFixed(4)}, ${cafe.longitude.toStringAsFixed(4)}',
                                  style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 11),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      cafe.reviewCount > 0 ? Icons.star : Icons.star_border,
                                      color: cafe.reviewCount > 0 ? AppTheme.starColor : AppTheme.textSecondary,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      cafe.reviewCount > 0 ? cafe.rating.toStringAsFixed(1) : '-',
                                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
