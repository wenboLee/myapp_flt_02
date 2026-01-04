import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Notifications {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Initialize the plugin. Call once at app startup.
  static Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const darwinInit = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const linuxInit = LinuxInitializationSettings(defaultActionName: 'Open');

    // Windows initialization if running on Windows.
    // WindowsInitializationSettings has a default constructor in the
    // flutter_local_notifications plugin; pass it when on Windows.
    final WindowsInitializationSettings? windowsInit = Platform.isWindows
        ? WindowsInitializationSettings(
            appName: 'MyAppFlt02',
            appUserModelId: 'Cn.Wenbooo.Myappflt02.Myapp_flt_02',
            guid: '8e0f7a12-bfb3-4fe8-b9a5-48fd50a15a9a',
            // appUserModelId: 'Com.Dexterous.FlutterLocalNotificationsExample',
            // Search online for GUID generators to make your own
            // guid: 'd49b0314-ee7a-4626-bf79-97cdb8a991bb',
          )
        : null;

    final initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
      linux: linuxInit,
      windows: windowsInit,
    );

    await _plugin.initialize(initSettings);

    _initialized = true;
  }

  /// Show a simple notification with given title and body.
  static Future<void> showNotification({required int id, required String title, String? body, String? payload}) async {
    if (!_initialized) {
      await init();
    }

    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      '默认',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const darwinDetails = DarwinNotificationDetails();
    const linuxDetails = LinuxNotificationDetails();
    final windowsDetails = Platform.isWindows ? WindowsNotificationDetails() : null;

    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
      linux: linuxDetails,
      windows: windowsDetails,
    );

    await _plugin.show(id, title, body, details, payload: payload);
  }
}
