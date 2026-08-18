import 'package:flutter/services.dart';

import '../domain/pdf_source_picker.dart';

class AndroidPdfSourcePicker implements PdfSourcePicker {
  static const MethodChannel _channel = MethodChannel(
    'com.quizmoi.quiz_moi/source_import',
  );

  final PdfSelectionPolicy policy;

  const AndroidPdfSourcePicker({this.policy = const PdfSelectionPolicy()});

  @override
  Future<SelectedPdfSource?> pickPdf() async {
    final Map<Object?, Object?>? selection;
    try {
      selection = await _channel.invokeMapMethod<Object?, Object?>('pickPdf', {
        'maxBytes': PdfSelectionPolicy.maxFileSizeBytes,
      });
    } on PlatformException catch (error) {
      if (error.code == 'file_too_large') {
        throw const PdfSelectionException(
          PdfSelectionErrorCode.fileTooLarge,
          'This PDF is larger than 10 MB. Choose a smaller file to control generation time and cost.',
        );
      }
      throw const PdfSelectionException(
        PdfSelectionErrorCode.unreadable,
        'The Android document picker could not read this PDF. Choose another file and try again.',
      );
    }
    if (selection == null) return null;

    final fileName = selection['fileName'] as String? ?? 'Imported PDF.pdf';
    final bytes = selection['bytes'] as Uint8List?;
    if (bytes == null) {
      throw const PdfSelectionException(
        PdfSelectionErrorCode.unreadable,
        'Android did not return readable PDF data.',
      );
    }
    return policy.validate(fileName: fileName, bytes: bytes);
  }
}
