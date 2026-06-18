import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Register dengan email & password
  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      await user.updateDisplayName(name);

      final userModel = UserModel(
        uid: user.uid,
        name: name,
        email: email,
        photoUrl: '',
        favoriteCategories: [],
        visitedCafes: [],
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toMap());

      return userModel;
    } catch (e) {
      rethrow;
    }
  }

  // Login dengan email & password
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;
      final doc =
          await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, user.uid);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Ambil data user
  Future<UserModel?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, uid);
    }
    return null;
  }

  // Update preferensi user
  Future<void> updatePreferences(
      String uid, List<String> categories) async {
    await _firestore.collection('users').doc(uid).update({
      'favoriteCategories': categories,
    });
  }

  // Update preferensi notifikasi
  Future<void> updateNotificationPreference(String uid, bool enabled) async {
    await _firestore.collection('users').doc(uid).update({
      'notificationsEnabled': enabled,
    });
  }

  // Update preferensi bahasa
  Future<void> updateLanguagePreference(String uid, String langCode) async {
    await _firestore.collection('users').doc(uid).update({
      'languageCode': langCode,
    });
  }

  // Tambah cafe ke visited
  Future<void> addVisitedCafe(String uid, String cafeId) async {
    await _firestore.collection('users').doc(uid).update({
      'visitedCafes': FieldValue.arrayUnion([cafeId]),
    });
  }

  // Toggle visited status
  Future<void> toggleVisited(String uid, String cafeId) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    final List<dynamic> visited = data['visitedCafes'] ?? [];
    if (visited.contains(cafeId)) {
      await _firestore.collection('users').doc(uid).update({
        'visitedCafes': FieldValue.arrayRemove([cafeId]),
      });
    } else {
      await _firestore.collection('users').doc(uid).update({
        'visitedCafes': FieldValue.arrayUnion([cafeId]),
      });
    }
  }

  // Cek apakah cafe sudah dikunjungi
  Future<bool> isVisited(String uid, String cafeId) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return false;
    final data = doc.data()!;
    final List<dynamic> visited = data['visitedCafes'] ?? [];
    return visited.contains(cafeId);
  }

  // Toggle favorit cafe
  Future<void> toggleFavorite(String uid, String cafeId) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    final List<dynamic> favorites = data['favoriteCafes'] ?? [];
    if (favorites.contains(cafeId)) {
      await _firestore.collection('users').doc(uid).update({
        'favoriteCafes': FieldValue.arrayRemove([cafeId]),
      });
    } else {
      await _firestore.collection('users').doc(uid).update({
        'favoriteCafes': FieldValue.arrayUnion([cafeId]),
      });
    }
  }

  // Cek apakah cafe sudah difavoritkan
  Future<bool> isFavorite(String uid, String cafeId) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return false;
    final data = doc.data()!;
    final List<dynamic> favorites = data['favoriteCafes'] ?? [];
    return favorites.contains(cafeId);
  }

  // Stream ID cafe favorit
  Stream<List<String>> getFavoriteCafeIds(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return <String>[];
      final data = doc.data()!;
      final List<dynamic> favorites = data['favoriteCafes'] ?? [];
      return favorites.cast<String>();
    });
  }

  // Metode untuk memperbarui profil pengguna (Nama Lengkap dan Foto Profil)
  Future<void> updateProfile({
    required String uid,
    required String name,
    File? imageFile,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    try {
      // 1. Memastikan pengguna saat ini sudah login di Firebase Authentication
      final user = _auth.currentUser;
      if (user == null) throw Exception('User tidak login');

      String? photoUrl;

      // 2. Jika ada file gambar atau data byte gambar baru yang diunggah
      if (imageFile != null || imageBytes != null) {
        try {
          final storage = FirebaseStorage.instance;
          // Membuat nama file unik berdasarkan UID dan timestamp agar tidak bertabrakan
          final fileName = imageFileName ?? '${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final ref = storage.ref().child('profiles/$fileName');

          // Menangani unggahan untuk Platform Web (menggunakan imageBytes)
          if (imageBytes != null) {
            final metadata = SettableMetadata(contentType: 'image/jpeg');
            final uploadTask = ref.putData(imageBytes, metadata);
            // Memberikan batas waktu (timeout) 5 detik untuk proses unggah
            final snap = await uploadTask.timeout(const Duration(seconds: 5));
            // Mengambil URL unduhan gambar dengan batas waktu 3 detik
            photoUrl = await snap.ref.getDownloadURL().timeout(const Duration(seconds: 3));
          } 
          // Menangani unggahan untuk Platform Native Mobile/Desktop (menggunakan imageFile)
          else if (imageFile != null) {
            final uploadTask = ref.putFile(imageFile);
            // Memberikan batas waktu (timeout) 5 detik untuk proses unggah
            final snap = await uploadTask.timeout(const Duration(seconds: 5));
            // Mengambil URL unduhan gambar dengan batas waktu 3 detik
            photoUrl = await snap.ref.getDownloadURL().timeout(const Duration(seconds: 3));
          }
        } catch (storageError) {
          // 3. Cadangan (Fallback): Jika Firebase Storage gagal atau dibatasi, konversi gambar ke Base64
          print('Upload foto profil ke Firebase Storage gagal, menggunakan fallback base64: $storageError');
          try {
            if (imageBytes != null) {
              final base64Str = base64Encode(imageBytes);
              photoUrl = 'data:image/jpeg;base64,$base64Str';
            } else if (imageFile != null) {
              final bytes = await imageFile.readAsBytes();
              final base64Str = base64Encode(bytes);
              photoUrl = 'data:image/jpeg;base64,$base64Str';
            }
          } catch (e) {
            print('Konversi base64 foto profil gagal: $e');
          }
        }
      }

      // 4. Memperbarui informasi profil pengguna di Firebase Authentication
      await user.updateDisplayName(name);
      if (photoUrl != null && photoUrl.isNotEmpty) {
        await user.updatePhotoURL(photoUrl);
      }

      // 5. Menyamakan pembaruan data (singkronisasi) ke dokumen pengguna di Firestore
      final updates = <String, dynamic>{
        'name': name,
      };
      if (photoUrl != null && photoUrl.isNotEmpty) {
        updates['photoUrl'] = photoUrl;
      }

      await _firestore.collection('users').doc(uid).update(updates);
    } catch (e) {
      rethrow;
    }
  }

  // Metode untuk mengubah password akun pengguna saat ini
  Future<void> changePassword(String newPassword) async {
    try {
      // 1. Memastikan pengguna saat ini sudah login
      final user = _auth.currentUser;
      if (user == null) throw Exception('User tidak login');
      
      // 2. Memperbarui password menggunakan Firebase Auth API
      await user.updatePassword(newPassword);
    } catch (e) {
      rethrow;
    }
  }
}
