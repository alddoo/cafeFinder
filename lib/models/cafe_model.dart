// Model data untuk merepresentasikan objek Cafe
class CafeModel {
  final String id;              // ID unik dokumen cafe di Firestore
  final String name;            // Nama cafe
  final String description;     // Deskripsi/tentang cafe
  final String address;         // Alamat lengkap cafe
  final double latitude;        // Koordinat lintang lokasi cafe
  final double longitude;       // Koordinat bujur lokasi cafe
  final String imageUrl;        // URL foto utama cafe
  final List<String> imageUrls; // List URL kumpulan foto-foto cafe
  final List<String> menuItems;  // Daftar menu yang tersedia di cafe
  final double priceMin;        // Estimasi harga terendah
  final double priceMax;        // Estimasi harga tertinggi
  final List<String> facilities; // Daftar fasilitas (misal: Wi-Fi, AC, Parkir, dll)
  final String ownerId;         // UID pemilik/pengunggah cafe
  final double rating;          // Rating rata-rata cafe
  final int reviewCount;        // Jumlah ulasan yang masuk
  final String category;        // Kategori cafe (misal: Coffee Shop, Bistro, dll)
  final List<String> tags;       // Tag preferensi rasa (misal: Creamy, Bold, Sweet)
  final DateTime createdAt;     // Waktu cafe ditambahkan ke sistem

  CafeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.imageUrls,
    required this.menuItems,
    required this.priceMin,
    required this.priceMax,
    required this.facilities,
    required this.ownerId,
    required this.rating,
    required this.reviewCount,
    required this.category,
    required this.tags,
    required this.createdAt,
  });

  // Konstruktor factory untuk membuat instance CafeModel dari data Map (Firestore document snapshot)
  factory CafeModel.fromMap(Map<String, dynamic> map, String id) {
    return CafeModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      menuItems: List<String>.from(map['menuItems'] ?? []),
      priceMin: (map['priceMin'] ?? 0.0).toDouble(),
      priceMax: (map['priceMax'] ?? 0.0).toDouble(),
      facilities: List<String>.from(map['facilities'] ?? []),
      ownerId: map['ownerId'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      category: map['category'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  // Mengubah instance CafeModel kembali menjadi Map untuk disimpan ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'menuItems': menuItems,
      'priceMin': priceMin,
      'priceMax': priceMax,
      'facilities': facilities,
      'ownerId': ownerId,
      'rating': rating,
      'reviewCount': reviewCount,
      'category': category,
      'tags': tags,
      // Field createdAt biasanya diset via FieldValue.serverTimestamp() di Firestore service
    };
  }
}
