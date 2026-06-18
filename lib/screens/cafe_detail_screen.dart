import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cafe_model.dart';
import '../models/review_model.dart';
import '../services/auth_service.dart';
import '../services/cafe_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cafe_image.dart';

// Layar detail cafe (Cafe Detail Screen) yang memuat informasi deskripsi, peta interaktif, daftar ulasan, menu makanan/minuman, fasilitas, serta form input ulasan dan rating
class CafeDetailScreen extends StatefulWidget {
  final CafeModel cafe; // Data cafe yang sedang dibuka detailnya

  const CafeDetailScreen({super.key, required this.cafe});

  @override
  State<CafeDetailScreen> createState() => _CafeDetailScreenState();
}

class _CafeDetailScreenState extends State<CafeDetailScreen>
    with SingleTickerProviderStateMixin {
  final _authService = AuthService(); // Service autentikasi user
  final _cafeService = CafeService(); // Service manajemen cafe
  final _reviewController =
      TextEditingController(); // Controller untuk input teks review
  double _userRating = 0; // Menyimpan nilai rating yang dipilih (1-5)
  bool _isSubmitting = false; // Status pengiriman review
  bool _isFavorite = false; // Status apakah cafe difavoritkan user
  bool _loadingFavorite = true; // Status loading pengecekan status favorit
  late TabController _tabController; // Pengontrol tab (Info, Menu, Ulasan)
  int _currentImageIndex = 0; // Indeks gambar banner yang sedang aktif

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _markAsVisited(); // Otomatis tandai cafe ini sebagai "pernah dikunjungi" oleh user
    _loadFavoriteStatus(); // Muat status apakah cafe ini masuk daftar favorit
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  // Membuka peta koordinat lokasi eksternal menggunakan Google Maps atau browser
  Future<void> _openMap(double latitude, double longitude) async {
    final url = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude",
    );
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      try {
        await launchUrl(url);
      } catch (e2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tidak dapat membuka peta: $e2',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  // Menandai cafe ini sebagai "pernah dikunjungi" oleh pengguna ke Firestore
  Future<void> _markAsVisited() async {
    final user = _authService.currentUser;
    if (user != null) {
      await _authService.addVisitedCafe(user.uid, widget.cafe.id);
    }
  }

  // Memeriksa status favorit cafe ini dari data pengguna saat ini di Firestore
  Future<void> _loadFavoriteStatus() async {
    final user = _authService.currentUser;
    if (user != null) {
      final fav = await _authService.isFavorite(user.uid, widget.cafe.id);
      if (mounted)
        setState(() {
          _isFavorite = fav;
          _loadingFavorite = false;
        });
    } else {
      if (mounted) setState(() => _loadingFavorite = false);
    }
  }

  // Menambahkan/menghapus cafe ini dari daftar favorit pengguna
  Future<void> _toggleFavorite() async {
    final user = _authService.currentUser;
    if (user == null) return;
    await _authService.toggleFavorite(user.uid, widget.cafe.id);
    if (mounted) setState(() => _isFavorite = !_isFavorite);
  }

  // Mengirim ulasan dan rating baru yang diinputkan pengguna ke Firestore
  Future<void> _submitReview() async {
    if (_userRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih rating terlebih dahulu'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tulis ulasan terlebih dahulu'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    try {
      final review = ReviewModel(
        id: '',
        cafeId: widget.cafe.id,
        userId: user.uid,
        userName: user.displayName ?? 'Pengguna',
        userPhoto: user.photoURL ?? '',
        rating: _userRating,
        comment: _reviewController.text.trim(),
        createdAt: DateTime.now(),
      );
      // Mengirim model review ke database
      await _cafeService.addReview(review);
      if (mounted) {
        _reviewController.clear();
        setState(() => _userRating = 0);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ulasan berhasil dikirim!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Menggunakan StreamBuilder agar data detail cafe (seperti rating, ulasan terbaru, dll) selalu sinkron secara real-time dari Firestore
    return StreamBuilder<CafeModel>(
      stream: _cafeService.getCafeStream(widget.cafe.id),
      initialData: widget.cafe,
      builder: (context, snapshot) {
        final cafe = snapshot.data ?? widget.cafe;
        // Penentuan daftar foto cafe yang akan ditampilkan di slider banner
        final displayImages = cafe.imageUrls.isNotEmpty
            ? cafe.imageUrls
            : (cafe.imageUrl.isNotEmpty ? [cafe.imageUrl] : <String>[]);

        return Scaffold(
          backgroundColor: AppTheme.darkBg,
          body: CustomScrollView(
            slivers: [
              // 2. Banner Header Interaktif (SliverAppBar) dengan gambar slider
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppTheme.darkBg,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Slider Foto Cafe (PageView) jika memiliki lebih dari 1 gambar
                      displayImages.isNotEmpty
                          ? PageView.builder(
                              itemCount: displayImages.length,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentImageIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                return CafeImage(
                                  imageUrl: displayImages[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: AppTheme.surfaceColor,
                                    child: const Icon(
                                      Icons.coffee,
                                      size: 80,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: AppTheme.surfaceColor,
                              child: const Icon(
                                Icons.coffee,
                                size: 80,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                      // Efek gelap transparan (Gradient) agar teks judul cafe tetap terbaca jelas
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                          ),
                        ),
                      ),
                      // Indikator Titik Halaman Foto
                      if (displayImages.length > 1)
                        Positioned(
                          bottom: 96,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              displayImages.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                height: 6,
                                width: _currentImageIndex == index ? 18 : 6,
                                decoration: BoxDecoration(
                                  color: _currentImageIndex == index
                                      ? AppTheme.primaryColor
                                      : Colors.white54,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Label Kategori, Nama Cafe, dan Alamat Cafe
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                cafe.category,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              cafe.name,
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    cafe.address,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                actions: [
                  // Tombol Tambah/Hapus dari Favorit
                  if (!_loadingFavorite)
                    GestureDetector(
                      onTap: _toggleFavorite,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            _isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            key: ValueKey(_isFavorite),
                            color: _isFavorite
                                ? Colors.redAccent
                                : Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // 3. Konten Utama Detail Cafe
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Baris Rating Bintang & Rentang Harga Cafe
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          // Bintang Rating
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: cafe.reviewCount > 0
                                ? Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: AppTheme.starColor,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        cafe.rating.toStringAsFixed(1),
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        ' (${cafe.reviewCount} ulasan)',
                                        style: GoogleFonts.poppins(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      const Icon(
                                        Icons.star_border,
                                        color: AppTheme.textSecondary,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Belum ada ulasan',
                                        style: GoogleFonts.poppins(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(width: 12),
                          // Rentang Estimasi Harga
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Idr ${cafe.priceMin.toInt()} - Idr ${cafe.priceMax.toInt()}',
                              style: GoogleFonts.poppins(
                                color: AppTheme.secondaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tab Bar Pilihan Konten (Info, Menu, Ulasan)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: AppTheme.primaryColor,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelColor: Colors.white,
                        unselectedLabelColor: AppTheme.textSecondary,
                        labelStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        tabs: const [
                          Tab(text: 'Info'),
                          Tab(text: 'Menu & Fasilitas'),
                          Tab(text: 'Ulasan'),
                        ],
                      ),
                    ),

                    // Konten Tab View yang Aktif
                    SizedBox(
                      height: 600,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: Menampilkan Deskripsi & Peta Mini Koordinat Cafe
                          _buildInfoTab(cafe),

                          // Tab 2: Menampilkan Daftar Menu & Fasilitas Cafe
                          _buildMenuFacilitiesTab(cafe),

                          // Tab 3: Menampilkan Form Beri Nilai & Daftar Ulasan Pengguna
                          _buildReviewsTab(cafe),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTab(CafeModel cafe) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tentang Cafe',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            cafe.description,
            style: GoogleFonts.poppins(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          _infoRow(Icons.location_on_outlined, 'Alamat', cafe.address),
          const SizedBox(height: 12),
          _infoRow(
            Icons.gps_fixed,
            'Koordinat',
            '${cafe.latitude}, ${cafe.longitude}',
          ),
          const SizedBox(height: 20),
          // ── MINI MAP SECTION ──
          Text(
            'Lokasi di Peta',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _buildMiniMap(cafe),
        ],
      ),
    );
  }

  Widget _buildMiniMap(CafeModel cafe) {
    final hasLocation = cafe.latitude != 0 && cafe.longitude != 0;
    return GestureDetector(
      onTap: hasLocation ? () => _openMap(cafe.latitude, cafe.longitude) : null,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFF1A2C3D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.surfaceColor),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Grid latar peta
              GridPaper(
                color: AppTheme.surfaceColor.withOpacity(0.3),
                divisions: 2,
                subdivisions: 3,
                child: const SizedBox.expand(),
              ),
              if (hasLocation)
                // Pin lokasi cafe di tengah
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.6),
                              blurRadius: 16,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.coffee,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      Container(
                        width: 0,
                        height: 0,
                        decoration: BoxDecoration(
                          border: Border(
                            left: const BorderSide(
                              color: Colors.transparent,
                              width: 8,
                            ),
                            right: const BorderSide(
                              color: Colors.transparent,
                              width: 8,
                            ),
                            top: BorderSide(
                              color: AppTheme.primaryColor,
                              width: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          cafe.name,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.location_off,
                        color: AppTheme.textSecondary,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Koordinat belum tersedia',
                        style: GoogleFonts.poppins(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              // Label koordinat
              Positioned(
                bottom: 10,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.gps_fixed,
                        color: Colors.white70,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasLocation
                            ? '${cafe.latitude.toStringAsFixed(4)}, ${cafe.longitude.toStringAsFixed(4)}'
                            : 'Tidak ada data',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Buka di Maps overlay label
              if (hasLocation)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Buka di Maps',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.open_in_new,
                          color: Colors.white,
                          size: 10,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuFacilitiesTab(CafeModel cafe) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Menu',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          if (cafe.menuItems.isEmpty)
            Text(
              'Belum ada menu',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            )
          else
            ...cafe.menuItems.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.restaurant_menu,
                      color: AppTheme.primaryColor,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      item,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          Text(
            'Fasilitas',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          if (cafe.facilities.isEmpty)
            Text(
              'Belum ada fasilitas',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: cafe.facilities
                  .map(
                    (f) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.5),
                        ),
                      ),
                      child: Text(
                        f,
                        style: GoogleFonts.poppins(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab(CafeModel cafe) {
    return Column(
      children: [
        // Write Review
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Beri Ulasan',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              // Star Rating
              Row(
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _userRating = star.toDouble()),
                    child: Icon(
                      star <= _userRating ? Icons.star : Icons.star_border,
                      color: AppTheme.starColor,
                      size: 34,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reviewController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tulis pengalamanmu...',
                  hintStyle: GoogleFonts.poppins(color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text('Kirim Ulasan', style: GoogleFonts.poppins()),
                ),
              ),
            ],
          ),
        ),

        // Review List
        Expanded(
          child: StreamBuilder<List<ReviewModel>>(
            stream: _cafeService.getReviews(cafe.id),
            builder: (ctx, snap) {
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error: ${snap.error}',
                      style: GoogleFonts.poppins(color: AppTheme.errorColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                );
              }
              final reviews = snap.data ?? [];
              if (reviews.isEmpty) {
                return Center(
                  child: Text(
                    'Belum ada ulasan',
                    style: GoogleFonts.poppins(color: AppTheme.textSecondary),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: reviews.length,
                itemBuilder: (ctx, i) {
                  final r = reviews[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppTheme.primaryColor,
                              child: Text(
                                r.userName[0].toUpperCase(),
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.userName,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Row(
                                    children: List.generate(
                                      5,
                                      (i) => Icon(
                                        i < r.rating.toInt()
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: AppTheme.starColor,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          r.comment,
                          style: GoogleFonts.poppins(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
