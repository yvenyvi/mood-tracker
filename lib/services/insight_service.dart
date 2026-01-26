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

    // 3. Physical Correlates (Symptom Patterns)
    final symptomStats = <String, List<Map<String, dynamic>>>{};
    for (var e in entries) {
      if (e['physical_symptoms'] != null &&
          (e['physical_symptoms'] as List).isNotEmpty) {
        final symptoms = (e['physical_symptoms'] as List)
            .map((s) => s.toString())
            .toList();
        for (var s in symptoms) {
          if (!symptomStats.containsKey(s)) symptomStats[s] = [];
          symptomStats[s]!.add(e);
        }
      }
    }

    // Check if any symptom is frequent (e.g. >= 2 times) and associated with low mood/high stress
    for (var entry in symptomStats.entries) {
      final symptom = entry.key;
      final occurrences = entry.value;
      if (occurrences.length >= 2) {
        int lowMoodCount = 0;
        for (var e in occurrences) {
          final intensity = (e['intensity'] as num?)?.toDouble() ?? 3.0;
          if (intensity <= 2) lowMoodCount++;
        }

        if (lowMoodCount >= (occurrences.length * 0.5)) {
          // 50% correlation with low mood
          insights.add({
            'type': 'physical_correlation',
            'title': 'Body & Mind Connection',
            'description':
                "You often report '$symptom' when you're feeling down or stressed.",
            'trigger': symptom,
            'coping_tip':
                "Scanning your body for tension can be a good first step.",
            'related_entries': occurrences,
          });
          // Break after finding one significant physical pattern to avoid clutter
          break;
        }
      }
    }

    // 4. Weekend Lift (Better mood on weekends)
    final weekendEntries = entries.where((e) {
      final dt = AppDateUtils.getDateTime(e['timestamp']);
      return dt.weekday == 6 || dt.weekday == 7; // Sat or Sun
    }).toList();

    final weekdayEntries = entries.where((e) {
      final dt = AppDateUtils.getDateTime(e['timestamp']);
      return dt.weekday >= 1 && dt.weekday <= 5;
    }).toList();

    if (weekendEntries.length >= 3 && weekdayEntries.length >= 5) {
      double weekendSum = 0;
      for (var e in weekendEntries) {
        weekendSum += (e['intensity'] as num?)?.toDouble() ?? 3.0;
      }
      double weekdaySum = 0;
      for (var e in weekdayEntries) {
        weekdaySum += (e['intensity'] as num?)?.toDouble() ?? 3.0;
      }

      final weekendAvg = weekendSum / weekendEntries.length;
      final weekdayAvg = weekdaySum / weekdayEntries.length;

      if (weekendAvg > (weekdayAvg + 1.0)) {
        // Significant difference
        insights.add({
          'type': 'pattern',
          'title': 'The Weekend Lift',
          'description':
              "Your mood is significantly higher on weekends compared to weekdays.",
          'trigger': null, // Time based
          'coping_tip':
              "What specifically about your weekends brings you joy? Try to bring one small piece of that into your Tuesday.",
          'related_entries': weekendEntries,
        });
      }
    }

    // 5. Evening Crash (Low mood after 8 PM)
    final eveningEntries = entries.where((e) {
      final dt = AppDateUtils.getDateTime(e['timestamp']);
      return dt.hour >= 20; // 8 PM onwards
    }).toList();

    if (eveningEntries.length >= 3) {
      int lowCount = 0;
      for (var e in eveningEntries) {
        final intensity = (e['intensity'] as num?)?.toDouble() ?? 3.0;
        if (intensity <= 2) lowCount++;
      }

      if (lowCount >= (eveningEntries.length * 0.6)) {
        insights.add({
          'type': 'pattern',
          'title': 'Evening Energy Dip',
          'description':
              "You tend to feel lower energy or mood in the late evenings (after 8 PM).",
          'trigger': null,
          'coping_tip':
              "This might be a sign of fatigue. Consider an earlier wind-down routine.",
          'related_entries': eveningEntries,
        });
      }
    }

    // 6. Social Battery (Social triggers leading to Tired/Drained)
    // We look for 'Social' or 'Family' or 'Friends' in triggers
    final socialKeywords = [
      'Social',
      'Family',
      'Friends',
      'Party',
      'Gathering',
      'Meeting',
      'Date',
    ];
    final socialEntries = entries.where((e) {
      final triggers = _getTriggers(e);
      return triggers.any((t) => socialKeywords.any((k) => t.contains(k)));
    }).toList();

    if (socialEntries.length >= 3) {
      int drainedCount = 0;
      for (var e in socialEntries) {
        final mood = e['mood'] as String? ?? '';
        final emotions =
            (e['emotions'] as List?)?.map((e) => e.toString()).toList() ?? [];

        if (mood == 'Tired' ||
            emotions.contains('Drained') ||
            emotions.contains('Exhausted') ||
            emotions.contains('Overwhelmed')) {
          drainedCount++;
        }
      }

      if (drainedCount >= (socialEntries.length * 0.5)) {
        insights.add({
          'type': 'pattern',
          'title': 'Social Battery Check',
          'description':
              "Social activities seem to often leave you feeling tired or drained.",
          'trigger': 'Social Activity',
          'coping_tip':
              "It's okay to set boundaries. Try shorter social engagements or scheduled quiet time after.",
          'related_entries': socialEntries,
        });
      }
    }

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
        'related_entries': <Map<String, dynamic>>[],
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
