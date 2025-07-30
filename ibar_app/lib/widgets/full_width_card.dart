import 'package:flutter/material.dart';
import 'package:ibar_app/constants/colors.dart';

Widget buildFullWidthCard(
  BuildContext context, {
  IconData ?icon,
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
            Padding(
              padding: const EdgeInsets.only(right:20), // Ajuste este valor conforme necessário
              child: Icon(
                icon,
                size: 34,
                color: AppColors.primaryColor,
              ),
            ),
            //Icon(icon, size: 40, color: AppColors.primaryColor),
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
}

// Método auxiliar para navegação
void navigateTo(BuildContext context, Widget screen) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}