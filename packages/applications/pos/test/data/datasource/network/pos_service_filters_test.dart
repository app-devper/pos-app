// Package imports:
import 'package:common/config/network_config.dart';
import 'package:common/core/network/custom_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Project imports:
import 'package:pos/data/datasource/network/pos_service.dart';

class _FakeNetworkConfig implements NetworkConfig {
  @override
  String getHostApp() => 'https://api.example.test';

  @override
  String getHostUm() => 'https://um.example.test';

  @override
  Map<String, String> getHeaders(Uri uri) => const {};

  @override
  bool isDebug() => false;
}

void main() {
  late List<Uri> asked;
  late PosService service;

  setUp(() {
    asked = [];
    service = PosService(
      networkConfig: _FakeNetworkConfig(),
      client: CustomClient(
        inner: MockClient((request) async {
          asked.add(request.url);
          return http.Response('[]', 200);
        }),
      ),
    );
  });

  test('the customer list asks pos-api to leave archived customers out',
      () async {
    // Act
    await service.getCustomers();

    // Assert
    expect(asked.single.path, '/api/pos/v1/customers');
    expect(asked.single.queryParameters, {'excludeArchived': 'true'});
  });

  test('the receipt list asks pos-api to leave cancelled receipts out',
      () async {
    // Act
    await service.getReceives(
        '2026-01-01T00:00:00.000Z', '2026-12-31T00:00:00.000Z');

    // Assert
    expect(asked.single.path, '/api/pos/v1/receives');
    expect(asked.single.queryParameters, {
      'startDate': '2026-01-01T00:00:00.000Z',
      'endDate': '2026-12-31T00:00:00.000Z',
      'excludeCancelled': 'true',
    });
  });
}
