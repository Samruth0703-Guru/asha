import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

class ImageEditorHelper {
  static Future<String?> cropImage({
    required BuildContext context,
    required String imagePath,
  }) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imagePath,
      aspectRatioPresets: [
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.ratio3x2,
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.ratio4x3,
        CropAspectRatioPreset.ratio16x9
      ],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop & Rotate',
          toolbarColor: const Color(0xff7C3AED),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop & Rotate',
        ),
      ],
    );
    return croppedFile?.path;
  }
}
