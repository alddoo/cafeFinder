import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/cafe_service.dart';
import '../services/language_service.dart';
import '../services/notification_service.dart';
import '../models/user_model.dart';
import '../models/cafe_model.dart';
import '../theme/app_theme.dart';
import '../widgets/cafe_image.dart';
import 'login_screen.dart';
import 'cafe_detail_screen.dart';
import 'edit_profile_screen.dart';

// Layar Profil Pengguna (Profile Screen) yang menampilkan foto, info email, preferensi rasa kopi, cafe yang pernah dikunjungi, ubah password, dan opsi keluar (logout)
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService(); // Service autentikasi user
  final _cafeService = CafeService(); // Service manajemen cafe
  final _notificationService = NotificationService(); // Service notifikasi
  UserModel? _userData; // Menyimpan data profil user dari Firestore
  List<CafeModel> _visitedCafesList =
      []; // Menyimpan riwayat cafe yang dikunjungi
  bool _isLoading = true; // Status loading data
  bool _notificationsEnabled =
      true; // Status notifikasi cafe baru aktif/nonaktif

  // Daftar lengkap semua kategori pilihan preferensi rasa kopi
  final List<String> _allCategories = [
    'Kopi & Espresso',
    'Teh & Herbal',
    'Dessert & Kue',
    'Makan Siang',
    'Sarapan',
    'Outdoor',
    'Cozy & Nyaman',
    'Wi-Fi Kencang',
    'Sarapan Ringan',
  ];

  @override
  void initState() {
    super.initState();
    _loadUser(); // Memuat data user saat inisialisasi halaman
  }

  // Mengambil data pengguna dan cafe yang pernah dikunjungi secara asinkron
  Future<void> _loadUser() async {
    final user = _authService.currentUser;
    if (user != null) {
      final data = await _authService.getUserData(user.uid);
      List<CafeModel> visitedList = [];
      if (data != null && data.visitedCafes.isNotEmpty) {
        // Mengambil detail cafe dari database berdasarkan daftar ID cafe yang pernah dikunjungi
        visitedList = await _cafeService.getCafesByIds(data.visitedCafes);
      }
      if (mounted) {
        setState(() {
          _userData = data;
          _visitedCafesList = visitedList;
          if (data != null) {
            _notificationsEnabled = data.notificationsEnabled;
          }
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  // Menyimpan pembaruan kategori rasa kopi favorit pilihan pengguna ke Firestore
  Future<void> _savePreferences(List<String> categories) async {
    final user = _authService.currentUser;
    if (user != null) {
      await _authService.updatePreferences(user.uid, categories);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('preferensi_disimpan'), style: GoogleFonts.poppins()),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  // Melakukan logout dan mengembalikan pengguna ke halaman LoginScreen
  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text(
          t('keluar'),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          t('yakin_keluar'),
          style: GoogleFonts.poppins(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              t('batal'),
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _authService.logout();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            child: Text(
              t('keluar'),
              style: GoogleFonts.poppins(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = _authService.currentUser;

    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : CustomScrollView(
              slivers: [
                // Profile Header
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 20,
                      bottom: 32,
                      left: 20,
                      right: 20,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.primaryColor, AppTheme.surfaceColor],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: SizedBox(
                              width: 100,
                              height: 100,
                              child: _userData?.photoUrl.isNotEmpty == true
                                  ? CafeImage(
                                      imageUrl: _userData!.photoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, stack) =>
                                          _buildInitialsAvatar(
                                            firebaseUser?.displayName,
                                          ),
                                    )
                                  : _buildInitialsAvatar(
                                      firebaseUser?.displayName,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          firebaseUser?.displayName ?? 'Pengguna',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          firebaseUser?.email ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Stats Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _statItem(
                              '${_userData?.visitedCafes.length ?? 0}',
                              t('cafe_dikunjungi'),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white30,
                            ),
                            _statItem(
                              '${_userData?.favoriteCategories.length ?? 0}',
                              t('preferensi'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Preferences Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader(t('preferensi_cafe')),
                        const SizedBox(height: 14),
                        _PreferencesSelector(
                          allCategories: _allCategories,
                          selected: _userData?.favoriteCategories ?? [],
                          onSave: _savePreferences,
                        ),
                        const SizedBox(height: 28),

                        // Riwayat Cafe Dikunjungi Section
                        _sectionHeader(t('riwayat_kunjungan')),
                        const SizedBox(height: 14),
                        if (_visitedCafesList.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).cardTheme.color ??
                                  AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                t('belum_ada_riwayat'),
                                style: GoogleFonts.poppins(
                                  color: AppTheme.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _visitedCafesList.length,
                              itemBuilder: (context, index) {
                                final cafe = _visitedCafesList[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            CafeDetailScreen(cafe: cafe),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 260,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).cardTheme.color ??
                                          AppTheme.cardBg,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(16),
                                            bottomLeft: Radius.circular(16),
                                          ),
                                          child: CafeImage(
                                            imageUrl: cafe.imageUrl,
                                            width: 90,
                                            height: 120,
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  cafe.name,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.poppins(
                                                    color:
                                                        Theme.of(
                                                              context,
                                                            ).brightness ==
                                                            Brightness.dark
                                                        ? Colors.white
                                                        : Colors.black87,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  cafe.category,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.poppins(
                                                    color:
                                                        AppTheme.textSecondary,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      cafe.reviewCount > 0
                                                          ? Icons.star
                                                          : Icons.star_border,
                                                      color:
                                                          cafe.reviewCount > 0
                                                          ? AppTheme.starColor
                                                          : AppTheme
                                                                .textSecondary,
                                                      size: 14,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      cafe.reviewCount > 0
                                                          ? cafe.rating
                                                                .toStringAsFixed(
                                                                  1,
                                                                )
                                                          : '-',
                                                      style: GoogleFonts.poppins(
                                                        color:
                                                            Theme.of(
                                                                  context,
                                                                ).brightness ==
                                                                Brightness.dark
                                                            ? Colors.white
                                                            : Colors.black87,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
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
                              },
                            ),
                          ),
                        const SizedBox(height: 28),

                        _sectionHeader(t('pengaturan_akun')),
                        const SizedBox(height: 14),
                        _settingTile(
                          icon: Icons.person_outline,
                          label: t('edit_profil'),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditProfileScreen(userData: _userData),
                              ),
                            );
                            if (result == true) {
                              _loadUser();
                            }
                          },
                        ),
                        _settingTile(
                          icon: Icons.lock_outline,
                          label: t('ubah_password'),
                          onTap: _showChangePasswordDialog,
                        ),
                        _settingSwitchTile(
                          icon: Icons.notifications_none_rounded,
                          label: t('notifikasi_cafe_baru'),
                          value: _notificationsEnabled,
                          onChanged: (val) async {
                            setState(() {
                              _notificationsEnabled = val;
                            });
                            final user = _authService.currentUser;
                            if (user != null) {
                              await _authService.updateNotificationPreference(
                                user.uid,
                                val,
                              );
                              if (val) {
                                _notificationService.startListeningToNewCafes();
                              } else {
                                _notificationService.stopListeningToNewCafes();
                              }
                            }
                          },
                        ),
                        _settingTile(
                          icon: Icons.language_outlined,
                          label:
                              '${t('pilih_bahasa')}: ${LanguageService.currentLanguage == 'id' ? 'Bahasa Indonesia' : 'English'}',
                          onTap: _showLanguageDialog,
                        ),
                        _settingTile(
                          icon:
                              AppTheme.themeModeNotifier.value == ThemeMode.dark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          label:
                              AppTheme.themeModeNotifier.value == ThemeMode.dark
                              ? t('mode_terang')
                              : t('mode_gelap'),
                          onTap: () {
                            setState(() {
                              AppTheme.themeModeNotifier.value =
                                  AppTheme.themeModeNotifier.value ==
                                      ThemeMode.dark
                                  ? ThemeMode.light
                                  : ThemeMode.dark;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        // Logout Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _logout,
                            icon: const Icon(
                              Icons.logout,
                              color: AppTheme.errorColor,
                            ),
                            label: Text(
                              t('keluar'),
                              style: GoogleFonts.poppins(
                                color: AppTheme.errorColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppTheme.errorColor,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInitialsAvatar(String? displayName) {
    final name = displayName ?? 'U';
    return CircleAvatar(
      radius: 50,
      backgroundColor: AppTheme.secondaryColor.withOpacity(0.8),
      child: Text(
        name.isEmpty ? 'U' : name[0].toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                t('ubah_password'),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      enabled: !isSaving,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: t('password_baru'),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.length < 6) {
                          return t('password_minimal');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      enabled: !isSaving,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: t('konfirmasi_password'),
                        prefixIcon: const Icon(
                          Icons.lock_clock_outlined,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      validator: (v) {
                        if (v != passwordController.text) {
                          return t('password_tidak_cocok');
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: Text(
                    t('batal'),
                    style: GoogleFonts.poppins(color: AppTheme.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() => isSaving = true);

                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await _authService.changePassword(
                              passwordController.text.trim(),
                            );
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    t('password_berhasil'),
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: AppTheme.successColor,
                                ),
                              );
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              setDialogState(() => isSaving = false);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    t('password_gagal') + ': ${e.toString()}',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  backgroundColor: AppTheme.errorColor,
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          t('simpan'),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
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
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppTheme.primaryColor, size: 22),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: AppTheme.textSecondary,
          size: 14,
        ),
      ),
    );
  }

  Widget _settingSwitchTile({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor, size: 22),
        title: Text(
          label,
          style: GoogleFonts.poppins(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black87,
            fontSize: 14,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: AppTheme.primaryColor,
          inactiveThumbColor: AppTheme.textSecondary,
          inactiveTrackColor: AppTheme.cardBg.withOpacity(0.5),
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: Text(
          t('pilih_bahasa'),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                t('bahasa_indonesia'),
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              trailing: LanguageService.currentLanguage == 'id'
                  ? const Icon(Icons.check, color: AppTheme.primaryColor)
                  : null,
              onTap: () async {
                LanguageService.setLanguage('id');
                Navigator.pop(ctx);
                final user = _authService.currentUser;
                if (user != null) {
                  await _authService.updateLanguagePreference(user.uid, 'id');
                }
                if (mounted) setState(() {});
              },
            ),
            ListTile(
              title: Text(
                t('bahasa_inggris'),
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              trailing: LanguageService.currentLanguage == 'en'
                  ? const Icon(Icons.check, color: AppTheme.primaryColor)
                  : null,
              onTap: () async {
                LanguageService.setLanguage('en');
                Navigator.pop(ctx);
                final user = _authService.currentUser;
                if (user != null) {
                  await _authService.updateLanguagePreference(user.uid, 'en');
                }
                if (mounted) setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferencesSelector extends StatefulWidget {
  final List<String> allCategories;
  final List<String> selected;
  final Function(List<String>) onSave;

  const _PreferencesSelector({
    required this.allCategories,
    required this.selected,
    required this.onSave,
  });

  @override
  State<_PreferencesSelector> createState() => _PreferencesSelectorState();
}

class _PreferencesSelectorState extends State<_PreferencesSelector> {
  late List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.allCategories.map((cat) {
            final sel = _selected.contains(cat);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (sel) {
                    _selected.remove(cat);
                  } else {
                    _selected.add(cat);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: sel
                      ? AppTheme.primaryColor
                      : (Theme.of(context).cardTheme.color ?? AppTheme.cardBg),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sel
                        ? AppTheme.primaryColor
                        : (Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.surfaceColor
                              : const Color(0xFFE0E0E0)),
                  ),
                ),
                child: Text(
                  t(cat),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: sel
                        ? Colors.white
                        : (Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.textSecondary
                              : const Color(0xFF555555)),
                    fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => widget.onSave(_selected),
            child: Text(t('simpan_preferensi'), style: GoogleFonts.poppins()),
          ),
        ),
      ],
    );
  }
}
