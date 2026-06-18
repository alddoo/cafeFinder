import 'package:flutter/material.dart';

// Fungsi global untuk mempermudah pemanggilan terjemahan di seluruh widget
String t(String key) {
  return LanguageService.translate(key);
}

// Service untuk mengelola multi-bahasa (lokalisasi) secara dinamis di dalam aplikasi
class LanguageService {
  // Notifier untuk memantau perubahan bahasa aktif saat ini (default: 'id' / Bahasa Indonesia)
  static final ValueNotifier<String> languageNotifier = ValueNotifier<String>('id');

  // Mendapatkan kode bahasa yang sedang aktif
  static String get currentLanguage => languageNotifier.value;

  // Mengubah bahasa dan memberi tahu seluruh sistem untuk membangun ulang (rebuild) UI
  static void setLanguage(String langCode) {
    if (langCode == 'id' || langCode == 'en') {
      languageNotifier.value = langCode;
    }
  }

  // Mengambil teks terjemahan berdasarkan kunci (key) dan bahasa aktif
  static String translate(String key) {
    final lang = languageNotifier.value;
    return _translations[lang]?[key] ?? _translations['id']?[key] ?? key;
  }

  // Peta (Map) data terjemahan untuk Bahasa Indonesia ('id') dan Bahasa Inggris ('en')
  static const Map<String, Map<String, String>> _translations = {
    'id': {
      // Navigasi & Umum
      'app_name': 'CaféFinder',
      'beranda': 'Beranda',
      'cari': 'Cari',
      'tambah': 'Tambah',
      'favorit': 'Favorit',
      'profil': 'Profil',
      'batal': 'Batal',
      'simpan': 'Simpan',
      'keluar': 'Keluar',
      'yakin_keluar': 'Yakin ingin keluar?',

      // Halaman Login & Register
      'masuk': 'Masuk',
      'daftar': 'Daftar',
      'email': 'Email',
      'password': 'Password',
      'nama_lengkap': 'Nama Lengkap',
      'belum_punya_akun': 'Belum punya akun? Daftar',
      'sudah_punya_akun': 'Sudah punya akun? Masuk',
      'silakan_login': 'Silakan masuk ke akun Anda',
      'buat_akun': 'Buat akun baru Anda',
      'email_tidak_valid': 'Email tidak valid',
      'password_pendek': 'Password minimal 6 karakter',
      'nama_kosong': 'Nama tidak boleh kosong',
      'login_gagal': 'Gagal masuk',
      'register_gagal': 'Gagal mendaftar',
      'selamat_datang_kembali': 'Selamat datang kembali!',
      'belum_punya_akun_tanya': 'Belum punya akun? ',
      'sudah_punya_akun_tanya': 'Sudah punya akun? ',
      'email_wajib': 'Email wajib diisi',
      'password_wajib': 'Password wajib diisi',
      'nama_wajib': 'Nama wajib diisi',
      'daftar_sekarang': 'Daftar Sekarang',
      'preferensi_cafe_opsional': 'Preferensi Cafe (opsional)',
      'bergabung_desc': 'Bergabung untuk menemukan cafe favoritmu!',
      'registrasi_gagal': 'Registrasi gagal',

      // Halaman Beranda (Home)
      'halo': 'Hai,',
      'rekomendasi_untukmu': 'Rekomendasi Untukmu',
      'jelajahi_cafe': 'Jelajahi Cafe terdekat',
      'semua': 'Semua',
      'cari_cafe_placeholder': 'Cari nama cafe, alamat, atau menu...',
      'cari_cafe': 'Cari cafe favoritmu hari ini!',
      'semua_cafe': 'Semua Cafe',
      'gagal_memuat': 'Gagal memuat data',
      'belum_ada_cafe': 'Belum ada cafe tersedia',
      'cafe_favorit': 'Cafe Favorit',
      'belum_ada_favorit': 'Belum ada cafe favorit',
      'petunjuk_favorit': 'Tekan ikon ♡ di halaman detail cafe\nuntuk menambahkan ke favorit',
      'login_untuk_favorit': 'Login untuk melihat favorit',

      // Halaman Tambah Cafe
      'tambah_cafe_baru': 'Tambah Cafe Baru',
      'nama_cafe': 'Nama Cafe',
      'deskripsi': 'Deskripsi',
      'alamat': 'Alamat',
      'kategori': 'Kategori',
      'koordinat': 'Koordinat',
      'ambil_lokasi': 'Ambil Lokasi Saat Ini',
      'pilih_foto': 'Pilih Foto Utama',
      'fasilitas': 'Fasilitas',
      'estimasi_harga': 'Estimasi Harga (Min - Max)',
      'simpan_cafe': 'Simpan Cafe',
      'nama_cafe_kosong': 'Nama cafe tidak boleh kosong',
      'deskripsi_kosong': 'Deskripsi tidak boleh kosong',
      'alamat_kosong': 'Alamat tidak boleh kosong',
      'harga_min_kosong': 'Harga minimal tidak boleh kosong',
      'harga_max_kosong': 'Harga maksimal tidak boleh kosong',
      'foto_kosong': 'Silakan pilih foto utama cafe',
      'cafe_berhasil_ditambah': 'Cafe baru berhasil ditambahkan!',

      // Halaman Detail Cafe
      'ulasan': 'Ulasan',
      'tambah_ulasan': 'Tambah Ulasan',
      'fasilitas_title': 'Fasilitas',
      'menu_title': 'Menu Populer',
      'lokasi_title': 'Lokasi',
      'petunjuk_arah': 'Petunjuk Arah',
      'rating_dan_ulasan': 'Rating & Ulasan',
      'tulis_ulasan_disini': 'Tulis ulasan Anda di sini...',
      'beri_rating': 'Beri Rating',
      'kirim': 'Kirim',
      'ulasan_kosong': 'Ulasan tidak boleh kosong',
      'ulasan_berhasil': 'Ulasan berhasil ditambahkan!',

      // Halaman Profil (Profile)
      'riwayat_kunjungan': 'Riwayat Cafe Dikunjungi',
      'belum_ada_riwayat': 'Belum ada riwayat kunjungan.',
      'pengaturan_akun': 'Pengaturan Akun',
      'edit_profil': 'Edit Profil',
      'ubah_password': 'Ubah Password',
      'mode_terang': 'Mode Terang',
      'mode_gelap': 'Mode Gelap',
      'preferensi_cafe': 'Preferensi Cafe',
      'preferensi_disimpan': 'Preferensi disimpan!',
      'simpan_preferensi': 'Simpan Preferensi',
      'cafe_dikunjungi': 'Cafe Dikunjungi',
      'preferensi': 'Preferensi',
      'notifikasi_cafe_baru': 'Notifikasi Cafe Baru',
      'pilih_bahasa': 'Bahasa',
      'bahasa_indonesia': 'Bahasa Indonesia',
      'bahasa_inggris': 'English',
      'edit_foto': 'Ubah Foto Profil',
      'nama': 'Nama',
      'simpan_perubahan': 'Simpan Perubahan',
      'password_baru': 'Password Baru',
      'konfirmasi_password': 'Konfirmasi Password',
      'password_minimal': 'Password minimal 6 karakter',
      'password_tidak_cocok': 'Password tidak cocok',
      'password_berhasil': 'Password berhasil diubah!',

      // Kategori Cafe
      'Kopi & Espresso': 'Kopi & Espresso',
      'Teh & Herbal': 'Teh & Herbal',
      'Dessert & Kue': 'Dessert & Kue',
      'Makan Siang': 'Makan Siang',
      'Sarapan': 'Sarapan',
      'Outdoor': 'Outdoor',
      'Cozy & Nyaman': 'Cozy & Nyaman',
      'Wi-Fi Kencang': 'Wi-Fi Kencang',
    },
    'en': {
      // Navigasi & Umum
      'app_name': 'CaféFinder',
      'beranda': 'Home',
      'cari': 'Search',
      'tambah': 'Add',
      'favorit': 'Favorite',
      'profil': 'Profile',
      'batal': 'Cancel',
      'simpan': 'Save',
      'keluar': 'Logout',
      'yakin_keluar': 'Are you sure you want to logout?',

      // Halaman Login & Register
      'masuk': 'Login',
      'daftar': 'Register',
      'email': 'Email',
      'password': 'Password',
      'nama_lengkap': 'Full Name',
      'belum_punya_akun': 'Don\'t have an account? Register',
      'sudah_punya_akun': 'Already have an account? Login',
      'silakan_login': 'Please log in to your account',
      'buat_akun': 'Create your new account',
      'email_tidak_valid': 'Invalid email address',
      'password_pendek': 'Password must be at least 6 characters',
      'nama_kosong': 'Name cannot be empty',
      'login_gagal': 'Failed to login',
      'register_gagal': 'Failed to register',
      'selamat_datang_kembali': 'Welcome back!',
      'belum_punya_akun_tanya': 'Don\'t have an account? ',
      'sudah_punya_akun_tanya': 'Already have an account? ',
      'email_wajib': 'Email is required',
      'password_wajib': 'Password is required',
      'nama_wajib': 'Name is required',
      'daftar_sekarang': 'Register Now',
      'preferensi_cafe_opsional': 'Cafe Preferences (optional)',
      'bergabung_desc': 'Join to find your favorite cafe!',
      'registrasi_gagal': 'Registration failed',

      // Halaman Beranda (Home)
      'halo': 'Hi,',
      'rekomendasi_untukmu': 'Recommendations for You',
      'jelajahi_cafe': 'Explore cafes nearby',
      'semua': 'All',
      'cari_cafe_placeholder': 'Search cafe name, address, or menu...',
      'cari_cafe': 'Find your favorite cafe today!',
      'semua_cafe': 'All Cafes',
      'gagal_memuat': 'Failed to load data',
      'belum_ada_cafe': 'No cafes available',
      'cafe_favorit': 'Favorite Cafes',
      'belum_ada_favorit': 'No favorite cafes yet',
      'petunjuk_favorit': 'Tap the ♡ icon on the cafe detail page\nto add to favorites',
      'login_untuk_favorit': 'Login to see favorites',

      // Halaman Tambah Cafe
      'tambah_cafe_baru': 'Add New Cafe',
      'nama_cafe': 'Cafe Name',
      'deskripsi': 'Description',
      'alamat': 'Address',
      'kategori': 'Category',
      'koordinat': 'Coordinates',
      'ambil_lokasi': 'Get Current Location',
      'pilih_foto': 'Choose Main Photo',
      'fasilitas': 'Facilities',
      'estimasi_harga': 'Price Estimate (Min - Max)',
      'simpan_cafe': 'Save Cafe',
      'nama_cafe_kosong': 'Cafe name cannot be empty',
      'deskripsi_kosong': 'Description cannot be empty',
      'alamat_kosong': 'Address cannot be empty',
      'harga_min_kosong': 'Minimum price cannot be empty',
      'harga_max_kosong': 'Maximum price cannot be empty',
      'foto_kosong': 'Please select a main cafe photo',
      'cafe_berhasil_ditambah': 'New cafe successfully added!',

      // Halaman Detail Cafe
      'ulasan': 'Reviews',
      'tambah_ulasan': 'Add Review',
      'fasilitas_title': 'Facilities',
      'menu_title': 'Popular Menu',
      'lokasi_title': 'Location',
      'petunjuk_arah': 'Get Directions',
      'rating_dan_ulasan': 'Rating & Reviews',
      'tulis_ulasan_disini': 'Write your review here...',
      'beri_rating': 'Give Rating',
      'kirim': 'Submit',
      'ulasan_kosong': 'Review cannot be empty',
      'ulasan_berhasil': 'Review successfully added!',

      // Halaman Profil (Profile)
      'riwayat_kunjungan': 'Visited Cafe History',
      'belum_ada_riwayat': 'No visit history yet.',
      'pengaturan_akun': 'Account Settings',
      'edit_profil': 'Edit Profile',
      'ubah_password': 'Change Password',
      'mode_terang': 'Light Mode',
      'mode_gelap': 'Dark Mode',
      'preferensi_cafe': 'Cafe Preferences',
      'preferensi_disimpan': 'Preferences saved!',
      'simpan_preferensi': 'Save Preferences',
      'cafe_dikunjungi': 'Cafes Visited',
      'preferensi': 'Preferences',
      'notifikasi_cafe_baru': 'New Cafe Notification',
      'pilih_bahasa': 'Language',
      'bahasa_indonesia': 'Indonesian',
      'bahasa_inggris': 'English',
      'edit_foto': 'Change Profile Photo',
      'nama': 'Name',
      'simpan_perubahan': 'Save Changes',
      'password_baru': 'New Password',
      'konfirmasi_password': 'Confirm Password',
      'password_minimal': 'Password must be at least 6 characters',
      'password_tidak_cocok': 'Passwords do not match',
      'password_berhasil': 'Password successfully changed!',

      // Kategori Cafe
      'Kopi & Espresso': 'Coffee & Espresso',
      'Teh & Herbal': 'Tea & Herbal',
      'Dessert & Kue': 'Dessert & Cake',
      'Makan Siang': 'Lunch',
      'Sarapan': 'Breakfast',
      'Outdoor': 'Outdoor',
      'Cozy & Nyaman': 'Cozy & Comfortable',
      'Wi-Fi Kencang': 'Fast Wi-Fi',
    }
  };
}
