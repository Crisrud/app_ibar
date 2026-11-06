import 'package:ibar_app/services/api_config.dart';
import 'package:ibar_app/services/protheus_api_client.dart';

class ProtheusOperationsApi {
  const ProtheusOperationsApi({required this.config, required this.client});

  final ApiConfig config;
  final ProtheusApiClient client;

  Future<List<dynamic>> getOpenRequisitions({required String token}) async {
    final uri = config.serviceUri('/api/ibar/wsrequisicoes?ctipo=abertas');
    final response = await client.getJson(uri, token: token);
    if (response is! Map<String, dynamic> || response['items'] is! List) {
      throw ProtheusApiFormatException(
        uri,
        const FormatException('Expected an object containing an items list.'),
      );
    }
    return response['items'] as List<dynamic>;
  }

  Future<void> approveItem({
    required Object? itemId,
    required String token,
  }) async {
    await _post(
      config.approvalUri('/rest/api/ibar/wsaprovarrequisicao'),
      token: token,
      body: {'id': itemId, 'acao': 'aprovar'},
    );
  }

  Future<void> rejectRequisition({
    required Object? requisitionId,
    required String justification,
    required String token,
  }) async {
    await _post(
      config.approvalUri('/rest/api/ibar/wsrejeitarrequisicao'),
      token: token,
      body: {
        'id': requisitionId,
        'acao': 'rejeitar',
        'justificativa': justification,
      },
    );
  }

  Future<void> releaseTurnstile({
    required String token,
    required String matricula,
    required String tipo,
    String? horaInicial,
    String? horaFinal,
  }) async {
    final queryParameters = <String, String>{'cmat': matricula, 'ctipo': tipo};
    if (horaInicial != null && horaFinal != null) {
      queryParameters['hinicial'] = horaInicial;
      queryParameters['hfinal'] = horaFinal;
    }
    await _post(
      config.serviceUri('/catraca').replace(queryParameters: queryParameters),
      token: token,
      body: null,
    );
  }

  Future<void> _post(
    Uri uri, {
    required String token,
    required Object? body,
  }) async {
    final response = await client.postJson(uri, token: token, body: body);
    if (response.statusCode != 200) {
      throw ProtheusApiHttpException(uri, response.statusCode);
    }
  }
}
