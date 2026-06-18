import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/cafe_model.dart';

// Service untuk mengelola notifikasi lokal dan mendengarkan data cafe baru dari Firestore
class NotificationService {
  // Implementasi Singleton agar service ini hanya memiliki satu instansi di aplikasi
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  StreamSubscription<QuerySnapshot>? _cafeSubscription;
  bool _isInitialized = false;

  // Menginisialisasi pengaturan notifikasi lokal untuk Android & iOS
  Future<void> init() async {
    if (_isInitialized) return;
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    // Pengaturan inisialisasi khusus untuk Android dengan menggunakan ikon default aplikasi
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Pengaturan inisialisasi untuk iOS/Darwin
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Logika tambahan ketika notifikasi di-klik oleh pengguna (jika diperlukan)
      },
    );

    // Meminta izin notifikasi runtime untuk Android 13 (API 33) ke atas
    final androidPlugin = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    _isInitialized = true;
  }

  // Fungsi untuk memicu dan menampilkan notifikasi lokal
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'new_cafe_channel_id',
      'Notifikasi Cafe Baru',
      channelDescription: 'Saluran notifikasi untuk informasi cafe baru yang terdaftar',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // Mulai memantau (listen) koleksi cafe secara real-time di Firestore
  void startListeningToNewCafes() {
    // Memastikan subscription sebelumnya dibatalkan terlebih dahulu agar tidak dobel
    stopListeningToNewCafes();

    bool isInitialLoad = true;

    _cafeSubscription = FirebaseFirestore.instance
        .collection('cafes')
        .snapshots()
        .listen((snapshot) {
      if (isInitialLoad) {
        // Snapshot pertama memuat semua cafe yang sudah ada di database.
        // Kita lewati (ignore) data awal agar tidak mengirim notifikasi massal saat aplikasi dibuka.
        isInitialLoad = false;
        return;
      }

      // Memeriksa setiap perubahan dokumen yang terjadi pada koleksi cafes
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            try {
              final cafe = CafeModel.fromMap(data, change.doc.id);
              
              // Memicu notifikasi lokal dengan info nama cafe baru
              showNotification(
                id: cafe.id.hashCode,
                title: 'Ada Cafe Baru! ☕',
                body: '${cafe.name} kini terdaftar di ${cafe.address}. Yuk lihat!',
              );
            } catch (e) {
              print('Gagal parsing data cafe untuk notifikasi: $e');
            }
          }
        }
      }
    });
  }

  // Menghentikan langganan (unsubscribe) aliran data cafe untuk menghindari kebocoran memori
  void stopListeningToNewCafes() {
    _cafeSubscription?.cancel();
    _cafeSubscription = null;
  }
}
