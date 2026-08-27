import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_library;
import 'package:quiz_moi_app/features/source_ingestion/domain/image_source_picker.dart';

void main() {
  const policy = ImageSelectionPolicy();

  test('accepts a readable camera image and exposes safe metadata', () {
    final image = image_library.Image(width: 640, height: 800);
    final bytes = Uint8List.fromList(image_library.encodeJpg(image));

    final selected = policy.validate(fileName: 'lesson.jpg', bytes: bytes);

    expect(selected.mimeType, 'image/jpeg');
    expect(selected.width, 640);
    expect(selected.height, 800);
    expect(selected.orientation, 'Portrait');
  });

  test('rejects an image that is too small for reliable reading', () {
    final image = image_library.Image(width: 320, height: 320);
    final bytes = Uint8List.fromList(image_library.encodePng(image));

    expect(
      () => policy.validate(fileName: 'tiny.png', bytes: bytes),
      throwsA(
        isA<ImageSelectionException>().having(
          (error) => error.code,
          'code',
          ImageSelectionErrorCode.invalidFile,
        ),
      ),
    );
  });
}
