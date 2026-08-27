import 'dart:typed_data';

enum PdfSelectionErrorCode { invalidFile, fileTooLarge, unreadable }

class PdfSelectionException implements Exception {
  final PdfSelectionErrorCode code;
  final String message;

  const PdfSelectionException(this.code, this.message);

  @override
  String toString() => message;
}

class SelectedPdfSource {
  final String fileName;
  final String title;
  final Uint8List bytes;

  const SelectedPdfSource({
    required this.fileName,
    required this.title,
    required this.bytes,
  });

  int get fileSizeBytes => bytes.length;
}

abstract interface class PdfSourcePicker {
  /// Returns null when the learner closes Android's picker without choosing a
  /// file. Expected selection problems are [PdfSelectionException] values.
  Future<SelectedPdfSource?> pickPdf();
}

class PdfSelectionPolicy {
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  const PdfSelectionPolicy();

  SelectedPdfSource validate({
    required String fileName,
    required Uint8List bytes,
  }) {
    if (!fileName.toLowerCase().endsWith('.pdf')) {
      throw const PdfSelectionException(
        PdfSelectionErrorCode.invalidFile,
        'Choose a PDF file. Other document types are not supported yet.',
      );
    }
    if (bytes.isEmpty ||
        bytes.length < 5 ||
        String.fromCharCodes(bytes.take(5)) != '%PDF-') {
      throw const PdfSelectionException(
        PdfSelectionErrorCode.unreadable,
        'This file is not a readable PDF.',
      );
    }
    if (bytes.length > maxFileSizeBytes) {
      throw const PdfSelectionException(
        PdfSelectionErrorCode.fileTooLarge,
        'This PDF is larger than 10 MB. Choose a smaller file to control generation time and cost.',
      );
    }

    final title = fileName.substring(0, fileName.length - 4).trim();
    return SelectedPdfSource(
      fileName: fileName,
      title: title.isEmpty ? 'Imported PDF' : title,
      bytes: bytes,
    );
  }
}
