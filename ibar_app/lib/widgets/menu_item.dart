import 'package:flutter/material.dart';
import 'package:ibar_app/constants/colors.dart';

class MenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const MenuItem({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 52,
      leading: Icon(icon, size: 22, color: AppColors.primaryColor),
      title: Text(text, style: Theme.of(context).textTheme.titleMedium),
      onTap: onTap,
      hoverColor: AppColors.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
