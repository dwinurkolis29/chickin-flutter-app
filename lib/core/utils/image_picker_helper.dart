import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:recording_app/core/theme/app_colors.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickImage(ImageSource source) async {
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

  static Future<File?> cropImage({
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
            toolbarColor: AppColors.primary,
            statusBarLight: false,
            toolbarWidgetColor: Colors.white,
            hideBottomControls: true,
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
          rotateButtonsHidden: true,
          resetButtonHidden: true,
          aspectRatioPickerButtonHidden: true,
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
}
