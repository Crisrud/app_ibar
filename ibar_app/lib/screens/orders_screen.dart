import 'package:flutter/material.dart';
import 'package:ibar_app/widgets/full_width_card.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:provider/provider.dart';

import '../services/protheus_auth.dart';
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
      // Mostrar diálogo de confirmação
      final confirmado = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar Aprovação'),
          content: Text('Deseja aprovar a requisição #${requisicao['num']}?'),
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

      if (confirmado == true) {
        // Chamar API para aprovar
        setState(() => isLoading = true);
        // Chamar API para aprovar todos os itens
        final items = requisicao['itemsrc'] as List? ?? [];
        var nCount = 0;
        for (var item in items) {
          final response = await http.post(
            Uri.parse(
                'http://192.168.101.244:10111/rest/api/ibar/wsaprovarrequisicao'),
            body: json.encode({
              'id': item['id'], // Agora usando o ID do item específico
              'acao': 'aprovar',
            }),
            headers: {'Content-Type': 'application/json'},
          );


          if (response.statusCode == 200) {
            nCount++;
          } else {
            throw Exception('Erro na API: ${response.statusCode}');
          }
        }// final do for

        // Verifica se todos os itens foram aprovados
        if (nCount > 0 && mounted && nCount == items.length) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Requisição #${requisicao['num']} aprovada!')),
          );
          _fetchRequisicoes(); // Recarregar a lista
        } else {
          throw Exception('Nenhum item aprovado');
        }

      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao aprovar: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _rejeitarRequisicao(Map<String, dynamic> requisicao) async {
    try {
      // Mostrar diálogo com campo de justificativa
      final justificativa = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text('Rejeitar Requisição'),
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

      if (justificativa != null && justificativa.isNotEmpty) {
        // Chamar API para rejeitar
        setState(() => isLoading = true);

        final response = await http.post(
          Uri.parse('http://192.168.101.244:10111/rest/api/ibar/wsrejeitarrequisicao'),
          body: json.encode({
            'id': requisicao['id'],
            'acao': 'rejeitar',
            'justificativa': justificativa,
          }),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Requisição #${requisicao['num']} rejeitada!')),
          );
          _fetchRequisicoes(); // Recarregar a lista
        } else {
          throw Exception('Erro na API: ${response.statusCode}');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao rejeitar: $e')),
      );
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
    try {

      final protheusAuth = Provider.of<ProtheusAuth>(context, listen: false);
      final token = protheusAuth.token;

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sessão expirada. Faça login novamente.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
        return;
      }


      final response = await http.get(
        Uri.parse('http://187.50.41.226:10099/api/ibar/wsrequisicoes?ctipo=abertas'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      if (response.statusCode == 200) {
        // Método 1: Tentativa padrão com UTF-8
        String decodedBody = utf8.decode(response.bodyBytes, allowMalformed: true);

        final data = json.decode(decodedBody);

        setState(() {
          requisicoes = data['items'] ?? []; // Acessa o array 'items' da resposta
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Erro ao carregar requisições: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erro de conexão: $e';
        isLoading = false;
      });
    }
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