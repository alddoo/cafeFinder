import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';
import 'main_screen.dart';

// Layar autentikasi masuk (Login Screen) untuk pengguna terdaftar
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();                  // Kunci form untuk validasi input
  final _emailController = TextEditingController();           // Controller input email
  final _passwordController = TextEditingController();        // Controller input password
  final _authService = AuthService();                        // Service autentikasi
  bool _isLoading = false;                                   // Status loading saat tombol masuk di-klik
  bool _obscurePassword = true;                              // Mengontrol visibilitas teks password

  // Pengendali Animasi Fade (Memudar) dan Slide (Menggeser) saat layar pertama kali dibuka
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    // Mengatur controller animasi
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
            begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    
    // Menjalankan animasi
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    // Membersihkan resources untuk menghindari kebocoran memori
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Melakukan login menggunakan AuthService
  Future<void> _login() async {
    // Memvalidasi field inputan
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final user = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (user != null && mounted) {
        // Navigasi ke halaman utama jika login sukses
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        // Menampilkan pesan error spesifik kepada user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t('login_gagal')}: ${_parseError(e.toString())}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Menerjemahkan kode error Firebase Auth ke dalam Bahasa Indonesia yang ramah pengguna
  String _parseError(String error) {
    if (error.contains('user-not-found')) return 'Pengguna tidak ditemukan';
    if (error.contains('wrong-password')) return 'Password salah';
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
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    // Logo & Title
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.accentColor
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.5),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                )
                              ],
                            ),
                            child: const Icon(Icons.coffee,
                                size: 50, color: Colors.white),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'CaféFinder',
                            style: GoogleFonts.poppins(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            t('jelajahi_cafe'),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      t('masuk'),
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t('selamat_datang_kembali'),
                      style: GoogleFonts.poppins(
                          color: AppTheme.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email Field
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
                          const SizedBox(height: 16),
                          // Password Field
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
                          const SizedBox(height: 32),
                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
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
                                      t('masuk'),
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                t('belum_punya_akun_tanya'),
                                style: GoogleFonts.poppins(
                                    color: AppTheme.textSecondary),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const RegisterScreen()),
                                ),
                                child: Text(
                                  t('daftar'),
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
      ),
    );
  }
}
