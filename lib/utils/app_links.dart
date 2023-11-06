import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:bluecherry_client/main.dart';
import 'package:bluecherry_client/widgets/device_grid/device_grid.dart';
import 'package:flutter/foundation.dart';
import 'package:win32_registry/win32_registry.dart';

final instance = AppLinks();

Future<void> register(String scheme) async {
  if (Platform.isWindows) {
    var appPath = Platform.resolvedExecutable;

    var protocolRegKey = 'Software\\Classes\\$scheme';
    var protocolRegValue = const RegistryValue(
      'URL Protocol',
      RegistryValueType.string,
      '',
    );
    var protocolCmdRegKey = 'shell\\open\\command';
    var protocolCmdRegValue = RegistryValue(
      '',
      RegistryValueType.string,
      '"$appPath" "%1"',
    );

    Registry.currentUser.createKey(protocolRegKey)
      ..createValue(protocolRegValue)
      ..createKey(protocolCmdRegKey).createValue(protocolCmdRegValue);
  }
}

void listen() {
  instance.allUriLinkStream.listen((uri) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    debugPrint('Received URI: $uri');

    final url = uri.toString();
    final context = navigatorKey.currentContext!;
    AddExternalStreamDialog.addStream(context, url);
  });
}
