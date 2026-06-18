import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cafe_image.dart';

// Layar untuk mengedit profil pengguna (Nama Lengkap dan Foto Profil)
class EditProfileScreen extends StatefulWidget {
  final UserModel? userData; // Menyimpan data profil user saat ini

  const EditProfileScreen({super.key, this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>(); // Kunci form untuk validasi inputan
  late TextEditingController _nameController; // Controller input Nama Lengkap
  late TextEditingController _emailController; // Controller input Email (Read-only)

  final _authService = AuthService(); // Instance service autentikasi
  final _picker = ImagePicker(); // Instance untuk memilih file gambar

  File? _selectedImage; // Menyimpan file gambar terpilih (untuk Mobile/Desktop)
  XFile? _selectedXFile; // Menyimpan metadata file gambar terpilih
  Uint8List? _selectedImageBytes; // Menyimpan data byte gambar terpilih (untuk Web)
  bool _isLoading = false; // Status loading saat proses simpan profil

  @override
  void initState() {
    super.initState();
    // Menginisialisasi input nama dan email dengan data pengguna saat ini
    _nameController = TextEditingController(text: widget.userData?.name ?? '');
    _emailController = TextEditingController(text: widget.userData?.email ?? '');
  }

  @override
  void dispose() {
    // Membersihkan controller untuk menghindari kebocoran memori (memory leak)
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Mengambil gambar dari sumber Kamera atau Galeri perangkat
  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedXFile = picked;
          _selectedImageBytes = bytes;
          // Di Web, kita tidak bisa menggunakan File(path), jadi hanya disimpan untuk platform non-web
          if (!kIsWeb) {
            _selectedImage = File(picked.path);
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e', style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // Menampilkan lembar opsi (Bottom Sheet) untuk memilih Kamera atau Galeri
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pilih Foto Profil',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Pilihan Mengambil dari Kamera
                  _pickerOption(
                    icon: Icons.camera_alt_outlined,
                    label: 'Kamera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  // Pilihan Mengambil dari Galeri
                  _pickerOption(
                    icon: Icons.photo_library_outlined,
                    label: 'Galeri',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget pembantu untuk merender tombol pilihan kamera/galeri di Bottom Sheet
  Widget _pickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppTheme.surfaceColor,
            child: Icon(icon, color: AppTheme.primaryColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // Menyimpan perubahan profil pengguna
  Future<void> _saveProfile() async {
    // 1. Memvalidasi input form
    if (!_formKey.currentState!.validate()) return;

    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // 2. Memanggil AuthService untuk memperbarui nama dan unggah gambar
      await _authService.updateProfile(
        uid: user.uid,
        name: _nameController.text.trim(),
        imageFile: kIsWeb ? null : _selectedImage,
        imageBytes: kIsWeb ? _selectedImageBytes : null,
        imageFileName: _selectedXFile?.name,
      );

      // 3. Menampilkan pesan sukses dan kembali ke halaman sebelumnya
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil berhasil diperbarui!', style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context, true); // Kirim nilai 'true' agar halaman profil memuat ulang data terbaru
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan profil: ${e.toString()}', style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasExistingPhoto = widget.userData?.photoUrl.isNotEmpty ?? false;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Text(
          'Edit Profil',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Area Pemilih Foto Profil
              GestureDetector(
                onTap: _isLoading ? null : _showImagePickerOptions,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primaryColor, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: SizedBox(
                          width: 120,
                          height: 120,
                          child: _selectedImageBytes != null
                              // Tampilkan gambar pratinjau yang baru dipilih
                              ? Image.memory(
                                  _selectedImageBytes!,
                                  fit: BoxFit.cover,
                                )
                              // Jika tidak ada gambar baru, tampilkan foto lama atau inisial nama
                              : hasExistingPhoto
                                  ? CafeImage(
                                      imageUrl: widget.userData!.photoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, stack) => _buildInitialsAvatar(),
                                    )
                                  : _buildInitialsAvatar(),
                        ),
                      ),
                    ),
                    // Icon Kamera melayang di atas foto profil
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.primaryColor,
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Form Input Nama Lengkap
              TextFormField(
                controller: _nameController,
                enabled: !_isLoading,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: const Icon(Icons.person, color: AppTheme.primaryColor),
                  fillColor: AppTheme.cardBg,
                  filled: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Nama lengkap tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Form Input Email (Read-Only agar email utama pengguna tidak berubah sembarangan)
              TextFormField(
                controller: _emailController,
                enabled: false,
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.textSecondary),
                  suffixIcon: const Icon(Icons.lock_outline, color: AppTheme.textSecondary, size: 18),
                  fillColor: AppTheme.cardBg.withOpacity(0.5),
                  filled: true,
                ),
              ),
              const SizedBox(height: 40),

              // Tombol Simpan Perubahan
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
                          'Simpan Perubahan',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget pembantu untuk merender inisial huruf nama depan ketika foto tidak ada
  Widget _buildInitialsAvatar() {
    final initials = widget.userData?.name.isNotEmpty == true
        ? widget.userData!.name[0].toUpperCase()
        : 'U';
    return Container(
      color: AppTheme.secondaryColor.withOpacity(0.8),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: GoogleFonts.poppins(
          fontSize: 50,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
