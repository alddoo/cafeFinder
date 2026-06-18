import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';

// Layar pendaftaran akun baru (Register Screen) beserta pemilihan preferensi kategori cafe
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();                          // Kunci form untuk validasi input
  final _nameController = TextEditingController();                   // Controller input nama
  final _emailController = TextEditingController();                  // Controller input email
  final _passwordController = TextEditingController();               // Controller input password
  final _confirmPasswordController = TextEditingController();        // Controller input konfirmasi password
  final _authService = AuthService();                                // Service autentikasi
  bool _isLoading = false;                                           // Status loading saat tombol daftar di-klik
  bool _obscurePassword = true;                                      // Mengontrol visibilitas teks password
  bool _obscureConfirm = true;                                       // Mengontrol visibilitas teks konfirmasi password

  // Daftar pilihan kategori preferensi cafe yang bisa dipilih pengguna
  final List<String> _categories = [
    'Kopi & Espresso',
    'Teh & Herbal',
    'Dessert & Kue',
    'Makan Siang',
    'Sarapan',
    'Outdoor',
    'Cozy & Nyaman',
    'Wi-Fi Kencang',
  ];
  final List<String> _selectedCategories = [];                       // Menyimpan daftar kategori yang dipilih user

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    // Inisialisasi animasi transisi layar
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    // Membersihkan controllers untuk mencegah kebocoran memori
    _fadeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Menjalankan proses pendaftaran akun
  Future<void> _register() async {
    // Validasi form input
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      // 1. Mendaftarkan user ke Firebase Authentication dan membuat dokumen user di Firestore
      final user = await _authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (user != null) {
        // 2. Jika ada kategori preferensi yang dipilih, simpan ke Firestore dokumen user
        if (_selectedCategories.isNotEmpty) {
          await _authService.updatePreferences(
              user.uid, _selectedCategories);
        }
        if (mounted) {
          // 3. Navigasi langsung masuk ke Halaman Utama (MainScreen)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        // Menampilkan pesan kegagalan pendaftaran
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t('registrasi_gagal')}: ${_parseError(e.toString())}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Menterjemahkan kode kesalahan pendaftaran Firebase Auth ke dalam bahasa yang ramah pengguna
  String _parseError(String error) {
    if (error.contains('email-already-in-use')) return 'Email sudah terdaftar';
    if (error.contains('weak-password')) return 'Password terlalu lemah';
    if (error.contains('invalid-email')) return 'Email tidak valid';
    return 'Terjadi kesalahan, coba lagi';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    t('buat_akun'),
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    t('bergabung_desc'),
                    style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 32),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: t('nama_lengkap'),
                            prefixIcon: const Icon(Icons.person_outline,
                                color: AppTheme.primaryColor),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? t('nama_wajib') : null,
                        ),
                        const SizedBox(height: 14),
                        // Email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: t('email'),
                            prefixIcon: const Icon(Icons.email_outlined,
                                color: AppTheme.primaryColor),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return t('email_wajib');
                            }
                            if (!v.contains('@')) return t('email_tidak_valid');
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        // Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: t('password'),
                            prefixIcon: const Icon(Icons.lock_outline,
                                color: AppTheme.primaryColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppTheme.textSecondary,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return t('password_wajib');
                            }
                            if (v.length < 6) {
                              return t('password_minimal');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        // Confirm Password
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: t('konfirmasi_password'),
                            prefixIcon: const Icon(Icons.lock_outline,
                                color: AppTheme.primaryColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppTheme.textSecondary,
                              ),
                              onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          validator: (v) {
                            if (v != _passwordController.text) {
                              return t('password_tidak_cocok');
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        // Kategori Preferensi
                        Text(
                          t('preferensi_cafe_opsional'),
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _categories.map((cat) {
                            final selected = _selectedCategories.contains(cat);
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (selected) {
                                    _selectedCategories.remove(cat);
                                  } else {
                                    _selectedCategories.add(cat);
                                  }
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
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
                                    fontSize: 12,
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
                          }).toList(),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
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
                                    t('daftar_sekarang'),
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              t('sudah_punya_akun_tanya'),
                              style: GoogleFonts.poppins(
                                  color: AppTheme.textSecondary),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text(
                                t('masuk'),
                                style: GoogleFonts.poppins(
                                  color: AppTheme.secondaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
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
          ),
        ),
      ),
    );
  }
}
