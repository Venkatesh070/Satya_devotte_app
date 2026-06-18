class EcommerceSettings {
  const EcommerceSettings({
    required this.deliveryFee,
    this.currency = 'ZAR',
    this.isEnabled = true,
    this.freeDeliveryMinimum,
  });

  final double deliveryFee;
  final String currency;
  final bool isEnabled;
  final double? freeDeliveryMinimum;

  factory EcommerceSettings.fromJson(Map<String, dynamic> json) {
    final charges = json['delivery_charges'] ?? json['deliveryCharges'];
    final map = charges is Map<String, dynamic> ? charges : json;

    final raw = map['delivery_charge'] ??
        map['deliveryCharge'] ??
        map['deliveryFee'] ??
        map['deliveryCharges'] ??
        map['shippingFee'] ??
        0;
    final fee = raw is num ? raw.toDouble() : double.tryParse('$raw') ?? 0;

    final currency = (map['currency'] ?? 'ZAR').toString().trim();

    final enabledRaw = map['is_enabled'] ?? map['isEnabled'];
    final isEnabled = enabledRaw is bool
        ? enabledRaw
        : enabledRaw == null
            ? true
            : '$enabledRaw'.toLowerCase() != 'false';

    final freeMinRaw = map['free_delivery_minimum'] ?? map['freeDeliveryMinimum'];
    double? freeDeliveryMinimum;
    if (freeMinRaw != null && '$freeMinRaw'.trim().isNotEmpty) {
      freeDeliveryMinimum = freeMinRaw is num
          ? freeMinRaw.toDouble()
          : double.tryParse('$freeMinRaw');
    }

    return EcommerceSettings(
      deliveryFee: fee < 0 ? 0 : fee,
      currency: currency.isEmpty ? 'ZAR' : currency.toUpperCase(),
      isEnabled: isEnabled,
      freeDeliveryMinimum: freeDeliveryMinimum != null && freeDeliveryMinimum < 0
          ? null
          : freeDeliveryMinimum,
    );
  }

  Map<String, dynamic> toUpdateJson() => {
        'delivery_charges': {
          'delivery_charge': deliveryFee,
          'currency': currency,
          'is_enabled': isEnabled,
          if (freeDeliveryMinimum != null)
            'free_delivery_minimum': freeDeliveryMinimum,
        },
      };

  EcommerceSettings copyWith({
    double? deliveryFee,
    String? currency,
    bool? isEnabled,
    double? freeDeliveryMinimum,
    bool clearFreeDeliveryMinimum = false,
  }) {
    return EcommerceSettings(
      deliveryFee: deliveryFee ?? this.deliveryFee,
      currency: currency ?? this.currency,
      isEnabled: isEnabled ?? this.isEnabled,
      freeDeliveryMinimum: clearFreeDeliveryMinimum
          ? null
          : (freeDeliveryMinimum ?? this.freeDeliveryMinimum),
    );
  }
}
