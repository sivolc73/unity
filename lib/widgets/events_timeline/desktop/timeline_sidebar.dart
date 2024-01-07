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

import 'package:auto_size_text/auto_size_text.dart';
import 'package:bluecherry_client/widgets/collapsable_sidebar.dart';
import 'package:bluecherry_client/widgets/events/events_screen.dart';
import 'package:bluecherry_client/widgets/events_timeline/events_playback.dart';
import 'package:bluecherry_client/widgets/misc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class TimelineSidebar extends StatelessWidget {
  const TimelineSidebar({
    super.key,
    required this.date,
    required this.onDateChanged,
    required this.onFetch,
  });

  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;

  final VoidCallback onFetch;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final state = eventsPlaybackScreenKey.currentState!;

    return Card(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadiusDirectional.vertical(
          top: Radius.circular(12.0),
        ),
      ),
      margin: const EdgeInsetsDirectional.only(end: 4.0, top: 4.0, start: 4.0),
      child: CollapsableSidebar(
        left: false,
        builder: (context, collapsed, collapseButton) {
          collapseButton = Padding(
            padding: const EdgeInsetsDirectional.only(top: 4.0),
            child: collapseButton,
          );
          if (collapsed) return collapseButton;

          return Column(children: [
            SubHeader(
              loc.servers,
              height: 40.0,
              trailing: collapseButton,
              padding: const EdgeInsetsDirectional.only(start: 16.0, end: 4.0),
            ),
            Expanded(
              child: StatefulBuilder(builder: (context, setState) {
                return EventsDevicesPicker(
                  disabledDevices: state.disabledDevices,
                  events: state.events,
                  onDisabledDeviceAdded: (device) =>
                      setState(() => state.disabledDevices.add(device)),
                  onDisabledDeviceRemoved: (device) =>
                      setState(() => state.disabledDevices.remove(device)),
                );
              }),
            ),
            SubHeader(loc.timeFilter, height: 24.0),
            ListTile(
              title: AutoSizeText(
                () {
                  final formatter = DateFormat.MEd();
                  if (DateUtils.isSameDay(date, DateTime.now())) {
                    return loc.today;
                  } else {
                    return formatter.format(date);
                  }
                }(),
                maxLines: 1,
              ),
              onTap: () async {
                final result = await showDatePicker(
                  context: context,
                  initialDate: date,
                  firstDate: DateTime.utc(1970),
                  lastDate: DateTime.now(),
                  initialEntryMode: DatePickerEntryMode.calendarOnly,
                  currentDate: date,
                );
                if (result != null) {
                  debugPrint('date picked: from $date to $result');
                  onDateChanged(result);
                }
              },
            ),
          ]);
        },
      ),
    );
  }
}
