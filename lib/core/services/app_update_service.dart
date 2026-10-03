import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';

/// Service responsible for managing Google Play In-App Updates.
class AppUpdateService {
  const AppUpdateService();

  /// Checks if an update is available on Google Play.
  /// Safely handles non-Android environments or missing Play Store contexts (e.g. dev builds).
  Future<AppUpdateInfo?> checkForUpdate() async {
    if (kIsWeb || !Platform.isAndroid) {
      debugPrint('[AppUpdateService] In-app updates are only supported on Android.');
      return null;
    }

    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      debugPrint(
        '[AppUpdateService] Update check result: '
        'updateAvailability=${updateInfo.updateAvailability}, '
        'immediateAllowed=${updateInfo.immediateUpdateAllowed}, '
        'flexibleAllowed=${updateInfo.flexibleUpdateAllowed}, '
        'availableVersionCode=${updateInfo.availableVersionCode}',
      );
      return updateInfo;
    } catch (e) {
      debugPrint('[AppUpdateService] Error checking for update: $e');
      return null;
    }
  }

  /// Automatically performs an in-app update check and triggers
  /// flexible or immediate flow depending on availability.
  ///
  /// - [preferImmediate]: If true and immediate update is allowed, triggers immediate flow.
  /// - [onFlexibleUpdateDownloaded]: Callback triggered when flexible update download is finished.
  Future<void> performAutoUpdateCheck({
    bool preferImmediate = false,
    VoidCallback? onFlexibleUpdateDownloaded,
  }) async {
    final info = await checkForUpdate();
    if (info == null) return;

    if (info.updateAvailability == UpdateAvailability.updateAvailable) {
      if (preferImmediate && info.immediateUpdateAllowed) {
        await startImmediateUpdate();
      } else if (info.flexibleUpdateAllowed) {
        await startFlexibleUpdate(onDownloaded: onFlexibleUpdateDownloaded);
      } else if (info.immediateUpdateAllowed) {
        await startImmediateUpdate();
      }
    } else if (info.updateAvailability == UpdateAvailability.developerTriggeredUpdateInProgress) {
      // If an update is already downloaded or in progress, complete it
      await completeFlexibleUpdate();
    }
  }

  /// Starts full-screen blocking immediate update flow.
  Future<AppUpdateResult?> startImmediateUpdate() async {
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      return await InAppUpdate.performImmediateUpdate();
    } catch (e) {
      debugPrint('[AppUpdateService] Immediate update failed: $e');
      return null;
    }
  }

  /// Starts background flexible update flow.
  Future<AppUpdateResult?> startFlexibleUpdate({VoidCallback? onDownloaded}) async {
    if (kIsWeb || !Platform.isAndroid) return null;
    try {
      final result = await InAppUpdate.startFlexibleUpdate();
      if (result == AppUpdateResult.success) {
        onDownloaded?.call();
      }
      return result;
    } catch (e) {
      debugPrint('[AppUpdateService] Flexible update failed: $e');
      return null;
    }
  }

  /// Finishes the update by restarting the app after a flexible update download completes.
  Future<void> completeFlexibleUpdate() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      debugPrint('[AppUpdateService] Completing flexible update failed: $e');
    }
  }
}

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return const AppUpdateService();
});
