// Model data untuk merepresentasikan ulasan/review cafe dari pengguna
class ReviewModel {
  final String id;          // ID unik dokumen ulasan di Firestore
  final String cafeId;      // ID cafe yang diulas
  final String userId;      // UID pengguna yang menulis ulasan
  final String userName;    // Nama pengguna saat menulis ulasan
  final String userPhoto;   // Foto profil pengguna saat menulis ulasan
  final double rating;      // Rating yang diberikan (skala 1-5)
  final String comment;     // Isi komentar/ulasan
  final DateTime createdAt; // Waktu ulasan dibuat

  ReviewModel({
    required this.id,
    required this.cafeId,
    required this.userId,
    required this.userName,
    required this.userPhoto,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  // Membuat instance ReviewModel dari data Map (Firestore document snapshot)
  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      id: id,
      cafeId: map['cafeId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhoto: map['userPhoto'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  // Mengubah data ReviewModel menjadi Map sebelum disimpan ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'cafeId': cafeId,
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'rating': rating,
      'comment': comment,
      // createdAt diisi oleh cafe_service.dart dengan FieldValue.serverTimestamp()
    };
  }
}
