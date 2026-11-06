import 'package:flutter/material.dart';
import 'package:ibar_app/screens/orders_screen.dart';
import 'package:ibar_app/screens/workflow_screen.dart';
import 'package:ibar_app/widgets/full_width_card.dart';

class ApprovalsScreen extends StatelessWidget {
  const ApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aprovações')),
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
                    'Acompanhe as solicitações que precisam de atenção.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  buildFullWidthCard(
                    context,
                    icon: Icons.description_outlined,
                    title: 'Requisições de Compras',
                    description: 'Gerencie e aprove requisições de compras.',
                    onTap: () => _navigateTo(context, const OrdersScreen()),
                  ),
                  const SizedBox(height: 12),
                  buildFullWidthCard(
                    context,
                    icon: Icons.account_tree_outlined,
                    title: 'Workflow',
                    description:
                        'Disponibilidade da integração de workflow ainda pendente.',
                    onTap: () => _navigateTo(context, const WorkflowScreen()),
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

void _navigateTo(BuildContext context, Widget screen) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}
