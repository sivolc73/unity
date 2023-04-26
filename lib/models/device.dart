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

import 'package:bluecherry_client/models/server.dart';
import 'package:flutter/foundation.dart';

/// A [Device] present on a server.
class Device {
  /// Name of the device.
  final String name;

  /// [Uri] to the RTSP stream associated with the device.
  final int id;

  /// `true` [status] indicates that device device is working correctly or is `Online`.
  final bool status;

  /// Horizontal resolution of the device device.
  final int? resolutionX;

  /// Vertical resolution of the device device.
  final int? resolutionY;

  /// Reference to the [Server], to which this camera [Device] belongs.
  final Server server;

  const Device(
    this.name,
    this.id,
    this.status,
    this.resolutionX,
    this.resolutionY,
    this.server,
  );

  String get uri => 'live/$id';

  factory Device.fromServerJson(Map map, Server server) {
    return Device(
      map['device_name'],
      int.tryParse(map['id']) ?? 0,
      map['status'] == 'OK',
      map['resolutionX'] == null ? null : int.parse(map['resolutionX']),
      map['resolutionX'] == null ? null : int.parse(map['resolutionY']),
      server,
    );
  }

  String get streamURL =>
      'rtsp://${server.login}:${server.password}@${server.ip}:${server.rtspPort}/$uri';

  String get hslURL {
    final videoLink =
        'https://${server.ip}:${server.port}/hsl/$id/0/playlist.m3u8?authtoken=token';

    debugPrint('HSL URL: $videoLink');

    return videoLink;
  }

  /// Server name / Device name
  String get fullName {
    return '${server.name} / $name';
  }

  @override
  String toString() =>
      'Device($name, $uri, $status, $resolutionX, $resolutionY)';

  @override
  bool operator ==(dynamic other) {
    return other is Device &&
        name == other.name &&
        uri == other.uri &&
        resolutionX == other.resolutionX &&
        resolutionY == other.resolutionY;
  }

  @override
  int get hashCode =>
      name.hashCode ^
      uri.hashCode ^
      status.hashCode ^
      resolutionX.hashCode ^
      resolutionY.hashCode;

  Device copyWith({
    String? name,
    int? id,
    bool? status,
    int? resolutionX,
    int? resolutionY,
    Server? server,
  }) =>
      Device(
        name ?? this.name,
        id ?? this.id,
        status ?? this.status,
        resolutionX ?? this.resolutionX,
        resolutionY ?? this.resolutionY,
        server ?? this.server,
      );

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'uri': uri,
      'status': status,
      'resolutionX': resolutionX,
      'resolutionY': resolutionY,
      'server': server.toJson(devices: false),
    };
  }

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      json['name'],
      int.tryParse(json['uri'] ?? '') ?? 0,
      json['status'],
      json['resolutionX'],
      json['resolutionY'],
      Server.fromJson(json['server'] as Map<String, dynamic>),
    );
  }
}
