import 'package:flutter/material.dart';
import 'package:mood_tracker/theme/mood_assets.dart';
import 'package:mood_tracker/utils/app_date_utils.dart';

class VibeHeatmap extends StatefulWidget {
  final List<Map<String, dynamic>> entries;

  const VibeHeatmap({super.key, required this.entries});

  @override
  State<VibeHeatmap> createState() => _VibeHeatmapState();
}

class _VibeHeatmapState extends State<VibeHeatmap> {
  String? _selectedTrigger;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("No entries for Heatmap")),
      );
    }

    // 1. Extract all triggers for Filter
    final triggers = _getAllTriggers();

    // 2. Build Calendar Grid
    final daysInMonth = DateUtils.getDaysInMonth(
      _currentMonth.year,
      _currentMonth.month,
    );
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final offset = firstDay.weekday - 1; // 0 for Monday

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header & Filter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppDateUtils.formatMonthYear(_currentMonth),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (triggers.isNotEmpty)
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.filter_list,
                  color: _selectedTrigger != null
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
                onSelected: (val) {
                  setState(() {
                    _selectedTrigger = val == 'Clear' ? null : val;
                  });
                },
                itemBuilder: (context) {
                  return [
                    const PopupMenuItem(
                      value: 'Clear',
                      child: Text('Clear Filter'),
                    ),
                    ...triggers.map(
                      (t) => PopupMenuItem(value: t, child: Text(t)),
                    ),
                  ];
                },
              ),
          ],
        ),
        if (_selectedTrigger != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Chip(
              label: Text("Filtered by: $_selectedTrigger"),
              onDeleted: () => setState(() => _selectedTrigger = null),
            ),
          ),

        const SizedBox(height: 16),

        // Calendar Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: daysInMonth + offset,
          itemBuilder: (context, index) {
            if (index < offset) return const SizedBox.shrink();

            final day = index - offset + 1;
            final date = DateTime(_currentMonth.year, _currentMonth.month, day);
            final entry = _getEntryForDate(date);

            if (entry == null) {
              return _buildDayCircle(context, null, false);
            }

            // Check Filter
            bool match = true;
            if (_selectedTrigger != null) {
              final entryTriggers = _getTriggersForEntry(entry);
              if (!entryTriggers.contains(_selectedTrigger)) {
                match = false;
              }
            }

            return _buildDayCircle(context, entry, match);
          },
        ),
      ],
    );
  }

  // Helpers
  Set<String> _getAllTriggers() {
    final Set<String> all = {};
    for (var e in widget.entries) {
      all.addAll(_getTriggersForEntry(e));
    }
    return all;
  }

  List<String> _getTriggersForEntry(Map<String, dynamic> entry) {
    if (entry['triggers'] != null && entry['triggers'] is List) {
      return (entry['triggers'] as List).map((e) => e.toString()).toList();
    } else if (entry['trigger'] != null &&
        (entry['trigger'] as String).isNotEmpty) {
      return [(entry['trigger'] as String)];
    }
    return [];
  }

  Map<String, dynamic>? _getEntryForDate(DateTime date) {
    // Find *dominant* entry? simplest is last one or avg.
    // Let's take the latest one for visual simplicity as per spec
    try {
      return widget.entries.firstWhere((e) {
        final d = AppDateUtils.getDateTime(e['timestamp']);
        return d.year == date.year &&
            d.month == date.month &&
            d.day == date.day;
      });
    } catch (_) {
      return null;
    }
  }

  Widget _buildDayCircle(
    BuildContext context,
    Map<String, dynamic>? entry,
    bool isMatch,
  ) {
    if (entry == null) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
      );
    }

    final color = MoodAssets.getMoodColor(entry['mood'] ?? 'Neutral');

    return Opacity(
      opacity: isMatch ? 1.0 : 0.2, // Fade out non-matches
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: isMatch
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
