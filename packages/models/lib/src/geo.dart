import 'dart:math' as math;

import 'package:meta/meta.dart';

/// A WGS84 coordinate.
@immutable
class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  factory GeoPoint.fromJson(Map<String, Object?> json) => GeoPoint(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );

  final double latitude;
  final double longitude;

  Map<String, Object?> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };

  /// Great-circle distance in metres. Used only for display fallbacks; ranking
  /// distance comes from PostGIS server side (PRD 12.1).
  double distanceTo(GeoPoint other) {
    const earthRadiusMetres = 6371000.0;
    final dLat = _toRadians(other.latitude - latitude);
    final dLon = _toRadians(other.longitude - longitude);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(latitude)) *
            math.cos(_toRadians(other.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return earthRadiusMetres * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180.0;

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() =>
      'GeoPoint(${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)})';
}

/// Administrative area, used for scope display and dashboard filters.
@immutable
class AdminArea {
  const AdminArea({
    required this.id,
    required this.code,
    required this.nameEn,
    this.nameLocal,
    this.parentId,
    this.centroid,
  });

  factory AdminArea.fromJson(Map<String, Object?> json, {String? parentKey}) =>
      AdminArea(
        id: json['id']! as String,
        code: json['code']! as String,
        nameEn: json['name_en']! as String,
        nameLocal: json['name_local'] as String?,
        parentId: parentKey == null ? null : json[parentKey] as String?,
      );

  final String id;
  final String code;
  final String nameEn;
  final String? nameLocal;
  final String? parentId;
  final GeoPoint? centroid;

  /// Tamil name when available, otherwise the English name.
  String displayName({required bool preferLocal}) =>
      preferLocal ? (nameLocal ?? nameEn) : nameEn;
}
