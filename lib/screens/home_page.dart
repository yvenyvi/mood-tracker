import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:mood_tracker/theme/app_theme.dart';
import 'package:mood_tracker/utils/daily_messages.dart';
import 'package:mood_tracker/screens/mood_entry_page.dart';
import 'package:lottie/lottie.dart';
import 'package:mood_tracker/theme/mood_assets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: AppColors.pastelBlue,
            child: user?.photoURL != null
                ? ClipOval(
                    child: Image.network(
                      user!.photoURL!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildInitialsAvatar(user),
                    ),
                  )
                : _buildInitialsAvatar(user),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.darkText),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: AppColors.darkText,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MoodEntryPage()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey[200], height: 1.0),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Message
              _buildWelcomeSection(user),
              const SizedBox(height: 24),

              // Daily Motivational Message
              _buildDailyMessage(),
              const SizedBox(height: 24),

              // Today's Mood Analytics
              _buildTodayAnalytics(),
              const SizedBox(height: 32),

              // Calendar Section
              _buildCalendarHeader(),
              const SizedBox(height: 16),
              _buildCalendar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(User? user) {
    final displayName = user?.displayName ?? user?.email ?? 'Guest';
    final initials = _getInitials(displayName);

    return Text(
      initials,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  Widget _buildWelcomeSection(User? user) {
    final isAnonymous = user?.isAnonymous ?? true;
    final displayName = user?.displayName ?? 'Friend';
    final greeting = _getGreeting();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAnonymous ? 'Hello, Friend' : '$greeting, $displayName',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'How are you feeling today?',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildDailyMessage() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.pastelBlue.withAlpha(77),
            AppColors.pastelPink.withAlpha(77),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.emoji_emotions,
            color: AppColors.pastelBlue,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              DailyMessages.getMessageOfTheDay(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayAnalytics() {
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(26),
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
                      color: AppColors.pastelBlue,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Today\'s Mood',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'No mood entries yet today',
                  style: TextStyle(color: Colors.grey[600]),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(26),
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
                    color: AppColors.pastelBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Today\'s Mood',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAnalyticCard(
                    'Entries',
                    entryCount.toString(),
                    AppColors.pastelBlue,
                    icon: Icons.edit_note,
                  ),
                  _buildAnalyticCard(
                    'Avg Intensity',
                    avgIntensity,
                    AppColors.pastelPink,
                    icon: Icons.trending_up,
                  ),
                  _buildAnalyticCard(
                    'Most Common',
                    mostCommonMood,
                    widgetIcon: Lottie.network(
                      MoodAssets.getUrl(
                        MoodAssets.getIntensity(mostCommonMood),
                      ),
                      width: 40,
                      height: 40,
                      animate: true,
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
          color: color.withAlpha(51),
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
                color: AppColors.darkText,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DateFormat('MMMM yyyy').format(_selectedMonth),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.darkText,
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
            final timestamp = (data['timestamp'] as Timestamp).toDate();
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
              final tA = (a['timestamp'] as Timestamp).toDate();
              final tB = (b['timestamp'] as Timestamp).toDate();
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
                        color: Colors.grey[600],
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
                    ? _getMoodColor(moodData[date]!.first['mood'] ?? 'neutral')
                    : null;

                return Expanded(
                  child: GestureDetector(
                    onTap: hasMood
                        ? () => _showMoodDetails(context, moodData[date]!)
                        : null,
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: moodColor ?? Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border:
                            date.day == DateTime.now().day &&
                                date.month == DateTime.now().month &&
                                date.year == DateTime.now().year
                            ? Border.all(color: AppColors.pastelBlue, width: 2)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '$dayNumber',
                          style: TextStyle(
                            color: hasMood ? Colors.white : AppColors.darkText,
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

  Color _getMoodColor(String? mood) {
    switch ((mood ?? 'neutral').toLowerCase()) {
      case 'happy':
      case 'good':
        return const Color(0xFFFDFD96); // Yellow
      case 'sad':
      case 'bad':
        return const Color(0xFFAEC6CF); // Blue
      case 'angry':
      case 'terrible':
        return const Color(0xFFFFB3BA); // Red
      case 'anxious':
        return const Color(0xFFB39EB5); // Purple
      case 'great':
        return const Color(0xFFB2F7EF); // Mint Green
      case 'netural':
      case 'okay':
      default:
        return Colors.grey;
    }
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
      builder: (context) {
        final firstTimestamp = (entries.first['timestamp'] as Timestamp)
            .toDate();

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, MMMM d, yyyy').format(firstTimestamp),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final moodData = entries[index];
                    final timestamp = (moodData['timestamp'] as Timestamp)
                        .toDate();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('h:mm a').format(timestamp),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text(
                              'Mood: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Lottie.network(
                              MoodAssets.getUrl(
                                MoodAssets.getIntensity(
                                  moodData['mood'] ?? 'neutral',
                                ),
                              ),
                              width: 30,
                              height: 30,
                            ),
                            const SizedBox(width: 8),
                            Text(moodData['mood'] ?? 'Unknown'),
                          ],
                        ),
                        if (moodData['intensity'] != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Text(
                                'Intensity: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text('${moodData['intensity']}/5'),
                            ],
                          ),
                        ],
                        if (moodData['note'] != null &&
                            (moodData['note'] as String).isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Notes:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(moodData['note']),
                        ] else if (moodData['rant'] != null &&
                            (moodData['rant'] as String).isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Notes:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(moodData['rant']),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
