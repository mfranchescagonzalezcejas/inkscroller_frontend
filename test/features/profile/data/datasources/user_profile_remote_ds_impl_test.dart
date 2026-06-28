import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkscroller_flutter/core/config/app_environment.dart';
import 'package:inkscroller_flutter/core/error/exceptions.dart';
import 'package:inkscroller_flutter/core/network/dio_client.dart';
import 'package:inkscroller_flutter/features/profile/data/datasources/user_profile_remote_ds_impl.dart';
import 'package:inkscroller_flutter/flavors/flavor_config.dart';

void main() {
  setUp(FlavorConfig.resetForTesting);

  test('PATCH /users/me sends username and birth_date JSON body', () async {
    FlavorConfig(
      flavor: Flavor.dev,
      apiBaseUrl: AppEnvironment.devCloudBaseUrl,
      name: 'InkScroller Test',
    );
    final adapter = _ProfilePatchAdapter(statusCode: 200);
    final dioClient = DioClient(tokenProvider: () async => 'token-123')
      ..dio.httpClientAdapter = adapter;
    final dataSource = UserProfileRemoteDataSourceImpl(dioClient: dioClient);

    final model = await dataSource.updateProfile(
      username: 'alice_01',
      birthDate: DateTime(2000, 2, 3),
    );

    expect(adapter.requests.single.method, 'PATCH');
    expect(adapter.requests.single.path, '/users/me');
    expect(
      adapter.requests.single.headers['Authorization'],
      'Bearer token-123',
    );
    expect(adapter.requests.single.data, <String, String>{
      'username': 'alice_01',
      'birth_date': '2000-02-03',
    });
    expect(model.username, 'alice_01');
    expect(model.birthDate, '2000-02-03');
  });

  test('maps backend detail into ServerException message', () async {
    FlavorConfig(
      flavor: Flavor.dev,
      apiBaseUrl: AppEnvironment.devCloudBaseUrl,
      name: 'InkScroller Test',
    );
    final adapter = _ProfilePatchAdapter(
      statusCode: 409,
      body: const <String, dynamic>{'detail': 'Username already in use'},
    );
    final dioClient = DioClient(tokenProvider: () async => 'token-123')
      ..dio.httpClientAdapter = adapter;
    final dataSource = UserProfileRemoteDataSourceImpl(dioClient: dioClient);

    await expectLater(
      dataSource.updateProfile(
        username: 'alice_01',
        birthDate: DateTime(2000, 2, 3),
      ),
      throwsA(
        isA<ServerException>().having(
          (error) => error.message,
          'message',
          'Username already in use',
        ),
      ),
    );
  });

  test(
    'maps structured backend detail into controlled ServerException',
    () async {
      FlavorConfig(
        flavor: Flavor.dev,
        apiBaseUrl: AppEnvironment.devCloudBaseUrl,
        name: 'InkScroller Test',
      );
      final adapter = _ProfilePatchAdapter(
        statusCode: 422,
        body: const <String, dynamic>{
          'detail': <Map<String, Object>>[
            <String, Object>{
              'loc': <String>['body', 'birth_date'],
              'msg': 'Input should be a valid date',
              'type': 'date_from_datetime_parsing',
            },
          ],
        },
      );
      final dioClient = DioClient(tokenProvider: () async => 'token-123')
        ..dio.httpClientAdapter = adapter;
      final dataSource = UserProfileRemoteDataSourceImpl(dioClient: dioClient);

      await expectLater(
        dataSource.updateProfile(
          username: 'alice_01',
          birthDate: DateTime(2000, 2, 3),
        ),
        throwsA(
          isA<ServerException>().having(
            (error) => error.message,
            'message',
            'Profile request validation failed.',
          ),
        ),
      );
    },
  );
}

class _ProfilePatchAdapter implements HttpClientAdapter {
  final int statusCode;
  final Map<String, dynamic> body;
  final requests = <RequestOptions>[];

  _ProfilePatchAdapter({
    required this.statusCode,
    this.body = const <String, dynamic>{
      'firebase_uid': 'uid-123',
      'email': 'alice@example.com',
      'display_name': null,
      'username': 'alice_01',
      'birth_date': '2000-02-03',
      'created_at': '2026-06-28T12:00:00Z',
    },
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
