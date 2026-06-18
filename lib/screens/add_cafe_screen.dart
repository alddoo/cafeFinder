import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/cafe_model.dart';
import '../services/auth_service.dart';
import '../services/cafe_service.dart';
import '../theme/app_theme.dart';

// Layar Tambah Cafe Baru (Add Cafe Screen) yang menyediakan form input data, unggah foto, pilih kategori, dan fasilitas
class AddCafeScreen extends StatefulWidget {
  const AddCafeScreen({super.key});

  @override
  State<AddCafeScreen> createState() => _AddCafeScreenState();
}

class _AddCafeScreenState extends State<AddCafeScreen> {
  final _formKey = GlobalKey<FormState>();                            // Kunci form untuk validasi inputan wajib
  final _nameController = TextEditingController();                     // Input nama cafe
  final _descController = TextEditingController();                     // Input deskripsi cafe
  final _addressController = TextEditingController();                 // Input alamat cafe
  final _latController = TextEditingController();                     // Input latitude lokasi cafe
  final _lngController = TextEditingController();                     // Input longitude lokasi cafe
  final _minPriceController = TextEditingController();                 // Input estimasi harga minimum
  final _maxPriceController = TextEditingController();                 // Input estimasi harga maksimum
  final _menuController = TextEditingController();                     // Input item menu tambahan

  final _authService = AuthService();                                  // Service autentikasi user
  final _cafeService = CafeService();                                  // Service pengolah data cafe
  final _picker = ImagePicker();                                       // Pengambil gambar dari galeri/kamera
  final _scrollController = ScrollController();                        // Pengontrol scroll form

  File? _selectedImage;                                                // Menyimpan file gambar terpilih (Non-Web)
  XFile? _selectedXFile;                                               // Menyimpan meta-data file gambar
  Uint8List? _selectedImageBytes;                                      // Menyimpan byte data gambar (untuk Web & Base64)
  bool _isLoading = false;                                             // Status loading saat submit data
  String _selectedCategory = 'Kopi & Espresso';                        // Kategori default cafe
  final List<String> _selectedFacilities = [];                         // Daftar fasilitas cafe yang dipilih
  final List<String> _menuItems = [];                                  // Daftar menu cafe yang ditambahkan

  // Pilihan kategori cafe
  final List<String> _categories = [
    'Kopi & Espresso',
    'Teh & Herbal',
    'Dessert & Kue',
    'Makan Siang',
    'Outdoor',
    'Cozy & Nyaman',
  ];

  // Pilihan fasilitas cafe
  final List<String> _facilityOptions = [
    'Wi-Fi',
    'Parkir',
    'AC',
    'Outdoor Area',
    'Live Music',
    'Non-Smoking',
    'Pet Friendly',
    'Prayer Room',
    'Meeting Room',
  ];

  // Membuka galeri foto dan memuat gambar yang dipilih pengguna
  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _selectedXFile = picked;
        _selectedImageBytes = bytes;
        if (!kIsWeb) {
          _selectedImage = File(picked.path);
        }
      });
    }
  }

  // Menambahkan item menu makanan/minuman ke daftar item menu cafe
  void _addMenuItem() {
    final menu = _menuController.text.trim();
    if (menu.isNotEmpty) {
      setState(() {
        _menuItems.add(menu);
        _menuController.clear();
      });
    }
  }

  // Mengirim data cafe baru ke Firestore beserta foto cafe (jika ada)
  Future<void> _submitCafe() async {
    debugPrint('=== SUBMIT CAFE DIPANGGIL ===');

    // 1. Validasi inputan form
    final isValid = _formKey.currentState!.validate();
    debugPrint('Validasi: $isValid');
    debugPrint('Nama: "${_nameController.text}"');
    debugPrint('Deskripsi: "${_descController.text}"');
    debugPrint('Alamat: "${_addressController.text}"');

    if (!isValid) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Harap lengkapi semua field yang wajib diisi',
              style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // 2. Memastikan user terautentikasi sebelum bisa menambahkan cafe
    final user = _authService.currentUser;
    debugPrint('User: ${user?.uid ?? "NULL - belum login!"}');
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silakan login terlebih dahulu',
              style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    debugPrint('Loading dimulai...');

    try {
      // 3. Mengemas data input ke model CafeModel
      final cafe = CafeModel(
        id: '',
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        address: _addressController.text.trim(),
        latitude: double.tryParse(_latController.text) ?? 0,
        longitude: double.tryParse(_lngController.text) ?? 0,
        imageUrl: '',
        imageUrls: const [],
        menuItems: _menuItems,
        priceMin: double.tryParse(_minPriceController.text) ?? 0,
        priceMax: double.tryParse(_maxPriceController.text) ?? 0,
        facilities: _selectedFacilities,
        ownerId: user.uid,
        rating: 0,
        reviewCount: 0,
        category: _selectedCategory,
        tags: [],
        createdAt: DateTime.now(),
      );

      debugPrint('Memanggil addCafe...');
      // 4. Memanggil service untuk menyimpan data ke Firestore & Storage
      await _cafeService.addCafe(
        cafe,
        imageFile: kIsWeb ? null : _selectedImage,
        imageBytes: kIsWeb ? _selectedImageBytes : null,
        imageFileName: _selectedXFile?.name,
      );
      debugPrint('addCafe BERHASIL!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cafe berhasil ditambahkan!',
                style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _clearForm(); // Mengosongkan form input jika sukses
      }
    } on FirebaseException catch (e) {
      debugPrint('FirebaseException: code=${e.code}, msg=${e.message}');
      if (mounted) {
        String pesan;
        if (e.code == 'permission-denied') {
          pesan = 'Akses ditolak. Periksa Firebase Rules.';
        } else if (e.code == 'storage/unauthorized') {
          pesan = 'Upload foto gagal: tidak ada izin.';
        } else {
          pesan = 'Firebase error [${e.code}]: ${e.message}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(pesan, style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('ERROR TIDAK DIKENAL: $e');
      debugPrint('Stack: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${e.toString()}',
                style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      debugPrint('Finally: reset loading');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Mengosongkan semua field input form dan pilihan status setelah berhasil ditambahkan
  void _clearForm() {
    _nameController.clear();
    _descController.clear();
    _addressController.clear();
    _latController.clear();
    _lngController.clear();
    _minPriceController.clear();
    _maxPriceController.clear();
    setState(() {
      _selectedImage = null;
      _selectedXFile = null;
      _selectedImageBytes = null;
      _menuItems.clear();
      _selectedFacilities.clear();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _menuController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Text('Tambah Cafe',
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppTheme.surfaceColor, width: 2),
                  ),
                  child: _selectedImageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.memory(
                            _selectedImageBytes!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo,
                                color: AppTheme.primaryColor, size: 40),
                            const SizedBox(height: 10),
                            Text(
                              'Tap untuk pilih foto cafe',
                              style: GoogleFonts.poppins(
                                  color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              _sectionLabel('Informasi Dasar'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _nameController,
                label: 'Nama Cafe',
                icon: Icons.store,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _descController,
                label: 'Deskripsi',
                icon: Icons.description_outlined,
                maxLines: 3,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Deskripsi wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _addressController,
                label: 'Alamat',
                icon: Icons.location_on_outlined,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Alamat wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              _sectionLabel('Lokasi (Koordinat)'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _latController,
                      label: 'Latitude',
                      icon: Icons.gps_fixed,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _lngController,
                      label: 'Longitude',
                      icon: Icons.gps_not_fixed,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _sectionLabel('Kategori'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: AppTheme.cardBg,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.category_outlined,
                      color: AppTheme.primaryColor),
                  filled: true,
                  fillColor: AppTheme.cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppTheme.surfaceColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppTheme.surfaceColor),
                  ),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(c,
                              style: GoogleFonts.poppins(
                                  color: Colors.white)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 20),
              _sectionLabel('Harga'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _minPriceController,
                      label: 'Harga Min (Rp)',
                      icon: Icons.payments_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _maxPriceController,
                      label: 'Harga Max (Rp)',
                      icon: Icons.payments,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _sectionLabel('Fasilitas'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _facilityOptions.map((f) {
                  final selected = _selectedFacilities.contains(f);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _selectedFacilities.remove(f);
                        } else {
                          _selectedFacilities.add(f);
                        }
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
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
                        f,
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
              _sectionLabel('Menu'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _menuController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Tambah item menu',
                        prefixIcon: const Icon(Icons.restaurant_menu,
                            color: AppTheme.primaryColor),
                        filled: true,
                        fillColor: AppTheme.cardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppTheme.surfaceColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppTheme.surfaceColor),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _addMenuItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
              if (_menuItems.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _menuItems
                      .map((item) => Chip(
                            label: Text(item,
                                style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 12)),
                            backgroundColor: AppTheme.surfaceColor,
                            deleteIcon: const Icon(Icons.close,
                                size: 16, color: Colors.white70),
                            onDeleted: () =>
                                setState(() => _menuItems.remove(item)),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitCafe,
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Tambah Cafe',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
      ),
      validator: validator,
    );
  }
}
