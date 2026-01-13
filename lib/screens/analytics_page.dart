import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mood_tracker/services/auth_service.dart';
import 'package:mood_tracker/theme/mood_assets.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

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
            final ts = (e['timestamp'] as Timestamp).toDate();
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

                const SizedBox(height: 32),

                // Weekly/Monthly Chart
                Text(
                  _selectedTimeRange == 'Week'
                      ? 'Daily Intensity'
                      : 'Weekly Intensity',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _selectedTimeRange == 'Week'
                    ? _buildDailyIntensityChart(context, filteredEntries)
                    : _buildWeeklyAverageChart(context, filteredEntries),
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
    final newestEntryTime = (entries.first['timestamp'] as Timestamp).toDate();
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
      final ts = (entry['timestamp'] as Timestamp).toDate();
      final dateKey = DateFormat('yyyy-MM-dd').format(ts);
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

  Widget _buildDailyIntensityChart(
    BuildContext context,
    List<Map<String, dynamic>> entries,
  ) {
    final now = DateTime.now();
    final last7Days = List.generate(
      7,
      (i) => now.subtract(Duration(days: 6 - i)),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: last7Days.map((date) {
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final dayEntries = entries.where((e) {
          final ts = (e['timestamp'] as Timestamp).toDate();
          return DateFormat('yyyy-MM-dd').format(ts) == dateStr;
        }).toList();

        double avg = 0;
        Color barColor = Colors.grey.withValues(alpha: 0.2);

        if (dayEntries.isNotEmpty) {
          avg = _calculateAverageIntensity(dayEntries);
          final counts = _calculateMoodCounts(dayEntries);
          final dominant = counts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
          barColor = MoodAssets.getMoodColor(dominant);
        }

        final dayLabel = DateFormat('E').format(date)[0];

        return _chartBar(context, avg, barColor, dayLabel);
      }).toList(),
    );
  }

  Widget _buildWeeklyAverageChart(
    BuildContext context,
    List<Map<String, dynamic>> entries,
  ) {
    // Last 4 weeks
    final now = DateTime.now();
    final List<Widget> bars = [];

    for (int i = 3; i >= 0; i--) {
      // Start of week (Monday)
      // Normalize today to start of week to find generic "Week X" ranges
      // Simplified: Just 7 days blocks going back
      final end = now.subtract(Duration(days: i * 7));
      final start = end.subtract(const Duration(days: 6));

      final weekEntries = entries.where((e) {
        final ts = (e['timestamp'] as Timestamp).toDate();
        // Check inclusive range
        // Reset times for simpler comparison
        final d = DateTime(ts.year, ts.month, ts.day);
        final s = DateTime(start.year, start.month, start.day);
        final en = DateTime(end.year, end.month, end.day);
        return (d.isAfter(s) || d.isAtSameMomentAs(s)) &&
            (d.isBefore(en) || d.isAtSameMomentAs(en));
      }).toList();

      double avg = 0;
      Color barColor = Colors.grey.withValues(alpha: 0.2);
      if (weekEntries.isNotEmpty) {
        avg = _calculateAverageIntensity(weekEntries);
        final counts = _calculateMoodCounts(weekEntries);
        final dominant = counts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
        barColor = MoodAssets.getMoodColor(dominant);
      }

      bars.add(_chartBar(context, avg, barColor, 'W${4 - i}'));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: bars,
    );
  }

  Widget _chartBar(
    BuildContext context,
    double value,
    Color color,
    String label,
  ) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 100,
          alignment: Alignment.bottomCenter,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Container(
            width: 12,
            height: (value / 5) * 100, // Normalize 1-5
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
