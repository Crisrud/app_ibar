import 'package:flutter/material.dart';
import 'package:ibar_app/constants/colors.dart';
import 'package:ibar_app/screens/approvals_screen.dart';
import 'package:ibar_app/screens/catraca.dart';
import 'package:ibar_app/screens/login_screen.dart';
import 'package:ibar_app/screens/queries_screen.dart';
import 'package:ibar_app/screens/workflow_screen.dart';
import 'package:ibar_app/services/protheus_auth.dart';
import 'package:ibar_app/widgets/full_width_card.dart';
import 'package:ibar_app/widgets/menu_item.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _openScreenFromDrawer(BuildContext context, Widget screen) {
    Navigator.pop(context);
    _openScreen(context, screen);
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Sair'),
            content: const Text('Deseja realmente sair?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Sair'),
              ),
            ],
          ),
    );
    if (shouldLogout != true || !context.mounted) return;

    try {
      await context.read<ProtheusAuth>().logout();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao encerrar sessão: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IBAR'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                color: AppColors.primaryDarkColor,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.apartment, color: Colors.white, size: 32),
                    SizedBox(height: 12),
                    Text(
                      'IBAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text('Navegação', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    MenuItem(
                      icon: Icons.check_circle_outline,
                      text: 'Aprovações',
                      onTap:
                          () => _openScreenFromDrawer(
                            context,
                            const ApprovalsScreen(),
                          ),
                    ),
                    MenuItem(
                      icon: Icons.search,
                      text: 'Consultas',
                      onTap:
                          () => _openScreenFromDrawer(
                            context,
                            const QueriesScreen(),
                          ),
                    ),
                    MenuItem(
                      icon: Icons.account_tree_outlined,
                      text: 'Workflow',
                      onTap:
                          () => _openScreenFromDrawer(
                            context,
                            const WorkflowScreen(),
                          ),
                    ),
                    MenuItem(
                      icon: Icons.settings_outlined,
                      text: 'Catraca',
                      onTap:
                          () => _openScreenFromDrawer(context, const Catraca()),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              MenuItem(
                icon: Icons.logout,
                text: 'Sair',
                onTap: () {
                  Navigator.pop(context);
                  _logout(context);
                },
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bem-vindo!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selecione uma opção para continuar.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  buildFullWidthCard(
                    context,
                    icon: Icons.check_circle_outline,
                    title: 'Aprovações',
                    description: 'Acesse requisições e itens pendentes.',
                    onTap: () => _openScreen(context, const ApprovalsScreen()),
                  ),
                  const SizedBox(height: 12),
                  buildFullWidthCard(
                    context,
                    icon: Icons.search,
                    title: 'Consultas',
                    description:
                        'Consulte informações quando a integração estiver disponível.',
                    onTap: () => _openScreen(context, const QueriesScreen()),
                  ),
                  const SizedBox(height: 12),
                  buildFullWidthCard(
                    context,
                    icon: Icons.account_tree_outlined,
                    title: 'Workflow',
                    description:
                        'Acompanhe fluxos quando a integração estiver disponível.',
                    onTap: () => _openScreen(context, const WorkflowScreen()),
                  ),
                  const SizedBox(height: 12),
                  buildFullWidthCard(
                    context,
                    icon: Icons.settings_outlined,
                    title: 'Catraca',
                    description: 'Solicite a liberação de acesso.',
                    onTap: () => _openScreen(context, const Catraca()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
