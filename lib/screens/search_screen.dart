import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/cafe_model.dart';
import '../services/cafe_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cafe_card.dart';
import 'cafe_detail_screen.dart';

// Layar pencarian cafe (Search Screen) ter-filter berdasarkan rating, kategori, dan range harga
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();                 // Controller untuk input teks pencarian
  final _cafeService = CafeService();                                // Service pengolah data cafe
  List<CafeModel> _results = [];                                     // List untuk menyimpan hasil pencarian
  bool _isLoading = false;                                           // Status loading ketika mencari data
  String _sortBy = 'rating';                                         // Menyimpan tipe pengurutan ('rating' | 'priceAsc' | 'priceDesc')
  double _minPrice = 0;                                              // Batas harga minimum filter
  double _maxPrice = 100000;                                         // Batas harga maksimum filter
  String _filterCategory = '';                                       // Kategori yang disaring

  // Kumpulan kategori filter pencarian
  final List<String> _categories = [
    '',
    'Kopi & Espresso',
    'Teh & Herbal',
    'Dessert & Kue',
    'Makan Siang',
    'Sarapan',
    'Outdoor',
    'Cozy & Nyaman',
  ];

  // Melakukan pencarian data cafe dari Firestore dan mem-filter di sisi klien
  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isLoading = true);
    try {
      // 1. Mengambil data hasil pencarian nama/alamat awal
      var results = await _cafeService.searchCafes(query);

      // 2. Menyaring berdasarkan kategori terpilih (jika ada)
      if (_filterCategory.isNotEmpty) {
        results =
            results.where((c) => c.category == _filterCategory).toList();
      }

      // 3. Menyaring berdasarkan kisaran harga minimum dan maksimum
      results = results
          .where((c) =>
              c.priceMin >= _minPrice && c.priceMin <= _maxPrice)
          .toList();

      // 4. Mengurutkan hasil pencarian
      switch (_sortBy) {
        case 'rating':
          results.sort((a, b) => b.rating.compareTo(a.rating)); // Rating tertinggi dahulu
          break;
        case 'priceAsc':
          results.sort((a, b) => a.priceMin.compareTo(b.priceMin)); // Harga termurah dahulu
          break;
        case 'priceDesc':
          results.sort((a, b) => b.priceMin.compareTo(a.priceMin)); // Harga termahal dahulu
          break;
      }

      setState(() => _results = results);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.textSecondary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Filter & Urutan',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Sort
                  Text(
                    'Urutkan Berdasarkan',
                    style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: [
                      _sortChip('Rating', 'rating', setModalState),
                      _sortChip('Harga ↑', 'priceAsc', setModalState),
                      _sortChip('Harga ↓', 'priceDesc', setModalState),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Category
                  Text(
                    'Kategori',
                    style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final selected = _filterCategory == cat;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() => _filterCategory = cat);
                          setState(() => _filterCategory = cat);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.primaryColor
                                : AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            cat.isEmpty ? 'Semua' : cat,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: selected
                                  ? Colors.white
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  // Price Range
                  Text(
                    'Range Harga: Rp${_minPrice.toInt()} - Rp${_maxPrice.toInt()}',
                    style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  RangeSlider(
                    values: RangeValues(_minPrice, _maxPrice),
                    min: 0,
                    max: 100000,
                    divisions: 20,
                    activeColor: AppTheme.primaryColor,
                    inactiveColor: AppTheme.surfaceColor,
                    onChanged: (v) {
                      setModalState(() {
                        _minPrice = v.start;
                        _maxPrice = v.end;
                      });
                      setState(() {
                        _minPrice = v.start;
                        _maxPrice = v.end;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _search(_searchController.text);
                      },
                      child: const Text('Terapkan Filter'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sortChip(String label, String value, StateSetter setModalState) {
    final selected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setModalState(() => _sortBy = value);
        setState(() => _sortBy = value);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: selected ? Colors.white : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Text(
          'Cari Cafe',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppTheme.primaryColor),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cari berdasarkan nama, lokasi...',
                prefixIcon: const Icon(Icons.search,
                    color: AppTheme.primaryColor),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppTheme.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _results = []);
                        },
                      )
                    : null,
              ),
              onChanged: (v) {
                setState(() {});
                _search(v);
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryColor))
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search,
                                size: 80, color: AppTheme.textSecondary),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'Ketik untuk mencari cafe'
                                  : 'Tidak ada hasil ditemukan',
                              style: GoogleFonts.poppins(
                                  color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _results.length,
                        itemBuilder: (ctx, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: CafeCard(
                            cafe: _results[i],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CafeDetailScreen(cafe: _results[i]),
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
