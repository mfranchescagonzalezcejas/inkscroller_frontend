import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/config/app_environment.dart';
import 'package:inkscroller_flutter/core/error/exceptions.dart';
import 'package:inkscroller_flutter/core/network/dio_client.dart';
import 'package:inkscroller_flutter/features/settings/data/datasources/settings_remote_ds_impl.dart';
import 'package:inkscroller_flutter/flavors/flavor_config.dart';

void main() {
  setUp(FlavorConfig.resetForTesting);

  test('DELETE /users/me sends auth header and succeeds on 204', () async {
    FlavorConfig(
      flavor: Flavor.dev,
      apiBaseUrl: AppEnvironment.devCloudBaseUrl,
      name: 'InkScroller Test',
    );
    final adapter = _DeleteAccountAdapter(statusCode: 204);
    final dioClient = DioClient(tokenProvider: () async => 'token-123')
      ..dio.httpClientAdapter = adapter;
    final dataSource = SettingsRemoteDataSourceImpl(dioClient: dioClient);

    await dataSource.deleteAccount();

    expect(adapter.requests.single.method, 'DELETE');
    expect(adapter.requests.single.path, '/users/me');
    expect(
      adapter.requests.single.headers['Authorization'],
      'Bearer token-123',
    );
  });

  test('maps 401 response into ServerException', () async {
    FlavorConfig(
      flavor: Flavor.dev,
      apiBaseUrl: AppEnvironment.devCloudBaseUrl,
      name: 'InkScroller Test',
    );
    final adapter = _DeleteAccountAdapter(
      statusCode: 401,
      body: const <String, dynamic>{'detail': 'Unauthorized'},
    );
    final dioClient = DioClient(tokenProvider: () async => 'token-123')
      ..dio.httpClientAdapter = adapter;
    final dataSource = SettingsRemoteDataSourceImpl(dioClient: dioClient);

    await expectLater(
      dataSource.deleteAccount(),
      throwsA(
        isA<ServerException>()
            .having((e) => e.code, 'code', 401)
            .having((e) => e.message, 'message', 'Unauthorized'),
      ),
    );
  });

  test('maps 500 response into ServerException', () async {
    FlavorConfig(
      flavor: Flavor.dev,
      apiBaseUrl: AppEnvironment.devCloudBaseUrl,
      name: 'InkScroller Test',
    );
    final adapter = _DeleteAccountAdapter(
      statusCode: 500,
      body: const <String, dynamic>{'detail': 'Internal server error'},
    );
    final dioClient = DioClient(tokenProvider: () async => 'token-123')
      ..dio.httpClientAdapter = adapter;
    final dataSource = SettingsRemoteDataSourceImpl(dioClient: dioClient);

    await expectLater(
      dataSource.deleteAccount(),
      throwsA(
        isA<ServerException>().having(
          (e) => e.message,
          'message',
          'Internal server error',
        ),
      ),
    );
  });

  test('maps connection timeout into NetworkException', () async {
    FlavorConfig(
      flavor: Flavor.dev,
      apiBaseUrl: AppEnvironment.devCloudBaseUrl,
      name: 'InkScroller Test',
    );
    final adapter = _TimeoutAdapter();
    final dioClient = DioClient(tokenProvider: () async => 'token-123')
      ..dio.httpClientAdapter = adapter;
    final dataSource = SettingsRemoteDataSourceImpl(dioClient: dioClient);

    await expectLater(
      dataSource.deleteAccount(),
      throwsA(isA<NetworkException>()),
    );
  });

  test('maps structured backend detail into controlled ServerException', () async {
    FlavorConfig(
      flavor: Flavor.dev,
      apiBaseUrl: AppEnvironment.devCloudBaseUrl,
      name: 'InkScroller Test',
    );
    final adapter = _DeleteAccountAdapter(
      statusCode: 422,
      body: const <String, dynamic>{
        'detail': <Map<String, Object>>[
          <String, Object>{
            'loc': <String>['body', 'field'],
            'msg': 'Invalid value',
            'type': 'value_error',
          },
        ],
      },
    );
    final dioClient = DioClient(tokenProvider: () async => 'token-123')
      ..dio.httpClientAdapter = adapter;
    final dataSource = SettingsRemoteDataSourceImpl(dioClient: dioClient);

    await expectLater(
      dataSource.deleteAccount(),
      throwsA(
        isA<ServerException>().having(
          (e) => e.message,
          'message',
          'Account deletion request failed.',
        ),
      ),
    );
  });
}

class _DeleteAccountAdapter implements HttpClientAdapter {
  final int statusCode;
  final Map<String, dynamic> body;
  final requests = <RequestOptions>[];

  _DeleteAccountAdapter({
    required this.statusCode,
    this.body = const <String, dynamic>{},
  });

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    if (statusCode >= 400) {
      throw DioException(
        requestOptions: options,
        response: Response<Map<String, dynamic>>(
          requestOptions: options,
          statusCode: statusCode,
          data: body,
        ),
      );
    }

    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _TimeoutAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionTimeout,
    );
  }

  @override
  void close({bool force = false}) {}
}
