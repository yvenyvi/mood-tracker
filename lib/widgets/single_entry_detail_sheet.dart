import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mood_tracker/theme/mood_assets.dart';
import 'package:mood_tracker/utils/app_date_utils.dart';
import 'package:mood_tracker/widgets/detail_section.dart';
import 'package:mood_tracker/widgets/mood_tag_wrap.dart';

class SingleEntryDetailSheet extends StatelessWidget {
  final Map<String, dynamic> entry;

  const SingleEntryDetailSheet({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final timestamp = AppDateUtils.getDateTime(entry['timestamp']);
    final mood = entry['mood'] ?? 'Neutral';
    final intensity = entry['intensity'] as int? ?? 3;
    final color = MoodAssets.getMoodColor(mood);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              AppDateUtils.formatFullDate(timestamp),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 12.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Time - Centered large
                  Text(
                    AppDateUtils.formatTime(timestamp),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Mood Icon
                  Center(
                    child: Hero(
                      tag: 'mood_icon_${timestamp.millisecondsSinceEpoch}',
                      child: Lottie.network(
                        MoodAssets.getCategoryUrl(mood),
                        width: 140, // Slightly larger
                        height: 140,
                        animate: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mood Name & Intensity
                  Text(
                    mood,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    MoodAssets.moodLabels[intensity] ??
                        (intensity == 0 ? 'Unsure' : 'Unknown'),
                    style: TextStyle(
                      fontSize: 18,
                      color: color.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Details Section
                  // Combine legacy trigger and new triggers for display
                  // If legacy trigger exists and is NOT in triggers list, show it.
                  // Otherwise just show triggers list.
                  Builder(
                    builder: (context) {
                      final legacyTrigger = entry['trigger'] as String? ?? '';
                      final triggersList = List<String>.from(
                        entry['triggers'] as List? ?? [],
                      );

                      // Merge unique
                      final displayTriggers = {...triggersList};
                      if (legacyTrigger.isNotEmpty) {
                        displayTriggers.add(legacyTrigger);
                      }

                      if (displayTriggers.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: DetailSection(
                            icon: Icons.bolt,
                            title: 'Triggers',
                            content: MoodTagWrap(
                              tags: displayTriggers.toList(),
                              baseColor: color,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  if (entry['emotions'] != null &&
                      (entry['emotions'] as List).isNotEmpty) ...[
                    DetailSection(
                      icon: Icons.sentiment_satisfied_alt,
                      title: 'Emotions',
                      content: MoodTagWrap(
                        tags: entry['emotions'] as List,
                        baseColor: color,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (entry['coping_strategies'] != null &&
                      (entry['coping_strategies'] as List).isNotEmpty) ...[
                    DetailSection(
                      icon: Icons.explore,
                      title: 'Safety Menu',
                      content: MoodTagWrap(
                        tags: entry['coping_strategies'] as List,
                        baseColor: color,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (entry['physical_symptoms'] != null &&
                      (entry['physical_symptoms'] as List).isNotEmpty) ...[
                    DetailSection(
                      icon: Icons.healing,
                      title: 'Physical Symptoms',
                      content: MoodTagWrap(
                        tags: entry['physical_symptoms'] as List,
                        baseColor: color,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if ((entry['note'] != null &&
                          (entry['note'] as String).isNotEmpty) ||
                      (entry['rant'] != null &&
                          (entry['rant'] as String).isNotEmpty)) ...[
                    DetailSection(
                      icon: Icons.edit_note,
                      title: 'Notes',
                      content: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          entry['note'] ?? entry['rant'],
                          style: const TextStyle(fontSize: 16, height: 1.6),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
