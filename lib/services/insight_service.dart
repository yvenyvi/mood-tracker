import 'package:mood_tracker/utils/app_date_utils.dart';

class InsightService {
  /// Generates a list of insights based on the provided logs.
  ///
  /// Returns a list of Map objects detailing the insight:
  /// {
  ///   'type': 'pattern' | 'streak' | 'trigger_warning',
  ///   'title': String,
  ///   'description': String,
  ///   'trigger': String?, // Related trigger if applicable
  ///   'coping_tip': String?,
  ///   'related_entries': `List<Map<String, dynamic>>`, // For "Tell me more"
  /// }
  static List<Map<String, dynamic>> generateInsights(
    List<Map<String, dynamic>> entries,
  ) {
    if (entries.isEmpty) return [];

    final insights = <Map<String, dynamic>>[];

    // 1. Weekly Pattern (e.g., Monday Blues)
    final mondayEntries = entries.where((e) {
      final dt = AppDateUtils.getDateTime(e['timestamp']);
      // 1 = Monday
      return dt.weekday == 1;
    }).toList();

    if (mondayEntries.length >= 3) {
      // Check average intensity
      double sum = 0;
      int lowCount = 0;
      for (var e in mondayEntries) {
        final intensity = (e['intensity'] as num?)?.toDouble() ?? 3.0;
        sum += intensity;
        if (intensity <= 2) lowCount++;
      }
      final avg = sum / mondayEntries.length;

      if (avg <= 2.5 || lowCount >= (mondayEntries.length / 2)) {
        insights.add({
          'type': 'pattern',
          'title': 'Monday Morning Blues?',
          'description':
              "You've logged lower energy on $lowCount out of the last ${mondayEntries.length} Mondays.",
          'trigger': null, // Could infer from common triggers on Mondays
          'coping_tip':
              'Would you like to add "5-minute stretching" to your Monday Safety Menu?',
          'related_entries': mondayEntries,
        });
      }
    }

    // 2. Trigger Trouble (Trigger correlation with low mood)
    final triggerStats = <String, List<Map<String, dynamic>>>{};
    for (var e in entries) {
      final intensity = (e['intensity'] as num?)?.toDouble() ?? 3.0;
      if (intensity <= 2) {
        final triggers = _getTriggers(e);
        for (var t in triggers) {
          if (!triggerStats.containsKey(t)) triggerStats[t] = [];
          triggerStats[t]!.add(e);
        }
      }
    }

    // Find significant negative triggers (appeared in at least 3 low mood logs)
    // Sort by count
    final sortedTriggers = triggerStats.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    if (sortedTriggers.isNotEmpty) {
      final topTrigger = sortedTriggers.first;
      if (topTrigger.value.length >= 2) {
        // Threshold
        insights.add({
          'type': 'trigger_warning',
          'title': 'Repeating Pattern: ${topTrigger.key}',
          'description':
              "This trigger appeared in ${topTrigger.value.length} of your recent low-mood entries.",
          'trigger': topTrigger.key,
          'coping_tip':
              'Consider planning a specific self-care activity after "${topTrigger.key}".',
          'related_entries': topTrigger.value,
        });
      }
    }

    // 3. Winning Streak / Positive Vibe (High intensity correlation)
    // Similar to above but for high intensity
    // Implementation can be expanded.

    // 4. Default: Daily Wisdom (if no specific patterns found yet)
    if (insights.isEmpty && entries.isNotEmpty) {
      // Import strictly needed here or at top? using dynamic for now or standard import
      // Since this is a static method, we can't easily access context for localization but we can use the util.
      // We'll return a generic "wisdom" card.
      final randomMessage = _getRandomWisdom(entries.length);
      insights.add({
        'type': 'wisdom',
        'title': 'Daily Wisdom',
        'description': randomMessage,
        'trigger': null,
        'coping_tip': null,
        'related_entries': [],
      });
    }

    return insights;
  }

  static String _getRandomWisdom(int seed) {
    const messages = [
      "Small steps are still progress.",
      "You are doing better than you think.",
      "Your feelings are valid.",
      "Peace begins with a deep breath.",
      "Be gentle with yourself today.",
    ];
    return messages[seed % messages.length];
  }

  static List<String> _getTriggers(Map<String, dynamic> entry) {
    if (entry['triggers'] != null && entry['triggers'] is List) {
      return (entry['triggers'] as List).map((e) => e.toString()).toList();
    } else if (entry['trigger'] != null &&
        (entry['trigger'] as String).isNotEmpty) {
      return [(entry['trigger'] as String)];
    }
    return [];
  }
}
