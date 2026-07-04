import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StorageService {
  String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  final String _uploadPreset = "recording";

  // File size limit: 5MB
  static const int _maxFileSizeBytes = 5 * 1024 * 1024;

  // Whitelist ekstensi yang diizinkan
  static const List<String> _allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  // Timeout upload: 30 detik
  static const Duration _uploadTimeout = Duration(seconds: 30);

  Future<String> uploadImage(File imageFile, String pathPrefix) async {
    // ── Validasi sebelum upload ─────────────────────────────────────────────

    // Cek ukuran file — tolak jika > 5MB
    final fileSize = await imageFile.length();
    if (fileSize > _maxFileSizeBytes) {
      throw Exception(
        'Ukuran file terlalu besar. Maksimal 5MB, ukuran saat ini: '
        '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB.',
      );
    }

    // Cek ekstensi file — tolak jika bukan gambar yang diizinkan
    final ext = imageFile.path.split('.').last.toLowerCase();
    if (!_allowedExtensions.contains(ext)) {
      throw Exception(
        'Format file tidak didukung. Gunakan: ${_allowedExtensions.join(', ')}.',
      );
    }

    // ── Persiapan path & nama file ─────────────────────────────────────────

    final pathParts = pathPrefix.split('/');
    final baseName = pathParts.removeLast();
    final subFolder = pathParts.join('/');

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final publicId = '${baseName}_$timestamp';
    final targetFolder = subFolder.isEmpty ? 'chickin' : 'chickin/$subFolder';

    // ── Upload ke Cloudinary ───────────────────────────────────────────────

    final uploadUrl = Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/image/upload");

    final request = http.MultipartRequest('POST', uploadUrl)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['public_id'] = publicId
      ..fields['folder'] = targetFolder
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          filename: '$publicId.$ext',
        ),
      );

    final streamedResponse = await request.send().timeout(
      _uploadTimeout,
      onTimeout: () => throw Exception(
        'Upload timeout setelah ${_uploadTimeout.inSeconds} detik. '
        'Periksa koneksi internet kamu.',
      ),
    );

    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      return responseBody['secure_url'] as String;
    } else {
      throw Exception(
        'Gagal upload gambar ke Cloudinary: '
        '${response.statusCode} — ${response.body}',
      );
    }
  }
}
