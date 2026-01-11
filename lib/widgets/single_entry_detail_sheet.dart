import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:mood_tracker/theme/mood_assets.dart';

class SingleEntryDetailSheet extends StatelessWidget {
  final Map<String, dynamic> entry;

  const SingleEntryDetailSheet({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final timestamp = (entry['timestamp'] as Timestamp).toDate().toLocal();
    final mood = entry['mood'] ?? 'Neutral';
    final intensity = entry['intensity'] as int? ?? 3;
    final color = MoodAssets.getMoodColor(mood);

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Date and Time
          Text(
            DateFormat('EEEE, MMMM d, yyyy').format(timestamp),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            DateFormat('h:mm a').format(timestamp),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Mood Icon
          Center(
            child: Lottie.network(
              MoodAssets.getCategoryUrl(mood),
              width: 120,
              height: 120,
              animate: true,
            ),
          ),
          const SizedBox(height: 16),

          // Mood Name & Intensity
          Text(
            mood,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            MoodAssets.moodLabels[intensity] ??
                (intensity == 0 ? 'Unsure' : 'Unknown'),
            style: TextStyle(
              fontSize: 16,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Details Section
          if (entry['trigger'] != null &&
              (entry['trigger'] as String).isNotEmpty) ...[
            _buildDetailSection(
              context,
              icon: Icons.bolt,
              title: 'Trigger',
              content: Text(
                entry['trigger'],
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (entry['emotions'] != null &&
              (entry['emotions'] as List).isNotEmpty) ...[
            _buildDetailSection(
              context,
              icon: Icons.sentiment_satisfied_alt,
              title: 'Emotions',
              content: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (entry['emotions'] as List).map<Widget>((e) {
                  return Chip(
                    label: Text(e.toString()),
                    backgroundColor: color.withOpacity(0.1),
                    side: BorderSide(color: color.withOpacity(0.3)),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if ((entry['note'] != null && (entry['note'] as String).isNotEmpty) ||
              (entry['rant'] != null &&
                  (entry['rant'] as String).isNotEmpty)) ...[
            _buildDetailSection(
              context,
              icon: Icons.edit_note,
              title: 'Notes',
              content: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  entry['note'] ?? entry['rant'],
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDetailSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }
}
