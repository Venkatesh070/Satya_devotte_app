import 'package:flutter/material.dart';
import 'package:satya_devotte_app/features/rituals/domain/entities/ritual_entity.dart';

class RitualCard extends StatelessWidget {
  const RitualCard({super.key, required this.ritual, this.onTap});

  final RitualEntity ritual;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(ritual.title),
        subtitle: Text(ritual.description),
        trailing: Icon(
          ritual.offlineAvailable ? Icons.download_done : Icons.cloud_download,
        ),
        onTap: onTap,
      ),
    );
  }
}
