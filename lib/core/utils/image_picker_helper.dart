import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recording_app/core/theme/app_colors.dart';

export 'package:image_cropper/image_cropper.dart' show CropAspectRatioPreset, CropStyle;
export 'package:image_picker/image_picker.dart' show ImageSource;

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<File?> pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  static Future<File?> cropImage({
    required File imageFile,
    CropAspectRatioPreset? aspectRatio,
    CropStyle cropStyle = CropStyle.rectangle,
    bool lockAspectRatio = false,
    List<CropAspectRatioPreset>? presets,
  }) async {
    final defaultPresets = aspectRatio != null && lockAspectRatio
        ? [aspectRatio]
        : [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio16x9,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.square,
          ];

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      compressQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Potong Gambar',
          toolbarColor: AppColors.primary,
          statusBarLight: false,
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: AppColors.primary,
          dimmedLayerColor: Colors.black.withValues(alpha: 0.75),
          cropFrameColor: Colors.white,
          cropGridColor: Colors.white.withValues(alpha: 0.7),
          cropFrameStrokeWidth: 2,
          cropGridStrokeWidth: 1,
          showCropGrid: true,
          hideBottomControls: false,
          cropStyle: cropStyle,
          initAspectRatio: aspectRatio ?? CropAspectRatioPreset.original,
          lockAspectRatio: lockAspectRatio,
          aspectRatioPresets: presets ?? defaultPresets,
        ),
        IOSUiSettings(
          title: 'Potong Gambar',
          rotateButtonsHidden: false,
          resetButtonHidden: false,
          aspectRatioPickerButtonHidden: lockAspectRatio,
          aspectRatioLockEnabled: lockAspectRatio,
          cropStyle: cropStyle,
          aspectRatioPresets: presets ?? defaultPresets,
        ),
      ],
    );

    if (croppedFile != null) {
      return File(croppedFile.path);
    }
    return null;
  }
}
