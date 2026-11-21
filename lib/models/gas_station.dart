import 'package:latlong2/latlong.dart';

class GasStation {
  final String id;
  final String name;
  final String brand;
  final String street;
  final String place;
  final double latitude;
  final double longitude;
  final double? diesel;
  final double? e5;
  final double? e10;
  final double distanceKm;
  final bool isOpen;

  GasStation({
    required this.id,
    required this.name,
    required this.brand,
    required this.street,
    required this.place,
    required this.latitude,
    required this.longitude,
    this.diesel,
    this.e5,
    this.e10,
    required this.distanceKm,
    required this.isOpen,
  });

  factory GasStation.fromJson(Map<String, dynamic> json) {
    return GasStation(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      brand: json['brand']?.toString() ?? 'Generic',
      street: json['street']?.toString() ?? '',
      place: json['place']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      diesel: (json['diesel'] as num?)?.toDouble(),
      e5: (json['e5'] as num?)?.toDouble(),
      e10: (json['e10'] as num?)?.toDouble(),
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      isOpen: json['is_open'] as bool? ?? true,
    );
  }

  // UI Helper Getters
  double get distance => distanceKm;
  double get gasolinePrice => e5 ?? 0.0;
  double get e10Price => e10 ?? 0.0;
  double get dieselPrice => diesel ?? 0.0;
  String get address => '$street, $place'.trim();
  LatLng get location => LatLng(latitude, longitude);

  GasStation copyWithPrices({
    double? gasolinePrice,
    double? e10Price,
    double? dieselPrice,
    bool? isOpen,
  }) {
    return GasStation(
      id: id,
      name: name,
      brand: brand,
      street: street,
      place: place,
      latitude: latitude,
      longitude: longitude,
      e5: gasolinePrice ?? e5,
      e10: e10Price ?? e10,
      diesel: dieselPrice ?? diesel,
      distanceKm: distanceKm,
      isOpen: isOpen ?? this.isOpen,
    );
  }
}
