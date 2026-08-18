// lib/features/poojakit/data/models/shipping_quote_model.dart

/// One The Courier Guy / ShipLogic service-level rate from `POST /shipping/quote`.
class ShippingRateModel {
  const ShippingRateModel({
    required this.serviceLevelCode,
    required this.serviceLevelName,
    required this.description,
    required this.rate,
    required this.rateExcludingVat,
    this.rateRevisionId,
    this.serviceLevelId,
  });

  final String serviceLevelCode;
  final String serviceLevelName;
  final String description;
  final double rate;
  final double rateExcludingVat;
  final dynamic rateRevisionId;
  final dynamic serviceLevelId;

  factory ShippingRateModel.fromJson(Map<String, dynamic> json) {
    return ShippingRateModel(
      serviceLevelCode: (json['serviceLevelCode'] ?? '').toString(),
      serviceLevelName: (json['serviceLevelName'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      rate: _toDouble(json['rate']) ?? 0,
      rateExcludingVat: _toDouble(json['rateExcludingVat']) ?? 0,
      rateRevisionId: json['rateRevisionId'],
      serviceLevelId: json['serviceLevelId'],
    );
  }
}

/// Quote envelope returned by `POST /shipping/quote` → `{ quote: {...} }`.
class ShippingQuoteModel {
  const ShippingQuoteModel({
    required this.rates,
    required this.currency,
    this.expiresAt,
    this.quotedAt,
  });

  final List<ShippingRateModel> rates;
  final String currency;
  final DateTime? expiresAt;
  final DateTime? quotedAt;

  factory ShippingQuoteModel.fromJson(Map<String, dynamic> json) {
    final rawRates = json['rates'];
    final rates = <ShippingRateModel>[];
    if (rawRates is List) {
      for (final r in rawRates) {
        if (r is Map<String, dynamic>) {
          rates.add(ShippingRateModel.fromJson(r));
        }
      }
    }
    return ShippingQuoteModel(
      rates: rates,
      currency: (json['currency'] ?? 'ZAR').toString(),
      expiresAt: _parseDate(json['expiresAt']),
      quotedAt: _parseDate(json['quotedAt']),
    );
  }

  /// Snapshot stored on an order after checkout (`order.shippingQuote`).
  factory ShippingQuoteModel.fromOrderSnapshot(Map<String, dynamic> json) {
    final code = (json['serviceLevelCode'] ?? '').toString();
    if (code.isEmpty && json['rates'] is List) {
      return ShippingQuoteModel.fromJson(json);
    }
    return ShippingQuoteModel(
      rates: [
        ShippingRateModel(
          serviceLevelCode: code,
          serviceLevelName: (json['serviceLevelName'] ?? '').toString(),
          description: (json['description'] ?? '').toString(),
          rate: _toDouble(json['rate']) ?? 0,
          rateExcludingVat: _toDouble(json['rateExcludingVat']) ?? 0,
          rateRevisionId: json['rateRevisionId'],
          serviceLevelId: json['serviceLevelId'],
        ),
      ],
      currency: (json['currency'] ?? 'ZAR').toString(),
      expiresAt: _parseDate(json['expiresAt']),
      quotedAt: _parseDate(json['quotedAt']),
    );
  }
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  final s = v.toString();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s)?.toLocal();
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
