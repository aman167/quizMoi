import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_moi_app/features/source_ingestion/domain/pdf_source_picker.dart';

void main() {
  const policy = PdfSelectionPolicy();

  test('rejects files that are not named as PDFs', () {
    expect(
      () => policy.validate(
        fileName: 'lesson.docx',
        bytes: Uint8List.fromList('%PDF-1.4'.codeUnits),
      ),
      throwsA(
        isA<PdfSelectionException>().having(
          (error) => error.code,
          'code',
          PdfSelectionErrorCode.invalidFile,
        ),
      ),
    );
  });

  test('rejects content without a PDF signature', () {
    expect(
      () => policy.validate(
        fileName: 'lesson.pdf',
        bytes: Uint8List.fromList('plain text'.codeUnits),
      ),
      throwsA(
        isA<PdfSelectionException>().having(
          (error) => error.code,
          'code',
          PdfSelectionErrorCode.unreadable,
        ),
      ),
    );
  });

  test('rejects PDFs larger than the prototype limit', () {
    final bytes = Uint8List(PdfSelectionPolicy.maxFileSizeBytes + 1)
      ..setRange(0, 5, '%PDF-'.codeUnits);
    expect(
      () => policy.validate(fileName: 'book.pdf', bytes: bytes),
      throwsA(
        isA<PdfSelectionException>().having(
          (error) => error.code,
          'code',
          PdfSelectionErrorCode.fileTooLarge,
        ),
      ),
    );
  });

  test('accepts a valid PDF and derives its source title', () {
    final source = policy.validate(
      fileName: 'Leçon de Camille.pdf',
      bytes: Uint8List.fromList('%PDF-1.4\ntest'.codeUnits),
    );

    expect(source.title, 'Leçon de Camille');
    expect(source.fileName, 'Leçon de Camille.pdf');
    expect(source.fileSizeBytes, greaterThan(5));
  });
}
