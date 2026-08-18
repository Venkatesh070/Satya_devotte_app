import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/network/api_endpoints.dart';
import 'package:satya_devotte_app/features/cms/data/models/ecommerce_settings_model.dart';

class EcommerceSettingsRemoteDataSource {
  EcommerceSettingsRemoteDataSource(this._apiClient);
  final ApiClient _apiClient;

  Future<EcommerceSettings> getSettings() async {
    final res = await _apiClient.dio.get(ApiEndpoints.ecommerceSettings);
    return EcommerceSettings.fromJson(_unwrap(res.data));
  }

  Future<EcommerceSettings> updateSettings(EcommerceSettings settings) async {
    final res = await _apiClient.dio.put(
      ApiEndpoints.ecommerceSettings,
      data: settings.toUpdateJson(),
    );
    return EcommerceSettings.fromJson(_unwrap(res.data));
  }

  Map<String, dynamic> _unwrap(dynamic raw) {
    if (raw is! Map) return const {};
    final map = Map<String, dynamic>.from(raw);
    final data = map['data'];
    if (data is Map) {
      final dataMap = Map<String, dynamic>.from(data);
      final settings = dataMap['settings'];
      if (settings is Map) return Map<String, dynamic>.from(settings);
      return dataMap;
    }
    final settings = map['settings'];
    if (settings is Map) return Map<String, dynamic>.from(settings);
    return map;
  }
}
