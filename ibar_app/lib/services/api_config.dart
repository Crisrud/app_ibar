import 'package:flutter/foundation.dart';

const String _serviceBaseUrl = String.fromEnvironment(
  'PROTHEUS_SERVICE_BASE_URL',
  defaultValue: 'http://mail.ibar.com.br:10099',
);
const String _approvalBaseUrl = String.fromEnvironment(
  'PROTHEUS_APPROVAL_BASE_URL',
  defaultValue: 'http://192.168.101.244:10111',
);

class ApiConfig {
  factory ApiConfig.development({
    Uri? serviceBaseUri,
    Uri? approvalBaseUri,
    Duration requestTimeout = const Duration(seconds: 30),
  }) {
    return ApiConfig._(
      serviceBaseUri: serviceBaseUri ?? Uri.parse(_serviceBaseUrl),
      approvalBaseUri: approvalBaseUri ?? Uri.parse(_approvalBaseUrl),
      requestTimeout: requestTimeout,
      isProduction: false,
    );
  }

  factory ApiConfig.production({
    Uri? serviceBaseUri,
    Uri? approvalBaseUri,
    Duration requestTimeout = const Duration(seconds: 30),
  }) {
    return ApiConfig._(
      serviceBaseUri: serviceBaseUri ?? Uri.parse(_serviceBaseUrl),
      approvalBaseUri: approvalBaseUri ?? Uri.parse(_approvalBaseUrl),
      requestTimeout: requestTimeout,
      isProduction: true,
    );
  }

  factory ApiConfig.forBuild({
    bool isRelease = kReleaseMode,
    Uri? serviceBaseUri,
    Uri? approvalBaseUri,
    Duration requestTimeout = const Duration(seconds: 30),
  }) {
    final factory = isRelease ? ApiConfig.production : ApiConfig.development;
    return factory(
      serviceBaseUri: serviceBaseUri,
      approvalBaseUri: approvalBaseUri,
      requestTimeout: requestTimeout,
    );
  }

  ApiConfig._({
    required this.serviceBaseUri,
    required this.approvalBaseUri,
    required this.requestTimeout,
    required this.isProduction,
  }) {
    _validateUri(serviceBaseUri);
    _validateUri(approvalBaseUri);
    if (requestTimeout <= Duration.zero) {
      throw const ProtheusApiConfigurationException(
        'The API request timeout must be greater than zero.',
      );
    }
  }

  final Uri serviceBaseUri;
  final Uri approvalBaseUri;
  final Duration requestTimeout;
  final bool isProduction;

  Uri serviceUri(String path) => serviceBaseUri.resolve(path);

  Uri approvalUri(String path) => approvalBaseUri.resolve(path);

  void validateRequestUri(Uri uri) {
    validateRequestUriForBuild(this, uri, isRelease: kReleaseMode);
  }

  @visibleForTesting
  static void validateRequestUriForBuild(
    ApiConfig config,
    Uri uri, {
    required bool isRelease,
  }) {
    _validateUri(uri);
    if (config.isProduction || isRelease) _requireHttps(uri);
  }

  static void _validateUri(Uri uri) {
    if (!uri.hasAuthority ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw ProtheusApiConfigurationException(
        'Invalid Protheus API URL: $uri. Configure an absolute HTTP or HTTPS URL.',
      );
    }
  }

  static void _requireHttps(Uri uri) {
    if (uri.scheme != 'https') {
      throw ProtheusApiConfigurationException(
        'HTTPS is required for Protheus production because bearer tokens must '
        'not be sent over HTTP. Configure HTTPS endpoints with the Protheus team.',
      );
    }
  }
}

class ProtheusApiConfigurationException implements Exception {
  const ProtheusApiConfigurationException(this.message);

  final String message;

  @override
  String toString() => 'ProtheusApiConfigurationException: $message';
}
