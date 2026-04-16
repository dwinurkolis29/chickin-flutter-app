import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';

class StorageService {
  final ImagePicker _picker = ImagePicker();
  
  String get _cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  final String _uploadPreset = "recording";

  Future<File?> pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1080,
    );
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  Future<File?> cropImage({
    required File imageFile,
    CropAspectRatioPreset? aspectRatio,
  }) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      compressQuality: 80,
      maxWidth: 1080,
      maxHeight: 1080,
      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Potong Gambar',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: aspectRatio ?? CropAspectRatioPreset.original,
            lockAspectRatio: aspectRatio != null,
            aspectRatioPresets: aspectRatio != null
                ? [aspectRatio]
                : [
                    CropAspectRatioPreset.original,
                    CropAspectRatioPreset.square,
                    CropAspectRatioPreset.ratio16x9
                  ]),
        IOSUiSettings(
          title: 'Potong Gambar',
          aspectRatioLockEnabled: aspectRatio != null,
          aspectRatioPresets: aspectRatio != null
              ? [aspectRatio]
              : [
                  CropAspectRatioPreset.original,
                  CropAspectRatioPreset.square,
                  CropAspectRatioPreset.ratio16x9
                ],
        ),
      ],
    );

    if (croppedFile != null) {
      return File(croppedFile.path);
    }
    return null;
  }

  Future<String> uploadImage(File imageFile, String pathPrefix) async {
    final uploadUrl = Uri.parse("https://api.cloudinary.com/v1_1/$_cloudName/image/upload");
    
    // PEMISAHAN LOGIKA PATH DAN FILENAME
    final pathParts = pathPrefix.split('/');
    final baseName = pathParts.removeLast(); 
    final subFolder = pathParts.join('/');   
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    final publicId = '${baseName}_$timestamp';
    final targetFolder = subFolder.isEmpty ? 'chickin' : 'chickin/$subFolder';
    
    // Encode bytes to base64
    // THE PREVIOUS BASE64 LOGIC IS DROPPED IN FAVOR OF MULTIPART!
    
    final request = http.MultipartRequest('POST', uploadUrl)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['public_id'] = publicId
      ..fields['folder'] = targetFolder
      ..files.add(
        await http.MultipartFile.fromPath(
          'file', 
          imageFile.path, 
          filename: '$publicId.jpg' // Explictly declaring name to avoid slashes from system path
        )
      );
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return responseBody['secure_url'];
    } else {
      throw Exception('Failed to upload image to Cloudinary: ${response.statusCode} - ${response.body}');
    }
  }
}
