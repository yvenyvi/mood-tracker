import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mood_tracker/theme/mood_assets.dart';
import 'package:mood_tracker/utils/app_date_utils.dart';
import 'package:mood_tracker/screens/mood_history_page.dart';
import 'package:mood_tracker/widgets/mood_details_sheet.dart';

class CalendarCard extends StatefulWidget {
  const CalendarCard({super.key});

  @override
  State<CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends State<CalendarCard> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCalendarHeader(),
        const SizedBox(height: 16),
        _buildCalendar(),
      ],
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          AppDateUtils.formatMonthYear(_selectedMonth),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(
                    _selectedMonth.year,
                    _selectedMonth.month - 1,
                  );
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _selectedMonth = DateTime(
                    _selectedMonth.year,
                    _selectedMonth.month + 1,
                  );
                });
              },
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    MoodHistoryPage(selectedMonth: _selectedMonth),
              ),
            );
          },
          child: const Text('See All'),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('moods')
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: DateTime(
              _selectedMonth.year,
              _selectedMonth.month,
              1,
            ),
            isLessThan: DateTime(
              _selectedMonth.year,
              _selectedMonth.month + 1,
              1,
            ),
          )
          .snapshots(),
      builder: (context, snapshot) {
        final moodData = <DateTime, List<Map<String, dynamic>>>{};

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = AppDateUtils.getDateTime(data['timestamp']);
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

          // Sort entries by time for each day (latest first)
          for (var entries in moodData.values) {
            entries.sort((a, b) {
              final tA = AppDateUtils.getDateTime(a['timestamp']);
              final tB = AppDateUtils.getDateTime(b['timestamp']);
              return tB.compareTo(tA);
            });
          }
        }

        return _buildCalendarGrid(moodData);
      },
    );
  }

  Widget _buildCalendarGrid(
    Map<DateTime, List<Map<String, dynamic>>> moodData,
  ) {
    final firstDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month,
      1,
    );
    final lastDayOfMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + 1,
      0,
    );
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0 = Sunday

    return Column(
      children: [
        // Weekday headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),

        // Calendar grid
        ...List.generate((daysInMonth + firstWeekday) ~/ 7 + 1, (weekIndex) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (dayIndex) {
                final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 1;

                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const Expanded(child: SizedBox());
                }

                final date = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month,
                  dayNumber,
                );
                final hasMood = moodData.containsKey(date);
                final moodColor = hasMood
                    ? MoodAssets.getMoodColor(
                        moodData[date]!.first['mood'] ?? 'neutral',
                      )
                    : null;

                final isDark = Theme.of(context).brightness == Brightness.dark;

                return Expanded(
                  child: GestureDetector(
                    onTap: hasMood
                        ? () => _showMoodDetails(context, moodData[date]!)
                        : null,
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: hasMood
                            ? (moodData[date]!.first['mood'] == 'I Don\'t Know'
                                  ? const RadialGradient(
                                      center: Alignment(-0.5, -0.5),
                                      radius: 1.4,
                                      colors: [
                                        Color.fromARGB(
                                          255,
                                          147,
                                          8,
                                          172,
                                        ), // Purple
                                        Color.fromARGB(255, 5, 84, 148), // Blue
                                        Color.fromARGB(255, 1, 46, 41), // Teal
                                        Color.fromARGB(
                                          255,
                                          160,
                                          60,
                                          29,
                                        ), // Orange
                                      ],
                                    )
                                  : RadialGradient(
                                      center: const Alignment(-0.5, -0.5),
                                      radius: 1.2,
                                      colors: [
                                        Color.lerp(
                                          moodColor,
                                          isDark ? Colors.black : Colors.white,
                                          0.4,
                                        )!, // Highlight
                                        moodColor!,
                                      ],
                                    ))
                            : null,
                        color: hasMood
                            ? null
                            : Theme.of(context)
                                  .inputDecorationTheme
                                  .fillColor, // Use theme fill color for empty days
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: hasMood
                            ? [
                                BoxShadow(
                                  color: moodColor!.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                        border:
                            date.day == DateTime.now().day &&
                                date.month == DateTime.now().month &&
                                date.year == DateTime.now().year
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '$dayNumber',
                          style: TextStyle(
                            color: hasMood
                                ? Colors
                                      .white // Mood cells always white text
                                : Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color, // Regular day text
                            fontWeight: hasMood
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  void _showMoodDetails(
    BuildContext context,
    List<Map<String, dynamic>> entries,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MoodDetailsSheet(entries: entries),
    );
  }
}
