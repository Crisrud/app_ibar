import 'package:flutter/material.dart';
import 'package:ibar_app/widgets/custom_card.dart';

class WorkflowScreen extends StatelessWidget {
  const WorkflowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workflow'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fluxos de trabalho ativos:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            CustomCard(
              title: 'Processo #ABC123',
              description: 'Status: Em andamento\nResponsável: Carlos Oliveira',
              onTap: () {},
            ),
            CustomCard(
              title: 'Processo #DEF456',
              description: 'Status: Aguardando aprovação\nResponsável: Ana Souza',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}