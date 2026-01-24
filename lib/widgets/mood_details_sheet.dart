import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mood_tracker/theme/mood_assets.dart';
import 'package:mood_tracker/utils/app_date_utils.dart';
import 'package:mood_tracker/widgets/single_entry_detail_sheet.dart';

class MoodDetailsSheet extends StatelessWidget {
  final List<Map<String, dynamic>> entries;

  const MoodDetailsSheet({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    // Safety check for empty entries
    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Text("No entries found."),
      );
    }

    final firstTimestamp = AppDateUtils.getDateTime(entries.first['timestamp']);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppDateUtils.formatFullDate(firstTimestamp),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${entries.length} ${entries.length == 1 ? 'Entry' : 'Entries'}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: entries.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final moodData = entries[index];
                final timestamp = AppDateUtils.getDateTime(
                  moodData['timestamp'],
                );
                final mood = moodData['mood'] ?? 'Neutral';
                final color = MoodAssets.getMoodColor(mood);

                // Determine summary text (Trigger > Note > Intensity)
                String summary =
                    MoodAssets.moodLabels[moodData['intensity'] as int? ?? 3] ??
                    '';
                if (moodData['trigger'] != null &&
                    (moodData['trigger'] as String).isNotEmpty) {
                  summary = 'Trigger: ${moodData['trigger']}';
                } else if (moodData['note'] != null &&
                    (moodData['note'] as String).isNotEmpty) {
                  summary = moodData['note'];
                }

                return Card(
                  elevation: 0,
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: color.withValues(alpha: 0.3)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (context) =>
                            SingleEntryDetailSheet(entry: moodData),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Lottie.network(
                            MoodAssets.getCategoryUrl(mood),
                            width: 36,
                            height: 36,
                            animate: false,
                            errorBuilder: (context, error, stackTrace) {
                              return Text(
                                MoodAssets.getFallbackEmoji(mood),
                                style: const TextStyle(fontSize: 24),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      AppDateUtils.formatTime(timestamp),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        mood,
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  summary,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
