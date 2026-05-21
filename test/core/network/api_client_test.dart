import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';
import 'package:satya_devotte_app/core/services/api_loading_service.dart';

void main() {
  test('ApiClient initializes Dio', () {
    final loadingService = ApiLoadingService();
    Get.put<ApiLoadingService>(loadingService);
    final client = ApiClient(loadingService: loadingService);
    expect(client.dio.options.connectTimeout, isNotNull);
    Get.reset();
  });
}
