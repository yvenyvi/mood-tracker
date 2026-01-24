import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mood_tracker/services/auth_service.dart';
import 'package:mood_tracker/theme/mood_assets.dart';
import 'package:mood_tracker/utils/app_date_utils.dart';
import 'package:lottie/lottie.dart';
import 'package:mood_tracker/screens/user_guide_page.dart'; // Import Guide Page
import 'package:mood_tracker/widgets/analytics/emotional_flow.dart';
import 'package:mood_tracker/widgets/analytics/insight_card.dart';
import 'package:mood_tracker/widgets/analytics/vibe_heatmap.dart';
import 'package:mood_tracker/services/insight_service.dart';

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
      appBar: AppBar(
        title: const Text('Mood Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'User Guide',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserGuidePage()),
              );
            },
          ),
        ],
      ),
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
          // Calculations
          final currentStreak = _calculateStreak(allEntries); // Streak uses all
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

                // 1. Emotional Flow (Updated Visual)
                Text(
                  'Emotional Flow',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Drag to explore your timeline',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                EmotionalFlow(entries: filteredEntries),

                const SizedBox(height: 32),

                // 2. Mood Hotspots (Carousel)
                // Generate insights on the fly
                Builder(
                  builder: (context) {
                    final insights = InsightService.generateInsights(
                      allEntries,
                    ); // Analyze all history for patterns
                    if (insights.isNotEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mood Hotspots',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height:
                                300, // Increased height to prevent overflow with long tips
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: insights.length,
                              clipBehavior: Clip.none,
                              itemBuilder: (context, index) {
                                return InsightCard(insight: insights[index]);
                              },
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

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
                        topMood !=
                                'None' // Pass name to fallback logic
                            ? MoodAssets.getCategoryUrl(
                                topMood,
                              ) // Still pass URL, but handled by card
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 3. Vibe Check (Heatmap)
                Text(
                  'Vibe Check',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                VibeHeatmap(
                  entries: allEntries,
                ), // Use all entries for monthly view

                const SizedBox(height: 32), // Bottom padding
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
                  Lottie.network(
                    lottieUrl,
                    width: 30,
                    height: 30,
                    errorBuilder: (context, error, stackTrace) {
                      // Extract mood from url if possible or just use a generic one?
                      // Actually this widget doesn't know the mood name directly, but it's used for Top Mood.
                      // The value (topMood) is passed as 'value' but that is the displayed text.
                      // Wait, _buildSummaryCard takes 'lottieUrl' as nullable String.
                      // But it doesn't take 'moodName'.
                      // However, in the usage at line 128:
                      // MoodAssets.getCategoryUrl(topMood) is passed.
                      // I should pass the mood name to _buildSummaryCard instead or in addition to be safe?
                      // Or I can infer it? No, inference is risky.
                      // Better to pass 'mood' as an optional parameter if needed?
                      // Or just show a generic icon?
                      // But the requirement is "offline emoji's".
                      // I will modify _buildSummaryCard to accept specific mood name or rely on passed icon if lottie fails?
                      // Actually, let's look at the usage.
                      // Usage: _buildSummaryCard(..., topMood, ..., MoodAssets.getCategoryUrl(topMood))
                      // So 'value' IS the mood name for Top Mood card.
                      // For other cards, 'value' is "5 days" or "3.5".
                      // So I can check if 'title' is 'Top Mood'.
                      if (title == 'Top Mood') {
                        return Text(
                          MoodAssets.getFallbackEmoji(value),
                          style: const TextStyle(fontSize: 20),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
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
}
