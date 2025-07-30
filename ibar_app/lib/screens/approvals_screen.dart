import 'package:flutter/material.dart';
import 'package:ibar_app/constants/colors.dart';
import 'package:ibar_app/screens/orders_screen.dart';
import 'package:ibar_app/screens/workflow_screen.dart';
import 'package:ibar_app/widgets/custom_card.dart';

import '../widgets/full_width_card.dart';

class ApprovalsScreen extends StatelessWidget {
  const ApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aprovações'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            buildFullWidthCard(
              context,
              icon: Icons.description,
              title: 'Requisições de Compras',
              description: 'Gerencie e aprove requisições de compras',
              onTap: () => _navigateTo(context, const OrdersScreen()),
            ),
            const SizedBox(height: 16),
            buildFullWidthCard(
              context,
              icon: Icons.work,
              title: 'Workflow',
              description: 'Acompanhe e gerencie os fluxos de trabalho',
              onTap: () => _navigateTo(context, const WorkflowScreen()),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget auxiliar para criar cards com largura total
/*Widget _buildFullWidthCard(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String description,
  required VoidCallback onTap,
}) {
  return Card(
    margin: EdgeInsets.zero,
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 40, color: AppColors.primaryColor),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Text(description, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}*/

// Método auxiliar para navegação
void _navigateTo(BuildContext context, Widget screen) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}