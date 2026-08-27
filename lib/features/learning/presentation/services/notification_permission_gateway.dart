import 'package:permission_handler/permission_handler.dart';

abstract interface class NotificationPermissionGateway {
  Future<bool> requestPermission();
}

class AndroidNotificationPermissionGateway
    implements NotificationPermissionGateway {
  const AndroidNotificationPermissionGateway();

  @override
  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }
}
