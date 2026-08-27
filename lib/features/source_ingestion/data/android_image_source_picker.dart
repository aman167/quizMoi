import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../domain/image_source_picker.dart';

class AndroidImageSourcePicker implements ImageSourcePicker {
  final ImagePicker imagePicker;
  final ImageSelectionPolicy policy;

  AndroidImageSourcePicker({
    ImagePicker? imagePicker,
    this.policy = const ImageSelectionPolicy(),
  }) : imagePicker = imagePicker ?? ImagePicker();

  @override
  Future<SelectedImageSource?> captureImage() async {
    final permission = await Permission.camera.request();
    if (!permission.isGranted) {
      throw const ImageSelectionException(
        ImageSelectionErrorCode.permissionDenied,
        'Camera permission is needed only when you choose to photograph study material. You can enable it in Android settings and retry.',
      );
    }
    final captured = await imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 88,
      maxWidth: 2400,
    );
    if (captured == null) return null;
    return policy.validate(
      fileName: captured.name.isEmpty ? 'study-photo.jpg' : captured.name,
      bytes: await captured.readAsBytes(),
    );
  }
}
