import 'package:flutter/material.dart';
import 'package:ibar_app/widgets/unavailable_feature_notice.dart';

class WorkflowScreen extends StatelessWidget {
  const WorkflowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workflow')),
      body: const UnavailableFeatureNotice(
        title: 'Workflow',
        description:
            'Os fluxos de trabalho ainda não estão disponíveis. Nenhum processo '
            'será exibido até que a integração esteja concluída.',
      ),
    );
  }
}
