/*
 * This file is a part of Bluecherry Client (https://https://github.com/bluecherrydvr/bluecherry_client).
 *
 * Copyright 2022 Bluecherry, LLC
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 3 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import 'dart:io';
import 'dart:math';
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:status_bar_control/status_bar_control.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import 'package:bluecherry_client/api/api.dart';
import 'package:bluecherry_client/firebase_options.dart';
import 'package:bluecherry_client/providers/mobile_view_provider.dart';
import 'package:bluecherry_client/providers/server_provider.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/widgets/events_screen.dart';
import 'package:bluecherry_client/widgets/device_tile.dart';
import 'package:bluecherry_client/utils/constants.dart';
import 'package:bluecherry_client/utils/methods.dart';
import 'package:bluecherry_client/models/device.dart';

import 'package:bluecherry_client/main.dart';

/// Callbacks received from the [FirebaseMessaging] instance.
Future<void> _firebaseMessagingHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  HttpOverrides.global = DevHttpOverrides();
  await EasyLocalization.ensureInitialized();
  await ServersProvider.ensureInitialized();
  await SettingsProvider.ensureInitialized();
  if (SettingsProvider.instance.snoozedUntil.isAfter(DateTime.now())) {
    debugPrint(
      'SettingsProvider.instance.snoozedUntil.isAfter(DateTime.now())',
    );
    return;
  }
  debugPrint(message.toMap().toString());
  try {
    await AwesomeNotifications().initialize(
      'resource://drawable/ic_stat_linked_camera',
      [
        NotificationChannel(
          channelKey: 'com.bluecherrydvr',
          channelName: 'Bluecherry DVR',
          channelDescription: 'Bluecherry DVR Notifications',
          ledColor: Colors.white,
        )
      ],
      debug: true,
    );
    final eventType = message.data['eventType'];
    final name = message.data['deviceName'];
    final serverUUID = message.data['serverId'];
    final id = message.data['deviceId'];
    if (!['motion_event', 'device_state'].contains(eventType)) {
      return;
    }
    final key = Random().nextInt(pow(2, 8) ~/ 1 - 1);
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: key,
        color: const Color.fromRGBO(92, 107, 192, 1),
        channelKey: 'com.bluecherrydvr',
        title: getEventNameFromID(eventType),
        body: name,
        displayOnBackground: true,
        displayOnForeground: true,
        payload: message.data
            .map<String, String>(
              (key, value) => MapEntry(
                key,
                value.toString(),
              ),
            )
            .cast(),
      ),
      actionButtons: [
        NotificationActionButton(
          label: 'snooze_15'.tr(),
          key: 'snooze_15',
        ),
        NotificationActionButton(
          label: 'snooze_30'.tr(),
          key: 'snooze_30',
        ),
        NotificationActionButton(
          label: 'snooze_60'.tr(),
          key: 'snooze_60',
        ),
      ],
    );
    try {
      final server = ServersProvider.instance.servers
          .firstWhere((server) => server.serverUUID == serverUUID);
      final events = await API.instance.getEvents(
        await API.instance.checkServerCredentials(server),
        limit: 10,
      );
      final event = events.firstWhere(
        (event) {
          debugPrint('$id == ${event.deviceID}');
          return id == event.deviceID.toString();
        },
      );
      final thumbnail =
          await API.instance.getThumbnail(server, event.id.toString());
      debugPrint(thumbnail);
      if (thumbnail != null) {
        final path = await _downloadAndSaveFile(thumbnail, event.id.toString());
        debugPrint(path);
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: key,
            color: const Color.fromRGBO(92, 107, 192, 1),
            channelKey: 'com.bluecherrydvr',
            bigPicture: path,
            title: getEventNameFromID(eventType),
            body: name,
            displayOnBackground: true,
            displayOnForeground: true,
            payload: message.data
                .map<String, String>(
                  (key, value) => MapEntry(
                    key,
                    value.toString(),
                  ),
                )
                .cast(),
            notificationLayout: NotificationLayout.BigPicture,
          ),
          actionButtons: [
            NotificationActionButton(
              label: 'snooze_15'.tr(),
              key: 'snooze_15',
            ),
            NotificationActionButton(
              label: 'snooze_30'.tr(),
              key: 'snooze_30',
            ),
            NotificationActionButton(
              label: 'snooze_60'.tr(),
              key: 'snooze_60',
            ),
          ],
        );
      }
    } catch (exception, stacktrace) {
      debugPrint(exception.toString());
      debugPrint(stacktrace.toString());
    }
  } catch (exception, stacktrace) {
    debugPrint(exception.toString());
    debugPrint(stacktrace.toString());
  }
}

Future<void> _backgroundClickAction(ReceivedAction action) async {
  await Firebase.initializeApp();
  HttpOverrides.global = DevHttpOverrides();
  await EasyLocalization.ensureInitialized();
  await ServersProvider.ensureInitialized();
  await SettingsProvider.ensureInitialized();
  debugPrint(action.toString());
  // Notification action buttons were not pressed.
  if (action.buttonKeyPressed.isEmpty) {
    debugPrint('action.buttonKeyPressed.isEmpty');
    // Fetch device & server details to show the [DeviceFullscreenViewer].
    if (SettingsProvider.instance.notificationClickAction ==
        NotificationClickAction.showFullscreenCamera) {
      final eventType = action.payload!['eventType'];
      final serverUUID = action.payload!['serverId'];
      final id = action.payload!['deviceId'];
      final name = action.payload!['deviceName'];
      // Return if same device is already playing or unknown event type is detected.
      if (_mutex == id ||
          !['motion_event', 'device_state'].contains(eventType)) {
        return;
      }
      final server = ServersProvider.instance.servers
          .firstWhere((server) => server.serverUUID == serverUUID);
      final device = Device(name!, 'live/$id', true, 0, 0, server);
      final player =
          MobileViewProvider.instance.getVideoPlayerController(device);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      StatusBarControl.setHidden(true);
      // No [DeviceFullscreenViewer] route is ever pushed due to notification click into the navigator.
      // Thus, push a new route.
      if (_mutex == null) {
        _mutex = id;
        await navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => DeviceFullscreenViewer(
              device: device,
              ijkPlayer: player,
              restoreStatusBarStyleOnDispose: true,
            ),
          ),
        );
        _mutex = null;
      }
      // A [DeviceFullscreenViewer] route is likely pushed before due to notification click into the navigator.
      // Thus, replace the existing route.
      else {
        navigatorKey.currentState?.pop();
        await Future.delayed(const Duration(seconds: 1));
        _mutex = id;
        await navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => DeviceFullscreenViewer(
              device: device,
              ijkPlayer: player,
              restoreStatusBarStyleOnDispose: true,
            ),
          ),
        );
        _mutex = null;
      }
      await player.release();
      await player.release();
    } else {
      if (_mutex == null) {
        _mutex = 'events_screen';
        await navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => const EventsScreen(),
          ),
        );
        _mutex = null;
      }
    }
  }
  // Any of the snooze buttons were pressed.
  else {
    debugPrint('action.buttonKeyPressed.isNotEmpty');
    final duration = Duration(
      minutes: {
        'snooze_15': 15,
        'snooze_30': 30,
        'snooze_60': 60,
      }[action.buttonKeyPressed]!,
    );
    SettingsProvider.instance.snoozedUntil = DateTime.now().add(duration);
    if (action.id != null) {
      AwesomeNotifications().dismiss(action.id!);
    }
  }
}

Future<String> _downloadAndSaveFile(String url, String eventID) async {
  final directory = await getExternalStorageDirectory();
  final filePath = '${directory?.path}/$eventID.png';
  final file = File(filePath);
  // Download the event thumbnail only if it doesn't exist already.
  if (!await file.exists()) {
    final response = await get(Uri.parse(url));
    await file.create(recursive: true);
    await file.writeAsBytes(response.bodyBytes);
  }
  debugPrint('file://$filePath');
  return 'file://$filePath';
}

/// Initialize & handle Firebase core & messaging plugins.
///
/// Saves entry point of application from getting unnecessarily cluttered.
///
abstract class FirebaseConfiguration {
  static Future<void> ensureInitialized() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingHandler);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (SettingsProvider.instance.snoozedUntil.isAfter(DateTime.now())) {
        debugPrint(
          'SettingsProvider.instance.snoozedUntil.isAfter(DateTime.now())',
        );
        return;
      }
      debugPrint(message.toMap().toString());
      try {
        final eventType = message.data['eventType'];
        final name = message.data['deviceName'];
        final serverUUID = message.data['serverId'];
        final id = message.data['deviceId'];
        if (!['motion_event', 'device_state'].contains(eventType)) {
          return;
        }
        final key = Random().nextInt(pow(2, 8) ~/ 1 - 1);
        AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: key,
            color: const Color.fromRGBO(92, 107, 192, 1),
            channelKey: 'com.bluecherrydvr',
            title: getEventNameFromID(eventType),
            body: name,
            displayOnBackground: true,
            displayOnForeground: true,
            payload: message.data
                .map<String, String>(
                  (key, value) => MapEntry(
                    key,
                    value.toString(),
                  ),
                )
                .cast(),
          ),
          actionButtons: [
            NotificationActionButton(
              label: 'snooze_15'.tr(),
              key: 'snooze_15',
            ),
            NotificationActionButton(
              label: 'snooze_30'.tr(),
              key: 'snooze_30',
            ),
            NotificationActionButton(
              label: 'snooze_60'.tr(),
              key: 'snooze_60',
            ),
          ],
        );
        try {
          final server = ServersProvider.instance.servers
              .firstWhere((server) => server.serverUUID == serverUUID);
          final events = await API.instance.getEvents(
            await API.instance.checkServerCredentials(server),
            limit: 10,
          );
          final event = events.firstWhere(
            (event) {
              debugPrint('$id == ${event.deviceID}');
              return id == event.deviceID.toString();
            },
          );
          final thumbnail =
              await API.instance.getThumbnail(server, event.id.toString());
          debugPrint(thumbnail);
          if (thumbnail != null) {
            final path =
                await _downloadAndSaveFile(thumbnail, event.id.toString());
            await AwesomeNotifications().createNotification(
              content: NotificationContent(
                id: key,
                color: const Color.fromRGBO(92, 107, 192, 1),
                channelKey: 'com.bluecherrydvr',
                bigPicture: path,
                title: getEventNameFromID(eventType),
                body: name,
                displayOnBackground: true,
                displayOnForeground: true,
                payload: message.data
                    .map<String, String>(
                      (key, value) => MapEntry(
                        key,
                        value.toString(),
                      ),
                    )
                    .cast(),
                notificationLayout: NotificationLayout.BigPicture,
              ),
              actionButtons: [
                NotificationActionButton(
                  label: '15 minutes',
                  key: 'snooze_15',
                ),
                NotificationActionButton(
                  label: '30 minutes',
                  key: 'snooze_30',
                ),
                NotificationActionButton(
                  label: '1 hour',
                  key: 'snooze_60',
                ),
              ],
            );
          }
        } catch (exception, stacktrace) {
          debugPrint(exception.toString());
          debugPrint(stacktrace.toString());
        }
      } catch (exception, stacktrace) {
        debugPrint(exception.toString());
        debugPrint(stacktrace.toString());
      }
    });
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await AwesomeNotifications().initialize(
      'resource://drawable/ic_stat_linked_camera',
      [
        NotificationChannel(
          channelKey: 'com.bluecherrydvr',
          channelName: 'Bluecherry DVR',
          channelDescription: 'Bluecherry DVR Notifications',
          ledColor: Colors.white,
        )
      ],
      backgroundClickAction: _backgroundClickAction,
      debug: true,
    );
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
    AwesomeNotifications().actionStream.listen((action) {
      _backgroundClickAction(action);
    });
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) async {
        debugPrint('[FirebaseMessaging.instance.onTokenRefresh]: $token');
        final instance = await SharedPreferences.getInstance();
        await instance.setString(
          kSharedPreferencesNotificationToken,
          token,
        );
        for (final server in ServersProvider.instance.servers) {
          API.instance.registerNotificationToken(
            await API.instance.checkServerCredentials(server),
            token,
          );
        }
      },
    );
    // Sometimes [FirebaseMessaging.instance.onTokenRefresh] is not getting invoked.
    // Having this as a fallback.
    FirebaseMessaging.instance.getToken().then((token) async {
      debugPrint('[FirebaseMessaging.instance.getToken]: $token');
      if (token != null) {
        final instance = await SharedPreferences.getInstance();
        // Do not proceed, if token is already saved.
        if (instance.getString(kSharedPreferencesNotificationToken) == token) {
          return;
        }
        await instance.setString(
          kSharedPreferencesNotificationToken,
          token,
        );
        for (final server in ServersProvider.instance.servers) {
          API.instance.registerNotificationToken(
            await API.instance.checkServerCredentials(server),
            token,
          );
        }
      }
    });
  }
}

String? _mutex;