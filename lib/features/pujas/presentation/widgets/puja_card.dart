import 'package:flutter/material.dart';
import 'package:satya_devotte_app/features/pujas/domain/entities/puja_entity.dart';
import 'package:satya_devotte_app/shared/widgets/rich_text_display.dart';

class RitualCard extends StatelessWidget {
  const RitualCard({super.key, required this.ritual, this.onTap});

  final RitualEntity ritual;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(ritual.title),
        subtitle: RichTextDisplay(ritual.description),
        trailing: Icon(
          ritual.offlineAvailable ? Icons.download_done : Icons.cloud_download,
        ),
        onTap: onTap,
      ),
    );
  }
}
