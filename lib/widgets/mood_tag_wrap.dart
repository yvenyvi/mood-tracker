import 'package:flutter/material.dart';

class MoodTagWrap extends StatelessWidget {
  final List<dynamic> tags;
  final Color baseColor;
  final double spacing;
  final double runSpacing;

  const MoodTagWrap({
    super.key,
    required this.tags,
    required this.baseColor,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: tags.map<Widget>((tag) {
        return Chip(
          label: Text(tag.toString()),
          backgroundColor: baseColor.withValues(alpha: 0.1),
          side: BorderSide(color: baseColor.withValues(alpha: 0.3)),
        );
      }).toList(),
    );
  }
}
