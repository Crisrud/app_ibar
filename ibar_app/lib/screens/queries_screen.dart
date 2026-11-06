import 'package:flutter/material.dart';
import 'package:ibar_app/widgets/unavailable_feature_notice.dart';

class QueriesScreen extends StatelessWidget {
  const QueriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consultas')),
      body: const UnavailableFeatureNotice(
        title: 'Consultas',
        description:
            'As consultas ainda não estão disponíveis. Esta opção será habilitada '
            'quando a integração estiver concluída.',
      ),
    );
  }
}
