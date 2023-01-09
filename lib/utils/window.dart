/*
 * This file is a part of Bluecherry Client (https://github.com/bluecherrydvr/unity).
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

import 'dart:convert';

import 'package:bluecherry_client/models/device.dart';
import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/widgets/misc.dart';

import 'package:unity_multi_window/unity_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

const kInitialWindowSize = Size(900, 645);

/// Configures the current window
Future<void> configureWindow() async {
  await WindowManager.instance.ensureInitialized();
  windowManager.waitUntilReadyToShow().then((_) async {
    await windowManager.setTitleBarStyle(
      TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    await windowManager.setSize(kInitialWindowSize);
    await windowManager.setMinimumSize(const Size(900, 600));
    // await windowManager.center();
    await windowManager.setSkipTaskbar(false);
    await windowManager.show();
  });
}

/// Configures the camera sub window
///
/// See also:
///
///  * [SingleCameraWindow]
Future<void> configureCameraWindow(String title) async {
  await WindowManager.instance.ensureInitialized();
  await windowManager.setTitle(title);
}

extension DeviceWindowExtension on Device {
  /// Opens this device in a new window
  void openInANewWindow() async {
    assert(isDesktop, 'Can not open a new window in a non-desktop environment');

    debugPrint('Opening a new window');
    final window = await MultiWindow.run([
      json.encode(toJson()),
      '${SettingsProvider.instance.themeMode.index}',
    ]);

    debugPrint('Opened window with id ${window.windowId}');
  }
}
