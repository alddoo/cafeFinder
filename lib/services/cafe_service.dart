import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/cafe_model.dart';
import '../models/review_model.dart';

// Service untuk mengelola data Cafe dan Ulasan di Cloud Firestore dan Firebase Storage
class CafeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===================== CAFE CRUD (Create, Read, Update, Delete) =====================

  // Mendapatkan aliran data (Stream) seluruh cafe, diurutkan berdasarkan tanggal dibuat terbaru
  Stream<List<CafeModel>> getCafes() {
    return _firestore
        .collection('cafes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CafeModel.fromMap(d.data(), d.id)).toList());
  }

  // Menambahkan data cafe baru beserta unggah foto utama (mendukung Storage & fallback Base64)
  Future<String> addCafe(
    CafeModel cafe, {
    File? imageFile,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    String imageUrl = '';

    // A. Mencoba mengunggah foto ke Firebase Storage terlebih dahulu
    try {
      final storage = FirebaseStorage.instance;
      final fileName = imageFileName ?? '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = storage.ref().child('cafes/$fileName');

      if (imageBytes != null) {
        final metadata = SettableMetadata(contentType: 'image/jpeg');
        final uploadTask = ref.putData(imageBytes, metadata);
        final snap = await uploadTask.timeout(const Duration(seconds: 5));
        imageUrl = await snap.ref.getDownloadURL().timeout(const Duration(seconds: 3));
      } else if (imageFile != null) {
        final uploadTask = ref.putFile(imageFile);
        final snap = await uploadTask.timeout(const Duration(seconds: 5));
        imageUrl = await snap.ref.getDownloadURL().timeout(const Duration(seconds: 3));
      }
    } catch (storageError) {
      print('Upload ke Firebase Storage gagal atau timeout, menggunakan fallback base64: $storageError');
      
      // B. Cadangan (Fallback): Konversi ke Base64 jika Firebase Storage tidak aktif / error
      try {
        if (imageBytes != null) {
          final base64Str = base64Encode(imageBytes);
          imageUrl = 'data:image/jpeg;base64,$base64Str';
        } else if (imageFile != null) {
          final bytes = await imageFile.readAsBytes();
          final base64Str = base64Encode(bytes);
          imageUrl = 'data:image/jpeg;base64,$base64Str';
        }
      } catch (e) {
        imageUrl = '';
        print('Konversi base64 gagal: $e');
      }
    }

    // Pembatasan keamanan: Ukuran dokumen Firestore maksimal 1MB. Jika Base64 terlalu besar, batalkan.
    if (imageUrl.startsWith('data:image') && imageUrl.length > 900000) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'invalid-argument',
        message: 'Ukuran foto terlalu besar untuk disimpan langsung di Firestore. Silakan aktifkan Firebase Storage di Firebase Console atau gunakan foto dengan resolusi lebih kecil.',
      );
    }

    final data = cafe.toMap();
    data['imageUrl'] = imageUrl;
    data['createdAt'] = FieldValue.serverTimestamp(); // Menyimpan waktu server Firestore

    final doc = await _firestore.collection('cafes').add(data);
    return doc.id;
  }

  // Memperbarui sebagian field data cafe di Firestore
  Future<void> updateCafe(String cafeId, Map<String, dynamic> data) async {
    await _firestore.collection('cafes').doc(cafeId).update(data);
  }

  // Menghapus dokumen cafe dari Firestore
  Future<void> deleteCafe(String cafeId) async {
    await _firestore.collection('cafes').doc(cafeId).delete();
  }

  // Mengambil informasi detail satu cafe berdasarkan ID dokumen
  Future<CafeModel?> getCafeById(String cafeId) async {
    final doc = await _firestore.collection('cafes').doc(cafeId).get();
    if (doc.exists) {
      return CafeModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  // Mengambil daftar cafe secara bersamaan (paralel) berdasarkan kumpulan ID
  Future<List<CafeModel>> getCafesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final futures = ids.map((id) => getCafeById(id));
    final results = await Future.wait(futures);
    return results.whereType<CafeModel>().toList();
  }

  // ===================== PENCARIAN & FILTER DATA =====================

  // Mencari cafe berdasarkan teks nama (menggunakan pencarian awalan teks Firestore & fallback Full-Scan)
  Future<List<CafeModel>> searchCafes(String query) async {
    final snap = await _firestore
        .collection('cafes')
        .orderBy('name')
        .startAt([query.toLowerCase()])
        .endAt(['${query.toLowerCase()}\uf8ff'])
        .get();

    // Jika pencarian ter-indeks awal kosong, lakukan pencarian substring di memori (Full-scan)
    if (snap.docs.isEmpty) {
      final allSnap = await _firestore.collection('cafes').get();
      return allSnap.docs
          .map((d) => CafeModel.fromMap(d.data(), d.id))
          .where((c) =>
              c.name.toLowerCase().contains(query.toLowerCase()) ||
              c.description.toLowerCase().contains(query.toLowerCase()) ||
              c.address.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

    return snap.docs.map((d) => CafeModel.fromMap(d.data(), d.id)).toList();
  }

  // Menyaring cafe berdasarkan nama kategori
  Future<List<CafeModel>> filterByCategory(String category) async {
    final snap = await _firestore
        .collection('cafes')
        .where('category', isEqualTo: category)
        .get();
    return snap.docs.map((d) => CafeModel.fromMap(d.data(), d.id)).toList();
  }

  // Menyaring cafe berdasarkan batasan harga terendah
  Future<List<CafeModel>> filterByPrice(
      double minPrice, double maxPrice) async {
    final snap = await _firestore
        .collection('cafes')
        .where('priceMin', isGreaterThanOrEqualTo: minPrice)
        .where('priceMin', isLessThanOrEqualTo: maxPrice)
        .get();
    return snap.docs.map((d) => CafeModel.fromMap(d.data(), d.id)).toList();
  }

  // Mendapatkan rekomendasi cafe berdasarkan preferensi kategori kopi yang disukai pengguna
  Future<List<CafeModel>> getRecommendations(
      List<String> preferredCategories) async {
    // Jika user belum memilih preferensi, tampilkan 10 cafe dengan rating tertinggi secara global
    if (preferredCategories.isEmpty) {
      final snap = await _firestore
          .collection('cafes')
          .orderBy('rating', descending: true)
          .limit(10)
          .get();
      return snap.docs.map((d) => CafeModel.fromMap(d.data(), d.id)).toList();
    }

    // Mengambil cafe yang memiliki kategori sesuai dengan preferensi pengguna
    final snap = await _firestore
        .collection('cafes')
        .where('category', whereIn: preferredCategories.take(10).toList())
        .get();
    
    final list = snap.docs.map((d) => CafeModel.fromMap(d.data(), d.id)).toList();
    // Mengurutkan secara lokal di memori berdasarkan rating tertinggi
    list.sort((a, b) => b.rating.compareTo(a.rating));
    return list.take(10).toList();
  }

  // ===================== ULASAN & RATING =====================

  // Menambahkan ulasan baru dan memperbarui rata-rata rating cafe secara otomatis
  Future<void> addReview(ReviewModel review) async {
    final data = review.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('reviews').add(data);

    // Memicu perhitungan ulang rata-rata rating di dokumen cafe
    await _updateCafeRating(review.cafeId);
  }

  // Mengambil ulasan cafe berdasarkan ID cafe (Real-time Stream)
  Stream<List<ReviewModel>> getReviews(String cafeId) {
    return _firestore
        .collection('reviews')
        .where('cafeId', isEqualTo: cafeId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => ReviewModel.fromMap(d.data(), d.id))
              .toList();
          // Diurutkan di memori agar tidak membutuhkan pembuatan composite index manual di Firestore Console
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // Mengalirkan data cafe spesifik secara real-time berdasarkan ID
  Stream<CafeModel> getCafeStream(String cafeId) {
    return _firestore
        .collection('cafes')
        .doc(cafeId)
        .snapshots()
        .map((doc) => CafeModel.fromMap(doc.data() ?? {}, doc.id));
  }

  // Fungsi internal untuk menghitung ulang rata-rata rating cafe
  Future<void> _updateCafeRating(String cafeId) async {
    final snap = await _firestore
        .collection('reviews')
        .where('cafeId', isEqualTo: cafeId)
        .get();

    if (snap.docs.isEmpty) return;

    double totalRating = 0;
    for (var doc in snap.docs) {
      totalRating += (doc.data()['rating'] ?? 0.0).toDouble();
    }
    final avgRating = totalRating / snap.docs.length;

    // Menyimpan hasil kalkulasi rata-rata rating dan jumlah ulasan ke dokumen cafe terkait
    await _firestore.collection('cafes').doc(cafeId).update({
      'rating': avgRating,
      'reviewCount': snap.docs.length,
    });
  }

  // Fungsi Seeder untuk memasukkan data awal cafe Palembang secara otomatis jika belum ada
  Future<void> seedPalembangCafes() async {
    final cafesToSeed = [
      {
        'name': 'Equatore Rooftop Cafe',
        'description': 'Cafe rooftop elegan dengan pemandangan kota Palembang yang menawan. Cocok untuk bersantai sore hari maupun makan malam romantis.',
        'address': 'Barong Hotel Lt. 5, Palembang Square Mall, Jl. POM IX, Palembang',
        'latitude': -2.9888,
        'longitude': 104.7431,
        'imageUrl': 'assets/images/equatore_hero.png',
        'imageUrls': [
          'assets/images/equatore_hero.png',
          'assets/images/gallery_coffee_art.png',
          'assets/images/gallery_outdoor_cozy.png'
        ],
        'menuItems': ['Hot Cafe Latte', 'Calamari Fritti', 'Equatore Chicken Wings', 'Ice Lychee Tea'],
        'priceMin': 30000.0,
        'priceMax': 120000.0,
        'facilities': ['Wi-Fi', 'Parkir', 'Outdoor Area', 'AC', 'Live Music'],
        'ownerId': 'admin_seeder',
        'rating': 4.6,
        'reviewCount': 12,
        'category': 'Outdoor',
        'tags': ['rooftop', 'sunset', 'view', 'romantis'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'York Coffee and Cookery',
        'description': 'Cafe estetik bernuansa Eropa klasik yang menyajikan hidangan lezat dan kopi berkualitas tinggi. Sangat nyaman untuk berkumpul bersama keluarga.',
        'address': 'Jl. Jenderal Basuki Rahmat No. 2, Palembang',
        'latitude': -2.9723,
        'longitude': 104.7601,
        'imageUrl': 'assets/images/york_hero.png',
        'imageUrls': [
          'assets/images/york_hero.png',
          'assets/images/gallery_dessert.png',
          'assets/images/gallery_coffee_art.png'
        ],
        'menuItems': ['York Signature Pizza', 'Aesthetic Cappuccino', 'Sop Buntut Premium', 'Chocolate Fudge Cake'],
        'priceMin': 35000.0,
        'priceMax': 150000.0,
        'facilities': ['Wi-Fi', 'Parkir', 'AC', 'Meeting Room', 'Non-Smoking'],
        'ownerId': 'admin_seeder',
        'rating': 4.5,
        'reviewCount': 8,
        'category': 'Cozy & Nyaman',
        'tags': ['eropa', 'klasik', 'keluarga', 'pizza'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Eighty Eight Coffee',
        'description': 'Tempat nongkrong modern minimalis dengan suasana tenang, ideal untuk bekerja (WFC) atau berdiskusi. Menyediakan berbagai jenis kopi susu spesial.',
        'address': 'Jl. Sumpah Pemuda No. 88, Lorok Pakjo, Palembang',
        'latitude': -2.9734,
        'longitude': 104.7410,
        'imageUrl': 'assets/images/eighty_eight_hero.png',
        'imageUrls': [
          'assets/images/eighty_eight_hero.png',
          'assets/images/gallery_coffee_art.png',
          'assets/images/gallery_outdoor_cozy.png'
        ],
        'menuItems': ['Es Kopi Susu Eighty Eight', 'Almond Croissant', 'V60 Gayo', 'Iced Matcha Latte'],
        'priceMin': 20000.0,
        'priceMax': 60000.0,
        'facilities': ['Wi-Fi', 'Parkir', 'AC', 'Non-Smoking', 'Wi-Fi Kencang'],
        'ownerId': 'admin_seeder',
        'rating': 4.7,
        'reviewCount': 15,
        'category': 'Cozy & Nyaman',
        'tags': ['wfc', 'kerja', 'minimalis', 'kopi susu'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Bingen Cafe',
        'description': 'Cafe bertema rustic garden yang luas dengan area tepi kolam (poolside) yang indah. Sangat populer untuk acara kumpul-kumpul di malam hari.',
        'address': 'Jl. Residen Abdul Rozak No. 5, Bukit Sangkal, Kalidoni, Palembang',
        'latitude': -2.9554,
        'longitude': 104.7794,
        'imageUrl': 'assets/images/bingen_hero.png',
        'imageUrls': [
          'assets/images/bingen_hero.png',
          'assets/images/gallery_outdoor_cozy.png',
          'assets/images/gallery_dessert.png'
        ],
        'menuItems': ['Bingen Fried Rice', 'Iced Taro Latte', 'Mix Platter', 'Mocktail Sunset'],
        'priceMin': 18000.0,
        'priceMax': 75000.0,
        'facilities': ['Wi-Fi', 'Parkir', 'Outdoor Area', 'Live Music', 'Pet Friendly'],
        'ownerId': 'admin_seeder',
        'rating': 4.3,
        'reviewCount': 5,
        'category': 'Outdoor',
        'tags': ['garden', 'poolside', 'rustic', 'santai'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Gunz Cafe & Bistro',
        'description': 'Cafe asyik dengan hiburan musik akustik langsung setiap malam. Tempat terbaik untuk bersantai bersama teman-teman sembari menikmati shisha dan pizza.',
        'address': 'Jl. Merdeka, Bukit Kecil, Palembang',
        'latitude': -2.9904,
        'longitude': 104.7570,
        'imageUrl': 'assets/images/gunz_hero.png',
        'imageUrls': [
          'assets/images/gunz_hero.png',
          'assets/images/gallery_outdoor_cozy.png',
          'assets/images/gallery_coffee_art.png'
        ],
        'menuItems': ['Pepperoni Pizza', 'Iced Hazelnut Latte', 'Chicken Quesadilla', 'Shisha Mint'],
        'priceMin': 25000.0,
        'priceMax': 110000.0,
        'facilities': ['Wi-Fi', 'Parkir', 'Outdoor Area', 'Live Music', 'AC'],
        'ownerId': 'admin_seeder',
        'rating': 4.4,
        'reviewCount': 9,
        'category': 'Outdoor',
        'tags': ['live music', 'shisha', 'akustik', 'nongkrong'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'ENAMDUA Coffee & Eatery',
        'description': 'Cafe bernuansa semi-industrial modern dengan desain estetis dan kopi racikan barista berpengalaman. Menyediakan hidangan western dan lokal.',
        'address': 'Jl. Hang Tuah No. 8, Talang Semut, Palembang',
        'latitude': -2.9925,
        'longitude': 104.7495,
        'imageUrl': 'assets/images/enamdua_hero.png',
        'imageUrls': [
          'assets/images/enamdua_hero.png',
          'assets/images/gallery_coffee_art.png',
          'assets/images/gallery_dessert.png'
        ],
        'menuItems': ['Enamdua Magic Coffee', 'Spaghetti Carbonara', 'Avocado Coffee Float', 'Croissant Butter'],
        'priceMin': 22000.0,
        'priceMax': 80000.0,
        'facilities': ['Wi-Fi', 'Parkir', 'AC', 'Non-Smoking', 'Prayer Room'],
        'ownerId': 'admin_seeder',
        'rating': 4.6,
        'reviewCount': 11,
        'category': 'Kopi & Espresso',
        'tags': ['industrial', 'aesthetic', 'makanan', 'barista'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Coffee Theory Palembang',
        'description': 'Cafe dengan spesialisasi kopi specialty dan suasana industrial modern. Sangat disukai oleh para pencinta kopi sejati dan profesional yang ingin bekerja.',
        'address': 'Jl. Letda A. Rozak No. 7, Ilir Timur II, Palembang',
        'latitude': -2.9548,
        'longitude': 104.7788,
        'imageUrl': 'assets/images/coffee_theory_hero.png',
        'imageUrls': [
          'assets/images/coffee_theory_hero.png',
          'assets/images/gallery_coffee_art.png',
          'assets/images/gallery_outdoor_cozy.png'
        ],
        'menuItems': ['Specialty Latte', 'Cold Brew Signature', 'Spaghetti Aglio Olio', 'Beef Burger Classic'],
        'priceMin': 25000.0,
        'priceMax': 90000.0,
        'facilities': ['Wi-Fi', 'Parkir', 'AC', 'Non-Smoking', 'Wi-Fi Kencang'],
        'ownerId': 'admin_seeder',
        'rating': 4.6,
        'reviewCount': 18,
        'category': 'Kopi & Espresso',
        'tags': ['specialty', 'work', 'barista', 'industrial'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Oculo Coffee',
        'description': 'Cafe minimalis estetik dengan konsep jendela melingkar yang unik. Menawarkan kopi susu kekinian dan aneka pastry segar.',
        'address': 'Jl. Sumpah Pemuda No. 12, Lorok Pakjo, Palembang',
        'latitude': -2.9730,
        'longitude': 104.7428,
        'imageUrl': 'assets/images/oculo_hero.png',
        'imageUrls': [
          'assets/images/oculo_hero.png',
          'assets/images/gallery_dessert.png',
          'assets/images/gallery_coffee_art.png'
        ],
        'menuItems': ['Oculo Aren Coffee', 'Salted Caramel Croissant', 'Croffle Cinnamon', 'Iced Lemon Tea'],
        'priceMin': 20000.0,
        'priceMax': 55000.0,
        'facilities': ['Wi-Fi', 'Parkir', 'AC', 'Non-Smoking', 'Wi-Fi Kencang'],
        'ownerId': 'admin_seeder',
        'rating': 4.5,
        'reviewCount': 10,
        'category': 'Dessert & Kue',
        'tags': ['pastry', 'croissant', 'aesthetic', 'circle window'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Terra Coffee & Eatery',
        'description': 'Cafe berkonsep alam dengan banyak ruang terbuka hijau. Menyajikan aneka pilihan kopi sehat, jus, serta hidangan nusantara modern.',
        'address': 'Jl. Cempaka No. 5, Ilir Barat I, Palembang',
        'latitude': -2.9802,
        'longitude': 104.7540,
        'imageUrl': 'assets/images/terra_hero.png',
        'imageUrls': [
          'assets/images/terra_hero.png',
          'assets/images/gallery_outdoor_cozy.png',
          'assets/images/gallery_coffee_art.png'
        ],
        'menuItems': ['Nasi Goreng Terra Special', 'Matcha Oat Latte', 'Healthy Green Juice', 'Banana Fritters'],
        'priceMin': 25000.0,
        'priceMax': 85000.0,
        'facilities': ['Wi-Fi', 'Parkir', 'Outdoor Area', 'AC', 'Prayer Room'],
        'ownerId': 'admin_seeder',
        'rating': 4.4,
        'reviewCount': 7,
        'category': 'Outdoor',
        'tags': ['eco', 'garden', 'green', 'healthy'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Luthier Coffee',
        'description': 'Salah satu pelopor kopi specialty di Palembang. Menyajikan kopi pilihan terbaik dengan suasana tenang dan ramah, sangat pas untuk mengobrol santai.',
        'address': 'Jl. Bangau No. 7, 9 Ilir, Palembang',
        'latitude': -2.9774,
        'longitude': 104.7645,
        'imageUrl': 'assets/images/luthier_hero.png',
        'imageUrls': [
          'assets/images/luthier_hero.png',
          'assets/images/gallery_coffee_art.png',
          'assets/images/gallery_outdoor_cozy.png'
        ],
        'menuItems': ['Pour Over Coffee', 'Luthier Flat White', 'Avocado Toast', 'Truffle Fries'],
        'priceMin': 30000.0,
        'priceMax': 80000.0,
        'facilities': ['Wi-Fi', 'Parkir', 'AC', 'Non-Smoking', 'Wi-Fi Kencang'],
        'ownerId': 'admin_seeder',
        'rating': 4.8,
        'reviewCount': 22,
        'category': 'Kopi & Espresso',
        'tags': ['specialty', 'pour over', 'vintage', 'quiet'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'FOW Coffee',
        'description': 'Cafe modern dengan konsep industrial minimalis yang sangat populer di kalangan anak muda Palembang. Terkenal dengan mocktail kopi yang inovatif.',
        'address': 'Jl. Ki Ranggo Wirosentiko No. 1A, 30 Ilir, Palembang',
        'latitude': -2.9912,
        'longitude': 104.7470,
        'imageUrl': 'assets/images/fow_hero.png',
        'imageUrls': [
          'assets/images/fow_hero.png',
          'assets/images/gallery_coffee_art.png',
          'assets/images/gallery_dessert.png'
        ],
        'menuItems': ['FOW Citrus Coffee', 'Espresso Matcha Tonic', 'Korean Fried Chicken Rice', 'Croffle Strawberry'],
        'priceMin': 23000.0,
        'priceMax': 70000.0,
        'facilities': ['Wi-Fi', 'Parkir', 'AC', 'Outdoor Area', 'Non-Smoking'],
        'ownerId': 'admin_seeder',
        'rating': 4.7,
        'reviewCount': 19,
        'category': 'Kopi & Espresso',
        'tags': ['modern', 'mocktail', 'minimalis', 'hits'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'History Coffee Palembang',
        'description': 'Tempat nongkrong asyik dengan konsep vintage retro. Menawarkan suasana hangat, live acoustic music, dan aneka racikan kopi lokal nusantara.',
        'address': 'Jl. Pangeran A. K. M. No. 18, 24 Ilir, Palembang',
        'latitude': -2.9840,
        'longitude': 104.7455,
        'imageUrl': 'assets/images/history_hero.png',
        'imageUrls': [
          'assets/images/history_hero.png',
          'assets/images/gallery_outdoor_cozy.png',
          'assets/images/gallery_coffee_art.png'
        ],
        'menuItems': ['Es Kopi Susu History', 'Nasi Goreng Kampung', 'Singkong Goreng Keju', 'Mocktail Berry Nice'],
        'priceMin': 15000.0,
        'priceMax': 65000.0,
        'facilities': ['Wi-Fi', 'Parkir', 'Outdoor Area', 'Live Music', 'AC'],
        'ownerId': 'admin_seeder',
        'rating': 4.5,
        'reviewCount': 14,
        'category': 'Cozy & Nyaman',
        'tags': ['vintage', 'live music', 'retro', 'nongkrong'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Stasiun Kopi Palembang',
        'description': 'Cafe berkonsep stasiun kereta api klasik yang menghadirkan suasana santai dan bersahabat. Menyediakan menu tradisional Palembang dan western.',
        'address': 'Jl. Demang Lebar Daun No. 10, Lorok Pakjo, Palembang',
        'latitude': -2.9701,
        'longitude': 104.7299,
        'imageUrl': 'assets/images/stasiun_kopi_hero.png',
        'imageUrls': [
          'assets/images/stasiun_kopi_hero.png',
          'assets/images/gallery_coffee_art.png',
          'assets/images/gallery_outdoor_cozy.png'
        ],
        'menuItems': ['Kopi Stasiun Signature', 'Pempek Panggang Cafe', 'Roti Bakar Cokelat', 'Iced Caramel Macchiato'],
        'priceMin': 18000.0,
        'priceMax': 80000.0,
        'facilities': ['Wi-Fi', 'Parkir', 'AC', 'Outdoor Area', 'Prayer Room'],
        'ownerId': 'admin_seeder',
        'rating': 4.4,
        'reviewCount': 11,
        'category': 'Kopi & Espresso',
        'tags': ['station', 'pempek', 'traditional', 'western'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Kopi Pulang',
        'description': 'Sebuah cafe mungil yang homey dengan konsep merasa "pulang ke rumah". Sangat tenang, nyaman, cocok untuk membaca buku atau menikmati kopi sore.',
        'address': 'Jl. Radial No. 24, Bukit Kecil, Palembang',
        'latitude': -2.9868,
        'longitude': 104.7490,
        'imageUrl': 'assets/images/gallery_outdoor_cozy.png',
        'imageUrls': [
          'assets/images/gallery_outdoor_cozy.png',
          'assets/images/gallery_coffee_art.png',
          'assets/images/gallery_dessert.png'
        ],
        'menuItems': ['Kopi Susu Rumah', 'Classic Brownies', 'Manual Brew Tubruk', 'Iced Peach Tea'],
        'priceMin': 15000.0,
        'priceMax': 50000.0,
        'facilities': ['Wi-Fi', 'Parkir', 'AC', 'Non-Smoking', 'Buku Bacaan'],
        'ownerId': 'admin_seeder',
        'rating': 4.6,
        'reviewCount': 9,
        'category': 'Cozy & Nyaman',
        'tags': ['homey', 'tenang', 'buku', 'sore'],
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'Mainichi Coffee',
        'description': 'Cafe bernuansa Jepang minimalis (Japandi) yang menyajikan kopi susu aren creamy, matcha premium, serta donat kentang homemade yang lezat.',
        'address': 'Jl. Mayor Ruslan No. 12, 9 Ilir, Palembang',
        'latitude': -2.9790,
        'longitude': 104.7599,
        'imageUrl': 'assets/images/gallery_dessert.png',
        'imageUrls': [
          'assets/images/gallery_dessert.png',
          'assets/images/gallery_coffee_art.png',
          'assets/images/gallery_outdoor_cozy.png'
        ],
        'menuItems': ['Mainichi Creamy Latte', 'Uji Matcha Latte', 'Potato Donut Powder', 'Matcha Croffle'],
        'priceMin': 18000.0,
        'priceMax': 55000.0,
        'facilities': ['Wi-Fi', 'Parkir', 'AC', 'Non-Smoking', 'Outdoor Seating'],
        'ownerId': 'admin_seeder',
        'rating': 4.7,
        'reviewCount': 16,
        'category': 'Dessert & Kue',
        'tags': ['japan', 'matcha', 'donut', 'creamy'],
        'createdAt': FieldValue.serverTimestamp(),
      }
    ];

    for (var cafeData in cafesToSeed) {
      final name = cafeData['name'] as String;
      final existing = await _firestore
          .collection('cafes')
          .where('name', isEqualTo: name)
          .limit(1)
          .get();
      if (existing.docs.isEmpty) {
        await _firestore.collection('cafes').add(cafeData);
      }
    }
  }
}
