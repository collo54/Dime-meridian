import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class AppUpdateService {
  static Future<void> checkForUpdate() async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable &&
          updateInfo.flexibleUpdateAllowed) {
        //await InAppUpdate.performImmediateUpdate();
        // For flexible update (downloads in background and asks for restart)
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
      }
    } catch (e) {
      debugPrint('flexible update check failed: $e');
    }
  }
}
