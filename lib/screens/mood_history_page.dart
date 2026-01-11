import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:mood_tracker/theme/mood_assets.dart';
import 'package:mood_tracker/widgets/mood_details_sheet.dart';

class MoodHistoryPage extends StatelessWidget {
  final DateTime? selectedMonth;

  const MoodHistoryPage({super.key, this.selectedMonth});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    final targetDate = selectedMonth ?? DateTime.now();
    final startOfMonth = DateTime(targetDate.year, targetDate.month, 1);
    final nextMonth = DateTime(targetDate.year, targetDate.month + 1, 1);

    return Scaffold(
      appBar: AppBar(title: Text(DateFormat('MMMM yyyy').format(targetDate))),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('moods')
            .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)
            .where('timestamp', isLessThan: nextMonth)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No mood entries found.'));
          }

          // Group by day
          final moodData = <DateTime, List<Map<String, dynamic>>>{};
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = (data['timestamp'] as Timestamp)
                .toDate()
                .toLocal();
            final date = DateTime(
              timestamp.year,
              timestamp.month,
              timestamp.day,
            );

            if (!moodData.containsKey(date)) {
              moodData[date] = [];
            }
            moodData[date]!.add(data);
          }

          final sortedDates = moodData.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final date = sortedDates[index];
              final entries = moodData[date]!;
              // Determine main mood for the day (most frequent or latest)
              // For simplicity, let's use the latest (first in list)
              final mainEntry = entries.first;
              final mood = mainEntry['mood'] ?? 'Neutral';

              final color = MoodAssets.getMoodColor(mood);
              final isDark = Theme.of(context).brightness == Brightness.dark;

              return Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Block (Left)
                    SizedBox(
                      width: 50,
                      child: Column(
                        children: [
                          Text(
                            DateFormat('d').format(date),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: isDark
                                  ? Colors.white
                                  : Colors.black, // High contrast
                            ),
                          ),
                          Text(
                            DateFormat('MMM').format(date).toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.black54, // High contrast
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 2,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white12
                                  : Colors.black12, // High contrast
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Content Bubble (Right)
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Theme.of(
                              context,
                            ).scaffoldBackgroundColor,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            builder: (context) =>
                                MoodDetailsSheet(entries: entries),
                          );
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          decoration: BoxDecoration(
                            color: color.withOpacity(isDark ? 0.15 : 0.08),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: color.withOpacity(
                                isDark ? 0.3 : 0.5,
                              ), // Darker border for light mode
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Lottie.network(
                                      MoodAssets.getCategoryUrl(mood),
                                      width: 28,
                                      height: 28,
                                      animate: false,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormat('h:mm a').format(date),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: color,
                                          ),
                                        ),
                                        Text(
                                          MoodAssets
                                                  .moodLabels[mainEntry['intensity']
                                                      as int? ??
                                                  3] ??
                                              (mainEntry['intensity'] == 0
                                                  ? 'Unsure'
                                                  : 'Unknown'),
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: color.withOpacity(0.5),
                                    size: 20,
                                  ),
                                ],
                              ),
                              if (mainEntry['trigger'] != null &&
                                  (mainEntry['trigger'] as String)
                                      .isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.bolt_rounded,
                                      size: 14,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        mainEntry['trigger'],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (mainEntry['emotions'] != null &&
                                  (mainEntry['emotions'] as List)
                                      .isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: (mainEntry['emotions'] as List)
                                      .take(3)
                                      .map<Widget>((e) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .scaffoldBackgroundColor
                                                .withOpacity(0.6),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            e.toString(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.8),
                                            ),
                                          ),
                                        );
                                      })
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
