import 'package:flutter/material.dart';

class StepTimeline extends StatelessWidget {
  const StepTimeline({super.key, required this.steps});
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: steps
          .asMap()
          .entries
          .map(
            (entry) => ListTile(
              leading: CircleAvatar(child: Text('${entry.key + 1}')),
              title: Text(entry.value),
            ),
          )
          .toList(),
    );
  }
}
