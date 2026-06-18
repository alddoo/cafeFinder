import 'dart:convert';
import 'package:flutter/material.dart';

// Widget kustom untuk memuat gambar dari berbagai format (Asset Lokal, URL Internet, Data URI Base64, maupun Base64 murni)
class CafeImage extends StatelessWidget {
  final String imageUrl;      // Lokasi path gambar (URL/Asset/Base64)
  final double? width;        // Lebar gambar (opsional)
  final double? height;       // Tinggi gambar (opsional)
  final BoxFit fit;           // Tipe scaling gambar (default: BoxFit.cover)
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder; // Builder tampilan jika memuat gambar gagal

  const CafeImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // A. Kasus jika parameter URL kosong
    if (imageUrl.isEmpty) {
      return errorBuilder?.call(context, 'Empty URL', null) ?? const SizedBox();
    }

    // B. Kasus jika menggunakan asset lokal bawaan project (misal: assets/images/...)
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    }

    // C. Kasus jika format gambar adalah Data URI Base64 (data:image/jpeg;base64,...)
    if (imageUrl.startsWith('data:image/') && imageUrl.contains('base64,')) {
      try {
        // Mengambil string base64 murni setelah koma
        final base64String = imageUrl.split('base64,')[1];
        final bytes = base64Decode(base64String.trim());
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: errorBuilder,
        );
      } catch (e) {
        return errorBuilder?.call(context, e, null) ?? const SizedBox();
      }
    } 
    // D. Kasus jika format gambar adalah URL internet (http:// atau https://)
    else if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    } 
    // E. Kasus cadangan: Mencoba menterjemahkan URL langsung sebagai string Base64 murni tanpa prefix data URI
    else {
      try {
        final bytes = base64Decode(imageUrl.trim());
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: errorBuilder,
        );
      } catch (e) {
        return errorBuilder?.call(context, e, null) ?? const SizedBox();
      }
    }
  }
}
