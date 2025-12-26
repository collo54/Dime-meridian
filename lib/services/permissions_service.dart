import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // New method to request contact permissions
  Future<bool> requestContactsPermission() async {
    final status = await Permission.contacts.request();
    if (status.isGranted) {
      return true;
    } else {
      debugPrint('Contacts permission was denied.');
      // You might want to open app settings here if permission is permanently denied
      openAppSettings();
      return false;
    }
  }

  Future<bool> requestExternalStoragePermissions() async {
    // if (await Permission.manageExternalStorage.request().isGranted) {
    //   return true;
    // }

    // You can request multiple permissions at once.
    Map<Permission, PermissionStatus> statuses = await [
      Permission.manageExternalStorage,
      Permission.storage,
      Permission.photos,
      Permission.videos,
      Permission.audio,
      Permission.microphone,
      Permission.camera,
    ].request();

    if ((statuses[Permission.manageExternalStorage]!.isGranted &&
            statuses[Permission.storage]!.isGranted &&
            statuses[Permission.photos]!.isGranted &&
            statuses[Permission.videos]!.isGranted &&
            statuses[Permission.audio]!.isGranted &&
            statuses[Permission.microphone]!.isGranted &&
            statuses[Permission.camera]!.isGranted) ==
        true) {
      return true;
    } else {
      debugPrint('Permissions not granted');
      return false;
    }
  }

  Future<bool> requestMediaImagesPermissions() async {
    // Your implementation for requesting media images permissions
    return true;
  }
}
