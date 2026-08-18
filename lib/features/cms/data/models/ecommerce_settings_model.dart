class EcommerceSettings {
  const EcommerceSettings({
    this.vatNumber = '',
    this.vatPercent = 0,
    this.currency = 'ZAR',
  });

  final String vatNumber;
  final double vatPercent;
  final String currency;

  factory EcommerceSettings.fromJson(Map<String, dynamic> json) {
    final vat = json['vat'] ?? json['settings']?['vat'] ?? json;
    final map = vat is Map<String, dynamic> ? vat : json;

    final number = (map['vat_number'] ?? map['vatNumber'] ?? '').toString().trim();
    final rawPct = map['vat_percent'] ?? map['vatPercent'] ?? 0;
    final pct = rawPct is num ? rawPct.toDouble() : double.tryParse('$rawPct') ?? 0;
    final currency = (map['currency'] ?? 'ZAR').toString().trim();

    return EcommerceSettings(
      vatNumber: number,
      vatPercent: pct.clamp(0, 100).toDouble(),
      currency: currency.isEmpty ? 'ZAR' : currency.toUpperCase(),
    );
  }

  Map<String, dynamic> toUpdateJson() => {
        'vat': {
          'vat_number': vatNumber.trim(),
          'vat_percent': vatPercent,
          'currency': currency,
        },
      };

  EcommerceSettings copyWith({
    String? vatNumber,
    double? vatPercent,
    String? currency,
  }) {
    return EcommerceSettings(
      vatNumber: vatNumber ?? this.vatNumber,
      vatPercent: vatPercent ?? this.vatPercent,
      currency: currency ?? this.currency,
    );
  }
}
