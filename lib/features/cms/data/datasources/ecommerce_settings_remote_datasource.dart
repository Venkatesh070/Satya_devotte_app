import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/features/cms/data/models/ecommerce_settings_model.dart';

class EcommerceSettingsRemoteDataSource {
  EcommerceSettingsRemoteDataSource(this._apiClient);
  final ApiClient _apiClient;

  Future<EcommerceSettings> getSettings() async {
    final res = await _apiClient.dio.get(ApiEndpoints.ecommerceSettings);
    return EcommerceSettings.fromJson(_unwrapDeliveryCharges(res.data));
  }

  Future<EcommerceSettings> updateSettings(EcommerceSettings settings) async {
    final res = await _apiClient.dio.put(
      ApiEndpoints.ecommerceSettings,
      data: settings.toUpdateJson(),
    );
    return EcommerceSettings.fromJson(_unwrapDeliveryCharges(res.data));
  }

  Map<String, dynamic> _unwrapDeliveryCharges(dynamic raw) {
    if (raw is! Map<String, dynamic>) return const {};

    final data = raw['data'];
    if (data is Map<String, dynamic>) {
      final settings = data['settings'];
      if (settings is Map<String, dynamic>) {
        final charges = settings['delivery_charges'] ?? settings['deliveryCharges'];
        if (charges is Map<String, dynamic>) return charges;
        return settings;
      }
      final charges = data['delivery_charges'] ?? data['deliveryCharges'];
      if (charges is Map<String, dynamic>) return charges;
      return data;
    }

    final settings = raw['settings'];
    if (settings is Map<String, dynamic>) {
      final charges = settings['delivery_charges'] ?? settings['deliveryCharges'];
      if (charges is Map<String, dynamic>) return charges;
      return settings;
    }

    final charges = raw['delivery_charges'] ?? raw['deliveryCharges'];
    if (charges is Map<String, dynamic>) return charges;

    return raw;
  }
}
