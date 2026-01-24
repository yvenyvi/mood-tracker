import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:mood_tracker/theme/app_theme.dart';
import 'package:mood_tracker/theme/mood_assets.dart';

class MoodAnalyticsCard extends StatelessWidget {
  const MoodAnalyticsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('moods')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: startOfDay,
            isLessThanOrEqualTo: endOfDay,
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Today\'s Mood',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'No mood entries yet today',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          );
        }

        final moods = <String>[];
        int totalIntensity = 0;

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['mood'] != null) {
            moods.add(data['mood']);
          }
          if (data['intensity'] != null) {
            totalIntensity += (data['intensity'] as int);
          }
        }

        final entryCount = moods.length;
        final avgIntensity = entryCount > 0
            ? (totalIntensity / entryCount).toStringAsFixed(1)
            : '0';

        // Count mood types
        final moodCounts = <String, int>{};
        for (var mood in moods) {
          moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
        }

        final mostCommonMood = moodCounts.isNotEmpty
            ? moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
            : 'None';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Today\'s Mood',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAnalyticCard(
                    context,
                    'Entries',
                    entryCount.toString(),
                    Theme.of(context).colorScheme.primary,
                    icon: Icons.edit_note,
                  ),
                  _buildAnalyticCard(
                    context,
                    'Avg Intensity',
                    avgIntensity,
                    Theme.of(context).colorScheme.secondary,
                    icon: Icons.trending_up,
                  ),
                  _buildAnalyticCard(
                    context,
                    'Most Common',
                    mostCommonMood,
                    widgetIcon: Lottie.network(
                      MoodAssets.getCategoryUrl(mostCommonMood),
                      width: 40,
                      height: 40,
                      animate: true,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          MoodAssets.getFallbackEmoji(mostCommonMood),
                          style: const TextStyle(fontSize: 24),
                        );
                      },
                    ),
                    AppColors.pastelGreen,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticCard(
    BuildContext context,
    String label,
    String value,
    Color color, {
    IconData? icon,
    Widget? widgetIcon,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            widgetIcon ?? Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
