import 'package:flutter/material.dart';
import 'package:ibar_app/widgets/full_width_card.dart';

import 'package:provider/provider.dart';

import '../services/protheus_auth.dart';
import '../services/protheus_api_client.dart';
import '../services/protheus_operations_api.dart';
import 'login_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<dynamic> requisicoes = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchRequisicoes();
  }

  void _showActionMenu(BuildContext context, Map<String, dynamic> requisicao) {
    final totalItens = (requisicao['itemsrc'] as List?)?.length ?? 0;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.check, color: Colors.green),
                title: Text('Aprovar Requisição ${requisicao['num']}'),
                subtitle: Text('$totalItens itens'),
                onTap: () {
                  Navigator.pop(context);
                  _aprovarRequisicao(requisicao);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.red),
                title: Text('Rejeitar Requisição ${requisicao['num']}'),
                subtitle: Text('$totalItens itens'),
                onTap: () {
                  Navigator.pop(context);
                  _rejeitarRequisicao(requisicao);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancelar'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _aprovarRequisicao(Map<String, dynamic> requisicao) async {
    try {
      final confirmado = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar Aprova\u00e7\u00e3o'),
          content: Text('Deseja aprovar a requisi\u00e7\u00e3o #${requisicao['num']}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Aprovar', style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      );
      if (!mounted) return;

      if (confirmado == true) {
        final token = _sessionTokenOrLogin();
        if (token == null) return;
        final api = context.read<ProtheusOperationsApi>();
        setState(() => isLoading = true);
        final items = requisicao['itemsrc'] as List? ?? [];
        var nCount = 0;
        for (final item in items) {
          await api.approveItem(itemId: item['id'], token: token);
          nCount++;
        }

        if (nCount > 0 && mounted && nCount == items.length) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Requisi\u00e7\u00e3o #${requisicao['num']} aprovada!')),
          );
          _fetchRequisicoes();
        } else {
          throw Exception('Nenhum item aprovado');
        }
      }
    } catch (error) {
      await _showOperationError('aprovar', error);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _rejeitarRequisicao(Map<String, dynamic> requisicao) async {
    try {
      final justificativa = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text('Rejeitar Requisi\u00e7\u00e3o'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Digite a justificativa para rejeitar #${requisicao['num']}:'),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Justificativa...',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Rejeitar', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      );
      if (!mounted) return;

      if (justificativa != null && justificativa.isNotEmpty) {
        final token = _sessionTokenOrLogin();
        if (token == null) return;
        setState(() => isLoading = true);
        await context.read<ProtheusOperationsApi>().rejectRequisition(
          requisitionId: requisicao['id'],
          justification: justificativa,
          token: token,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Requisi\u00e7\u00e3o #${requisicao['num']} rejeitada!')),
        );
        _fetchRequisicoes();
      }
    } catch (error) {
      await _showOperationError('rejeitar', error);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _buildDescription(List<dynamic> items) {
    final buffer = StringBuffer();

    // Mostra o primeiro item completo
    if (items.isNotEmpty) {
      final primeiroItem = items.first;
      final descricao = primeiroItem['descricao']?.toString().trim() ?? 'Sem descrição';
      final aplicacao = primeiroItem['aplicacao']?.toString().trim() ?? 'Sem aplicação';

      buffer.writeln('Total de Itens: ${items.length}');
      buffer.writeln('item: ${primeiroItem['item']}');
      buffer.writeln('Produto: ${primeiroItem['produto']?.toString().trim() ?? 'N/A'}');
      buffer.writeln('Qtd: ${primeiroItem['qtde']}');
      buffer.writeln('Descrição: ${descricao.length > 30 ? '${descricao.substring(0, 30)}...' : descricao}');
      buffer.writeln('Aplicação: ${aplicacao.length > 30 ? '${aplicacao.substring(0, 30)}...' : aplicacao}');

      // Se houver mais itens, mostra indicador
      if (items.length > 1) {
        buffer.writeln('\n+ ${items.length - 1} itens adicionais...');
      }
    } else {
      buffer.writeln('Nenhum item encontrado nesta requisição');
    }

    return buffer.toString();
  }


  Future<void> _fetchRequisicoes() async {
    final token = _sessionTokenOrLogin();
    if (token == null) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    try {
      final result = await context
          .read<ProtheusOperationsApi>()
          .getOpenRequisitions(token: token);
      if (!mounted) return;
      setState(() {
        requisicoes = result;
        isLoading = false;
      });
    } catch (error) {
      if (error is ProtheusApiHttpException && error.statusCode == 401) {
        await _expireSession();
      }
      if (!mounted) return;
      setState(() {
        errorMessage = error is ProtheusApiNetworkException
            ? 'Erro de conex\u00e3o: $error'
            : 'Erro ao carregar requisi\u00e7\u00f5es: $error';
        isLoading = false;
      });
    }
  }

  String? _sessionTokenOrLogin() {
    final token = context.read<ProtheusAuth>().token;
    if (token != null && token.isNotEmpty) return token;
    if (!mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sess\u00e3o expirada. Fa\u00e7a login novamente.'),
        backgroundColor: Colors.red,
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
    return null;
  }

  Future<void> _showOperationError(String operation, Object error) async {
    if (!mounted) return;
    if (error is ProtheusApiHttpException && error.statusCode == 401) {
      await _expireSession();
      return;
    }
    final message = error is ProtheusApiNetworkException
        ? 'Erro de conex\u00e3o: $error'
        : 'Erro ao $operation: $error';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _expireSession() async {
    if (!mounted) return;
    try {
      await context.read<ProtheusAuth>().logout();
    } catch (_) {
      // Continue to login even if persisted-session cleanup fails.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sess\u00e3o expirada. Fa\u00e7a login novamente.'),
        backgroundColor: Colors.red,
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Requisições de Compras'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lista de requisições pendentes de aprovação:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage.isNotEmpty)
              Center(child: Text(errorMessage))
            else if (requisicoes.isEmpty)
                const Center(child: Text('Nenhuma requisição pendente'))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: requisicoes.length,
                    itemBuilder: (context, index) {
                      final requisicao = requisicoes[index];
                      final items = requisicao['itemsrc'] ?? [];

                      //return Column(
                      return GestureDetector(
                          onLongPress: () => _showActionMenu(context, requisicao),
                          child: Column(
                            children: [
                            const SizedBox(height: 16),
                              buildFullWidthCard(
                              context,
                              icon: (Icons.pending_actions),
                              title: 'Requisição #${requisicao['num'] ?? 'N/A'}',
                              description: _buildDescription(items),
                              onTap: () => _showDetailsDialog(context, requisicao),
                            ),
                        ])
                      );
                    },
                  ),
                ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchRequisicoes,
        tooltip: 'Recarregar',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> requisicao) {
    final items = requisicao['itemsrc'] as List? ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalhes da Requisição #${requisicao['num']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Itens da Requisição:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              if (items.isEmpty)
                const Text('Nenhum item encontrado')
              else
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6, // Altura máxima
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) => _buildItemWidget(items[index]),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemWidget(Map<String, dynamic> item) {
    final descricao = item['descricao']?.toString().trim() ?? 'Sem descrição';
    final aplicacao = item['aplicacao']?.toString().trim() ?? 'Sem aplicação';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Item: ${item['item']}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Produto: ${item['produto']?.toString().trim() ?? 'N/A'}'),
          const SizedBox(height: 4),
          Text('Quantidade: ${item['qtde']}'),
          const SizedBox(height: 4),
          Text('Descrição: $descricao'),
          const SizedBox(height: 4),
          Text('Aplicação: $aplicacao'),
          const SizedBox(height: 4),
          Text('ID: ${item['id']}', style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }


}