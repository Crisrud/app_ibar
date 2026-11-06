import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

class ProtheusApiClient {
  ProtheusApiClient({required this.config, required http.Client httpClient})
    : _httpClient = httpClient;

  final ApiConfig config;
  final http.Client _httpClient;

  Future<Object?> getJson(Uri uri, {required String token}) async {
    config.validateRequestUri(uri);
    final response = await _httpClient
        .get(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        )
        .timeout(config.requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProtheusApiHttpException(uri, response.statusCode);
    }

    try {
      return jsonDecode(response.body);
    } on FormatException catch (error) {
      throw ProtheusApiFormatException(uri, error);
    }
  }
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
