// lib/features/poojakit/data/models/address_model.dart

class AddressModel {
  const AddressModel({
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.line1,
    required this.city,
    required this.state,
    required this.postalCode,
    this.pincode,
    required this.country,
  });

  final String fullName;
  final String phone;
  final String addressLine1;
  final String? line1;
  final String city;
  final String state;
  final String postalCode;
  final String? pincode;
  final String country;

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'phone': phone,
    'addressLine1': addressLine1,
    if (line1 != null) 'line1': line1,
    'city': city,
    'state': state,
    'postalCode': postalCode,
    if (pincode != null) 'pincode': pincode,
    'country': country,
  };

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
    fullName: json['fullName']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    addressLine1: json['addressLine1']?.toString() ?? '',
    line1: json['line1']?.toString(),
    city: json['city']?.toString() ?? '',
    state: json['state']?.toString() ?? '',
    postalCode: json['postalCode']?.toString() ?? '',
    pincode: json['pincode']?.toString(),
    country: json['country']?.toString() ?? '',
  );
}
