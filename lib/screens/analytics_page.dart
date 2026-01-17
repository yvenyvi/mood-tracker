import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mood_tracker/services/auth_service.dart';
import 'package:mood_tracker/theme/mood_assets.dart';
import 'package:mood_tracker/utils/app_date_utils.dart';
import 'package:lottie/lottie.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  String _selectedTimeRange = 'Week'; // 'Week' or 'Month'

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;
    final theme = Theme.of(context);

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mood Analytics')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('moods')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(theme);
          }

          final allEntries = snapshot.data!.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

          // Filter entries based on selection
          final now = DateTime.now();
          final cutoffDate = _selectedTimeRange == 'Week'
              ? now.subtract(const Duration(days: 7))
              : now.subtract(const Duration(days: 30));

          final filteredEntries = allEntries.where((e) {
            final ts = AppDateUtils.getDateTime(e['timestamp']);
            return ts.isAfter(cutoffDate);
          }).toList();

          // Calculations
          final totalEntries = filteredEntries.length;
          final currentStreak = _calculateStreak(allEntries); // Streak uses all
          final avgIntensity = _calculateAverageIntensity(filteredEntries);
          final moodCounts = _calculateMoodCounts(filteredEntries);
          final topMood = moodCounts.entries.isEmpty
              ? 'None'
              : moodCounts.entries
                    .reduce((a, b) => a.value > b.value ? a : b)
                    .key;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Time Range Selector
                _buildTimeRangeSelector(theme),
                const SizedBox(height: 24),

                // Insight Text
                _buildInsightSection(
                  theme,
                  currentStreak,
                  topMood,
                  _selectedTimeRange,
                ),
                const SizedBox(height: 24),

                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        'Streak',
                        '$currentStreak days',
                        Icons.local_fire_department,
                        Colors.orange,
                        null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        'Top Mood',
                        topMood,
                        Icons.star,
                        MoodAssets.getMoodColor(topMood),
                        topMood != 'None'
                            ? MoodAssets.getCategoryUrl(topMood)
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        'Avg Intensity',
                        avgIntensity.toStringAsFixed(1),
                        Icons.speed,
                        Colors.purple,
                        null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        'Total Logs',
                        '$totalEntries',
                        Icons.history,
                        Colors.blue,
                        null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Mood Composition (Pie Chart)
                Text(
                  'Mood Composition',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildMoodPieChart(context, filteredEntries),

                const SizedBox(height: 32),

                // Intensity Trend (Line Chart)
                Text(
                  'Intensity Trend',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Average intensity over time',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                _buildIntensityLineChart(
                  context,
                  filteredEntries,
                  _selectedTimeRange,
                ),

                const SizedBox(height: 32),

                // Top Triggers
                Text(
                  'Top Triggers',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTopTriggers(context, filteredEntries),

                const SizedBox(height: 32),

                // Frequent Emotions
                Text(
                  'Frequent Emotions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFrequentEmotions(context, filteredEntries),

                const SizedBox(height: 32),

                // Emotional Replay Section
                Text(
                  'Emotional Replay',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your $_selectedTimeRange in colors (Past → Present)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                _buildEmotionalReplay(context, filteredEntries),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: theme.colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text('No Data Yet', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Start logging your moods to see insights!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector(ThemeData theme) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment<String>(
          value: 'Week',
          label: Text('Week'),
          icon: Icon(Icons.calendar_view_week),
        ),
        ButtonSegment<String>(
          value: 'Month',
          label: Text('Month'),
          icon: Icon(Icons.calendar_month),
        ),
      ],
      selected: {_selectedTimeRange},
      onSelectionChanged: (Set<String> newSelection) {
        setState(() {
          _selectedTimeRange = newSelection.first;
        });
      },
      style: ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildInsightSection(
    ThemeData theme,
    int streak,
    String topMood,
    String range,
  ) {
    String message = '';
    if (streak > 3) {
      message = "You're on a $streak-day streak! Consistency is key. 🔥";
    } else if (topMood == 'Happy' ||
        topMood == 'Excited' ||
        topMood == 'Great') {
      message =
          "You've been feeling mostly positive this $range! Keep it up. ✨";
    } else if (topMood == 'Sad' || topMood == 'Tired' || topMood == 'Stress') {
      message =
          "It's been a tough $range. Remember to be gentle with yourself. 💙";
    } else {
      message = "You've had a balanced $range. Staying steady is good! ⚖️";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.secondary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateStreak(List<Map<String, dynamic>> entries) {
    if (entries.isEmpty) return 0;
    int streak = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final newestEntryTime = AppDateUtils.getDateTime(
      entries.first['timestamp'],
    );
    final newestEntryDate = DateTime(
      newestEntryTime.year,
      newestEntryTime.month,
      newestEntryTime.day,
    );
    DateTime expectedDate = today;

    if (newestEntryDate.isBefore(today)) {
      final yesterday = today.subtract(const Duration(days: 1));
      if (newestEntryDate.difference(yesterday).inDays == 0) {
        expectedDate = yesterday;
      } else {
        return 0;
      }
    }

    Set<String> uniqueDays = {};
    for (var entry in entries) {
      final ts = AppDateUtils.getDateTime(entry['timestamp']);
      final dateKey = AppDateUtils.formatIsoDate(ts);
      if (!uniqueDays.contains(dateKey)) {
        uniqueDays.add(dateKey);
        final date = DateTime(ts.year, ts.month, ts.day);
        if (date.difference(expectedDate).inDays == 0) {
          streak++;
          expectedDate = expectedDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }
    }
    return streak;
  }

  double _calculateAverageIntensity(List<Map<String, dynamic>> entries) {
    if (entries.isEmpty) return 0.0;
    double sum = 0;
    int count = 0;
    for (var entry in entries) {
      if (entry['intensity'] != null) {
        sum += (entry['intensity'] as num).toDouble();
        count++;
      }
    }
    return count == 0 ? 0.0 : sum / count;
  }

  Map<String, int> _calculateMoodCounts(List<Map<String, dynamic>> entries) {
    Map<String, int> counts = {};
    for (var entry in entries) {
      final mood = entry['mood'] as String? ?? 'Neutral';
      counts[mood] = (counts[mood] ?? 0) + 1;
    }
    return counts;
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String? lottieUrl,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                if (lottieUrl != null)
                  Lottie.network(lottieUrl, width: 30, height: 30),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmotionalReplay(
    BuildContext context,
    List<Map<String, dynamic>> entries,
  ) {
    // Show up to 14 recent entries in the gradient
    final recentEntries = entries.take(14).toList().reversed.toList();

    if (recentEntries.isEmpty) {
      return const SizedBox(height: 50, child: Center(child: Text("No data")));
    }

    return Container(
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: recentEntries.map((e) {
            return MoodAssets.getMoodColor(
              e['mood'] ?? 'Neutral',
            ).withValues(alpha: 0.8);
          }).toList(),
          stops: _calculateStops(recentEntries.length),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 8,
            left: 16,
            child: Text(
              'Past → Present',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black45, blurRadius: 2)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<double> _calculateStops(int count) {
    if (count <= 1) return [0.0];
    final List<double> stops = [];
    final double step = 1.0 / (count - 1);
    for (int i = 0; i < count; i++) {
      stops.add(i * step);
    }
    return stops;
  }

  Widget _buildMoodPieChart(
    BuildContext context,
    List<Map<String, dynamic>> entries,
  ) {
    final counts = _calculateMoodCounts(entries);
    if (counts.isEmpty) {
      return const SizedBox(height: 200, child: Center(child: Text('No Data')));
    }

    final total = entries.length;
    final List<PieChartSectionData> sections = counts.entries.map((e) {
      final mood = e.key;
      final count = e.value;
      final percentage = count / total;
      final color = MoodAssets.getMoodColor(mood);

      return PieChartSectionData(
        color: color,
        value: count.toDouble(),
        title: '${(percentage * 100).toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$total',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('Entries', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntensityLineChart(
    BuildContext context,
    List<Map<String, dynamic>> entries,
    String range,
  ) {
    List<FlSpot> spots = [];
    double interval = 1.0;
    double maxX = 6.0;

    if (range == 'Week') {
      spots = _getWeekData(entries);
      maxX = 6.0;
      interval = 1.0;
    } else {
      spots = _getMonthData(entries);
      maxX = 3.0; // 4 weeks (0,1,2,3)
      interval = 1.0;
    }

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (range == 'Week') {
                    final date = DateTime.now().subtract(
                      Duration(days: 6 - value.toInt()),
                    );
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        AppDateUtils.formatShortWeekday(date)[0],
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'W${4 - value.toInt()}',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    );
                  }
                },
                interval: interval,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: maxX,
          minY: 0,
          maxY: 5.5, // Intensity 1-5
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _getWeekData(List<Map<String, dynamic>> entries) {
    final now = DateTime.now();
    List<FlSpot> spots = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = AppDateUtils.formatIsoDate(date);
      final dayEntries = entries.where((e) {
        final ts = AppDateUtils.getDateTime(e['timestamp']);
        return AppDateUtils.formatIsoDate(ts) == dateStr;
      }).toList();

      if (dayEntries.isNotEmpty) {
        final avg = _calculateAverageIntensity(dayEntries);
        spots.add(FlSpot((6 - i).toDouble(), avg));
      } else {
        spots.add(FlSpot((6 - i).toDouble(), 0));
      }
    }
    return spots;
  }

  List<FlSpot> _getMonthData(List<Map<String, dynamic>> entries) {
    final now = DateTime.now();
    List<FlSpot> spots = [];

    for (int i = 3; i >= 0; i--) {
      final end = now.subtract(Duration(days: i * 7));
      final start = end.subtract(const Duration(days: 6));

      final weekEntries = entries.where((e) {
        final ts = AppDateUtils.getDateTime(e['timestamp']);
        final d = DateTime(ts.year, ts.month, ts.day);
        final s = DateTime(start.year, start.month, start.day);
        final en = DateTime(end.year, end.month, end.day);
        return (d.isAfter(s) || d.isAtSameMomentAs(s)) &&
            (d.isBefore(en) || d.isAtSameMomentAs(en));
      }).toList();

      if (weekEntries.isNotEmpty) {
        final avg = _calculateAverageIntensity(weekEntries);
        spots.add(FlSpot((3 - i).toDouble(), avg));
      } else {
        spots.add(FlSpot((3 - i).toDouble(), 0));
      }
    }
    return spots;
  }

  Widget _buildTopTriggers(
    BuildContext context,
    List<Map<String, dynamic>> entries,
  ) {
    final counts = _calculateTriggerCounts(entries);
    if (counts.isEmpty) {
      return const Text('No triggers recorded yet.');
    }

    // Sort by count descending
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();

    return Column(
      children: top.map((e) {
        final count = e.value;
        final totalFn = entries
            .where((entry) => entry['trigger'] != null)
            .length;
        final pct = (count / totalFn);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  e.key,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                flex: 4,
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(pct * 100).toInt()}%',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Map<String, int> _calculateTriggerCounts(List<Map<String, dynamic>> entries) {
    Map<String, int> counts = {};
    for (var entry in entries) {
      // Handle new list format
      if (entry['triggers'] != null && (entry['triggers'] as List).isNotEmpty) {
        final triggers = entry['triggers'] as List;
        for (var t in triggers) {
          final tStr = t.toString().trim();
          if (tStr.isNotEmpty) {
            counts[tStr] = (counts[tStr] ?? 0) + 1;
          }
        }
      }
      // Handle legacy string format (fallback if list is missing/empty)
      else {
        final trigger = entry['trigger'] as String?;
        if (trigger != null && trigger.isNotEmpty) {
          // Some legacy entries might be comma separated manually
          final parts = trigger.split(',');
          for (var part in parts) {
            final t = part.trim();
            if (t.isNotEmpty) {
              counts[t] = (counts[t] ?? 0) + 1;
            }
          }
        }
      }
    }
    return counts;
  }

  Widget _buildFrequentEmotions(
    BuildContext context,
    List<Map<String, dynamic>> entries,
  ) {
    final counts = _calculateEmotionCounts(entries);
    if (counts.isEmpty) {
      return const Text('No emotions recorded yet.');
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(10).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: top.map((e) {
        return Chip(
          label: Text('${e.key} (${e.value})'),
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          side: BorderSide.none,
        );
      }).toList(),
    );
  }

  Map<String, int> _calculateEmotionCounts(List<Map<String, dynamic>> entries) {
    Map<String, int> counts = {};
    for (var entry in entries) {
      final emotions = entry['emotions'] as List?;
      if (emotions != null) {
        for (var e in emotions) {
          final eStr = e.toString();
          counts[eStr] = (counts[eStr] ?? 0) + 1;
        }
      }
    }
    return counts;
  }
}
