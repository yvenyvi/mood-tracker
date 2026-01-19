import 'package:flutter/material.dart';
import 'package:mood_tracker/theme/mood_assets.dart';
import 'package:lottie/lottie.dart';

class UserGuidePage extends StatelessWidget {
  final String? sectionKey;

  const UserGuidePage({super.key, this.sectionKey});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Guide')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(context),
            const Divider(height: 32),
            _buildSection(
              context,
              'Home Page',
              'Your dashboard for daily tracking.',
              Icons.home_outlined,
              [
                _buildGuideItem(
                  context,
                  'Daily Message',
                  'A personalized greeting and prompt to check in with yourself.',
                ),
                _buildGuideItem(
                  context,
                  'Today\'s Analytics',
                  'A quick snapshot of your day so far, showing entry count and average intensity.',
                ),
                _buildGuideItem(
                  context,
                  'Calendar',
                  'A monthly view of your mood history. Days are colored by the average mood of that day.',
                ),
              ],
            ),
            const Divider(height: 32),
            _buildSection(
              context,
              'Analytics',
              'Understand your emotional trends.',
              Icons.analytics_outlined,
              [
                _buildGuideItem(
                  context,
                  'Streak',
                  'Consecutive days you have logged a mood.',
                ),
                _buildGuideItem(
                  context,
                  'Avg Intensity',
                  'The average score of your moods (1-5 scale). Higher means more positive.',
                ),
                _buildGuideItem(
                  context,
                  'Intensity Trend',
                  'A graph showing how your mood fluctuates over the week or month.',
                ),
                _buildGuideItem(
                  context,
                  'Emotional Replay',
                  'A color gradient visualizing your recent mood history from past to present.',
                ),
              ],
            ),
            const Divider(height: 32),
            _buildSection(
              context,
              'Journal Logs',
              'Review your past entries.',
              Icons.history_outlined,
              [
                _buildGuideItem(
                  context,
                  'History View',
                  'Scroll through a chronological list of your mood entries.',
                ),
                _buildGuideItem(
                  context,
                  'Details',
                  'Tap on any day\'s card to view full details, including notes, triggers, and symptoms.',
                ),
              ],
            ),
            const Divider(height: 32),
            _buildIntensitySection(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome to Emote Guide',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Here is a quick overview of how to use the app and read your data.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildGuideItem(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.secondary.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntensitySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.speed, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Mood Intensity Scale',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Your mood intensity is calculated based on the category you select, ranging from 1 to 5.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        _buildIntensityRow(context, 5, 'Great / Happy / Excited', 'Happy'),
        _buildIntensityRow(context, 4, 'Good', 'Happy'), // Fallback icon
        _buildIntensityRow(context, 3, 'Okay / Neutral', 'Neutral'),
        _buildIntensityRow(context, 2, 'Tired', 'Tired'),
        _buildIntensityRow(context, 1, 'Bad / Sad / Angry / Stress', 'Sad'),
      ],
    );
  }

  Widget _buildIntensityRow(
    BuildContext context,
    int score,
    String label,
    String lottieCategory,
  ) {
    // Determine color based on common representation of that intensity
    // Just picking one representative color for the bar
    Color color;
    switch (score) {
      case 5:
        color = MoodAssets.getMoodColor('Happy');
        break;
      case 4:
        color = MoodAssets.getMoodColor('Good');
        break;
      case 3:
        color = MoodAssets.getMoodColor('Neutral');
        break;
      case 2:
        color = MoodAssets.getMoodColor('Tired');
        break;
      case 1:
        color = MoodAssets.getMoodColor('Sad');
        break;
      default:
        color = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(4),
            child: score == 4
                ? Center(
                    child: Text(
                      "4",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  )
                : Lottie.network(MoodAssets.getCategoryUrl(lottieCategory)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Intensity $score',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
