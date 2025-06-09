import 'package:permission_handler/permission_handler.dart';

Future<void> requestAllPermissions() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.camera,
    Permission.contacts,
    Permission.location,
    Permission.locationWhenInUse,
    Permission.storage,
    Permission.phone,
  ].request();

  statuses.forEach((permission, status) {
    if (status.isGranted) {
      print('${permission.toString()} granted');
    } else if (status.isPermanentlyDenied) {
      print('${permission.toString()} permanently denied');
      // You can open app settings if needed:
      // openAppSettings();
    } else {
      print('${permission.toString()} denied');
    }
  });
}
