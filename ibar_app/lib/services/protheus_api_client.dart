import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class ProtheusApiClient {
  ProtheusApiClient({required this.config, required http.Client httpClient})
    : _httpClient = httpClient;

  final ApiConfig config;
  final http.Client _httpClient;

  Future<Object?> getJson(Uri uri, {required String token}) async {
    config.validateRequestUri(uri);
    final response = await _send(
      () => _httpClient.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ),
    );

    if (response.statusCode != 200) {
      throw ProtheusApiHttpException(uri, response.statusCode);
    }

    try {
      return jsonDecode(response.body);
    } on FormatException catch (error) {
      throw ProtheusApiFormatException(uri, error);
    }
  }

  Future<http.Response> postJson(
    Uri uri, {
    required String token,
    Object? body,
  }) async {
    config.validateRequestUri(uri);
    final response = await _send(
      () => _httpClient.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: body == null ? null : jsonEncode(body),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProtheusApiHttpException(uri, response.statusCode);
    }
    return response;
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(config.requestTimeout);
    } on http.ClientException catch (error) {
      throw ProtheusApiNetworkException(error);
    } on SocketException catch (error) {
      throw ProtheusApiNetworkException(error);
    } on TimeoutException catch (error) {
      throw ProtheusApiNetworkException(error);
    }
  }

  void close() => _httpClient.close();
}

class ProtheusApiHttpException implements Exception {
  const ProtheusApiHttpException(this.uri, this.statusCode);

  final Uri uri;
  final int statusCode;

  @override
  String toString() => 'ProtheusApiHttpException: HTTP $statusCode for $uri';
}

class ProtheusApiFormatException implements Exception {
  const ProtheusApiFormatException(this.uri, this.cause);

  final Uri uri;
  final FormatException cause;

  @override
  String toString() =>
      'ProtheusApiFormatException: invalid JSON from $uri ($cause)';
}

class ProtheusApiNetworkException implements Exception {
  const ProtheusApiNetworkException(this.cause);

  final Object cause;

  @override
  String toString() => 'ProtheusApiNetworkException: $cause';
}
