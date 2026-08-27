import 'dart:typed_data';

import 'package:image/image.dart' as image_library;

enum ImageSelectionErrorCode {
  permissionDenied,
  invalidFile,
  fileTooLarge,
  unreadable,
}

class ImageSelectionException implements Exception {
  final ImageSelectionErrorCode code;
  final String message;

  const ImageSelectionException(this.code, this.message);

  @override
  String toString() => message;
}

class SelectedImageSource {
  final String fileName;
  final String title;
  final String mimeType;
  final Uint8List bytes;
  final int width;
  final int height;

  const SelectedImageSource({
    required this.fileName,
    required this.title,
    required this.mimeType,
    required this.bytes,
    required this.width,
    required this.height,
  });

  int get fileSizeBytes => bytes.length;
  String get orientation => width == height
      ? 'Square'
      : width > height
      ? 'Landscape'
      : 'Portrait';
}

abstract interface class ImageSourcePicker {
  Future<SelectedImageSource?> captureImage();
}

class ImageSelectionPolicy {
  static const int maxFileSizeBytes = 10 * 1024 * 1024;
  static const int minimumDimension = 480;
  static const int maximumDimension = 8000;

  const ImageSelectionPolicy();

  SelectedImageSource validate({
    required String fileName,
    required Uint8List bytes,
  }) {
    if (bytes.isEmpty) {
      throw const ImageSelectionException(
        ImageSelectionErrorCode.unreadable,
        'The captured image is empty. Retake the photograph.',
      );
    }
    if (bytes.length > maxFileSizeBytes) {
      throw const ImageSelectionException(
        ImageSelectionErrorCode.fileTooLarge,
        'This image is larger than 10 MB. Retake it closer to the page.',
      );
    }
    final decoded = image_library.decodeImage(bytes);
    if (decoded == null) {
      throw const ImageSelectionException(
        ImageSelectionErrorCode.unreadable,
        'The captured image could not be read. Retake the photograph.',
      );
    }
    if (decoded.width < minimumDimension || decoded.height < minimumDimension) {
      throw const ImageSelectionException(
        ImageSelectionErrorCode.invalidFile,
        'The image is too small to read reliably. Move closer and retake it.',
      );
    }
    if (decoded.width > maximumDimension || decoded.height > maximumDimension) {
      throw const ImageSelectionException(
        ImageSelectionErrorCode.invalidFile,
        'The image dimensions are too large. Retake it using the normal camera setting.',
      );
    }
    final lowerName = fileName.toLowerCase();
    final mimeType = lowerName.endsWith('.png')
        ? 'image/png'
        : lowerName.endsWith('.webp')
        ? 'image/webp'
        : 'image/jpeg';
    return SelectedImageSource(
      fileName: fileName,
      title: 'Camera study image',
      mimeType: mimeType,
      bytes: bytes,
      width: decoded.width,
      height: decoded.height,
    );
  }
}
