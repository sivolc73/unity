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

import 'dart:io';

import 'package:bluecherry_client/providers/settings_provider.dart';
import 'package:bluecherry_client/screens/settings/settings_desktop.dart';
import 'package:bluecherry_client/screens/settings/shared/options_chooser_tile.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class EventsAndDownloadsSettings extends StatelessWidget {
  const EventsAndDownloadsSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = context.watch<SettingsProvider>();
    return ListView(children: [
      SubHeader(loc.downloads),
      if (settings.kShowDebugInfo.value)
        CheckboxListTile.adaptive(
          value: settings.kChooseLocationEveryTime.value,
          onChanged: (v) {
            if (v != null) {
              settings.kChooseLocationEveryTime.value = v;
            }
          },
          contentPadding: DesktopSettings.horizontalPadding,
          secondary: CircleAvatar(
            backgroundColor: Colors.transparent,
            foregroundColor: theme.iconTheme.color,
            child: const Icon(Icons.create_new_folder),
          ),
          title: const Text('Choose location for each download'),
        ),
      ListTile(
        contentPadding: DesktopSettings.horizontalPadding,
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.notifications_paused),
        ),
        title: Text(loc.downloadPath),
        subtitle: Text(settings.kDownloadsDirectory.value),
        trailing: const Icon(Icons.navigate_next),
        onTap: () async {
          final selectedDirectory = await FilePicker.platform.getDirectoryPath(
            dialogTitle: loc.downloadPath,
            initialDirectory: settings.kDownloadsDirectory.value,
            lockParentWindow: true,
          );

          if (selectedDirectory != null) {
            settings.kDownloadsDirectory.value =
                Directory(selectedDirectory).path;
          }
        },
      ),
      if (settings.kShowDebugInfo.value)
        CheckboxListTile.adaptive(
          value: false,
          onChanged: (v) {},
          contentPadding: DesktopSettings.horizontalPadding,
          secondary: CircleAvatar(
            backgroundColor: Colors.transparent,
            foregroundColor: theme.iconTheme.color,
            child: const Icon(Icons.close),
          ),
          title: const Text(
              'Block the app from closing when there are ongoing downloads'),
        ),
      const SubHeader('Events'),
      if (settings.kShowDebugInfo.value)
        CheckboxListTile.adaptive(
          value: settings.kPictureInPicture.value,
          onChanged: (v) {
            if (v != null) {
              settings.kPictureInPicture.value = v;
            }
          },
          contentPadding: DesktopSettings.horizontalPadding,
          secondary: CircleAvatar(
            backgroundColor: Colors.transparent,
            foregroundColor: theme.iconTheme.color,
            child: const Icon(Icons.picture_in_picture),
          ),
          title: const Text('Picture-in-picture'),
          subtitle: const Text(
            'Move to picture-in-picture mode when the app moves to background.',
          ),
        ),
      ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.speed),
        ),
        contentPadding: DesktopSettings.horizontalPadding,
        title: const Text('Default speed'),
        subtitle: Text(settings.kEventsSpeed.value.toStringAsFixed(1)),
        trailing: SizedBox(
          width: 160.0,
          child: Slider(
            value: settings.kEventsSpeed.value.clamp(
              settings.kEventsSpeed.min!,
              settings.kEventsSpeed.max!,
            ),
            min: settings.kEventsSpeed.min!,
            max: settings.kEventsSpeed.max!,
            onChanged: (v) {
              settings.kEventsSpeed.value = v;
            },
          ),
        ),
      ),
      ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.transparent,
          foregroundColor: theme.iconTheme.color,
          child: const Icon(Icons.equalizer),
        ),
        contentPadding: DesktopSettings.horizontalPadding,
        title: const Text('Default volume'),
        subtitle: const Text('1.0'),
        trailing: SizedBox(
          width: 160.0,
          child: Slider(
            value: settings.kEventsVolume.value,
            onChanged: (v) {
              settings.kEventsVolume.value = v;
            },
          ),
        ),
      ),
      const SizedBox(height: 20.0),
      if (settings.kShowDebugInfo.value) ...[
        const SubHeader('Timeline of Events'),
        CheckboxListTile.adaptive(
          value: settings.kShowDifferentColorsForEvents.value,
          onChanged: (v) {
            if (v != null) {
              settings.kShowDifferentColorsForEvents.value = v;
            }
          },
          contentPadding: DesktopSettings.horizontalPadding,
          secondary: CircleAvatar(
            backgroundColor: Colors.transparent,
            foregroundColor: theme.iconTheme.color,
            child: const Icon(Icons.color_lens),
          ),
          title: const Text('Show different colors for events'),
          subtitle: const Text(
            'Whether to show different colors for events in the timeline. '
            'This will help you to easily identify the events.',
          ),
        ),
        CheckboxListTile.adaptive(
          value: settings.kPauseToBuffer.value,
          onChanged: (v) {
            if (v != null) {
              settings.kPauseToBuffer.value = v;
            }
          },
          contentPadding: DesktopSettings.horizontalPadding,
          secondary: CircleAvatar(
            backgroundColor: Colors.transparent,
            foregroundColor: theme.iconTheme.color,
            child: const Icon(Icons.pause_presentation),
          ),
          title: const Text('Pause to buffer'),
          subtitle: const Text(
            'Whether the entire timeline should pause to buffer the events.',
          ),
        ),
        OptionsChooserTile(
          title: 'Initial point',
          description: 'When the timeline should begin.',
          icon: Icons.flag,
          value: '',
          values: const [
            Option(value: '', icon: Icons.start, text: 'Beginning'),
            Option(value: '', icon: Icons.first_page, text: 'First event'),
            Option(
                value: '', icon: Icons.hourglass_bottom, text: 'An hour ago'),
          ],
          onChanged: (v) {},
        ),
      ],
    ]);
  }
}
