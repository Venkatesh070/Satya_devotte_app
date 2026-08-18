// lib/features/poojakit/data/models/pickup_location_model.dart

/// Warehouse / come-and-collect location from `GET /shipping/pickup-location`
/// (also snapshotted on pickup orders as `order.pickupLocation`).
class PickupLocationModel {
  const PickupLocationModel({
    required this.company,
    required this.streetAddress,
    required this.localArea,
    required this.city,
    required this.zone,
    required this.postalCode,
    required this.country,
    required this.enteredAddress,
    required this.contactName,
    required this.contactPhone,
    required this.contactEmail,
    required this.hours,
    required this.instructions,
    this.lat,
    this.lng,
  });

  final String company;
  final String streetAddress;
  final String localArea;
  final String city;
  final String zone;
  final String postalCode;
  final String country;
  final String enteredAddress;
  final String contactName;
  final String contactPhone;
  final String contactEmail;
  final String hours;
  final String instructions;
  final double? lat;
  final double? lng;

  factory PickupLocationModel.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => (v ?? '').toString();
    return PickupLocationModel(
      company: s(json['company']),
      streetAddress: s(json['streetAddress'] ?? json['street_address']),
      localArea: s(json['localArea'] ?? json['local_area']),
      city: s(json['city']),
      zone: s(json['zone']),
      postalCode: s(json['postalCode'] ?? json['code']),
      country: s(json['country']).isEmpty ? 'South Africa' : s(json['country']),
      enteredAddress: s(json['enteredAddress'] ?? json['entered_address']),
      contactName: s(json['contactName']),
      contactPhone: s(json['contactPhone']),
      contactEmail: s(json['contactEmail']),
      hours: s(json['hours']),
      instructions: s(json['instructions']),
      lat: _toDouble(json['lat']),
      lng: _toDouble(json['lng']),
    );
  }

  String get singleLine {
    if (enteredAddress.trim().isNotEmpty) return enteredAddress.trim();
    final parts = <String>[
      if (company.trim().isNotEmpty) company.trim(),
      if (streetAddress.trim().isNotEmpty) streetAddress.trim(),
      if (localArea.trim().isNotEmpty) localArea.trim(),
      if (city.trim().isNotEmpty) city.trim(),
      if (zone.trim().isNotEmpty) zone.trim(),
      if (postalCode.trim().isNotEmpty) postalCode.trim(),
      if (country.trim().isNotEmpty) country.trim(),
    ];
    return parts.join(', ');
  }
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
