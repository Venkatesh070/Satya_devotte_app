import 'package:flutter_test/flutter_test.dart';
import 'package:satya_devotte_app/core/network/api_client.dart';

void main() {
  test('ApiClient initializes Dio', () {
    final client = ApiClient();
    expect(client.dio.options.connectTimeout, isNotNull);
  });
}
