// Model data untuk merepresentasikan objek pengguna/user aplikasi
class UserModel {
  final String uid;                        // ID unik pengguna dari Firebase Authentication
  final String name;                       // Nama lengkap pengguna
  final String email;                      // Email pengguna
  final String photoUrl;                   // URL foto profil pengguna (mendukung HTTPS dan Base64)
  final List<String> favoriteCategories;   // Daftar kategori kopi favorit pilihan pengguna
  final List<String> visitedCafes;         // Daftar ID cafe yang pernah dikunjungi pengguna
  final DateTime createdAt;                // Tanggal pendaftaran akun pengguna
  final bool notificationsEnabled;         // Apakah notifikasi cafe baru aktif
  final String languageCode;               // Kode bahasa pilihan (id/en)

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.favoriteCategories,
    required this.visitedCafes,
    required this.createdAt,
    this.notificationsEnabled = true,
    this.languageCode = 'id',
  });

  // Membuat instance UserModel dari data Map (Firestore document snapshot)
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      favoriteCategories: List<String>.from(map['favoriteCategories'] ?? []),
      visitedCafes: List<String>.from(map['visitedCafes'] ?? []),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      languageCode: map['languageCode'] ?? 'id',
    );
  }

  // Mengubah data UserModel menjadi Map sebelum disimpan ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'favoriteCategories': favoriteCategories,
      'visitedCafes': visitedCafes,
      'createdAt': createdAt,
      'notificationsEnabled': notificationsEnabled,
      'languageCode': languageCode,
    };
  }
}
