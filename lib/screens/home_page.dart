import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mood_tracker/theme/app_theme.dart';
import 'package:mood_tracker/utils/app_date_utils.dart';
import 'package:mood_tracker/utils/daily_messages.dart';
import 'package:mood_tracker/screens/mood_entry_page.dart';
import 'package:mood_tracker/screens/profile_page.dart';
import 'package:mood_tracker/screens/settings_page.dart';
import 'package:lottie/lottie.dart';
import 'package:mood_tracker/theme/mood_assets.dart';
import 'package:provider/provider.dart';
import 'package:mood_tracker/services/auth_service.dart';
import 'package:mood_tracker/screens/mood_history_page.dart';
import 'package:mood_tracker/screens/search_page.dart';
import 'package:mood_tracker/widgets/mood_details_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Rebuild to update DateTime.now() references in UI
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(user),
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: user?.photoURL != null
                  ? ClipOval(
                      child: Image.network(
                        user!.photoURL!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildInitialsAvatar(
                              user,
                              textColor: Theme.of(
                                context,
                              ).colorScheme.onSecondary,
                            ),
                      ),
                    )
                  : _buildInitialsAvatar(
                      user,
                      textColor: Theme.of(context).colorScheme.onSecondary,
                    ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.add_circle_outline,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MoodEntryPage()),
              );
              // Refresh state when returning from mood entry
              if (mounted) {
                setState(() {});
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Theme.of(context).dividerColor, height: 1.0),
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

  Widget _buildDrawer(User? user) {
    final colorScheme = Theme.of(context).colorScheme;
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      width: MediaQuery.of(context).size.width * 0.85,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: colorScheme.secondary),
            currentAccountPicture: CircleAvatar(
              backgroundColor: colorScheme.surface,
              child: user?.photoURL != null
                  ? ClipOval(
                      child: Image.network(
                        user!.photoURL!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildInitialsAvatar(
                              user,
                              textColor: colorScheme.secondary,
                            ),
                      ),
                    )
                  : _buildInitialsAvatar(
                      user,
                      textColor: colorScheme.secondary,
                    ),
            ),
            accountName: Text(
              user?.displayName ?? 'Friend',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSecondary,
              ),
            ),
            accountEmail: Text(
              user?.email ?? '',
              style: TextStyle(color: colorScheme.onSecondary.withAlpha(179)),
            ),
          ),
          ListTile(
            leading: Icon(Icons.person_outline, color: colorScheme.onSurface),
            title: Text(
              'Profile',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.settings_outlined,
              color: colorScheme.onSurface,
            ),
            title: Text(
              'Settings',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.emergency_outlined,
              color: AppTheme.blossomPink, // Use our theme color
            ),
            title: Text(
              'Emergency Support',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {
              Navigator.pop(context); // Close drawer
              _showEmergencyHotlinesDialog(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.info_outline, color: colorScheme.onSurface),
            title: Text(
              'About Emote',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            onTap: () {
              Navigator.pop(context); // Close drawer
              _showAboutDialog(context);
            },
          ),
          const Spacer(),
          Divider(color: Theme.of(context).dividerColor),
          ListTile(
            leading: Icon(Icons.logout, color: colorScheme.error),
            title: Text('Logout', style: TextStyle(color: colorScheme.error)),
            onTap: () async {
              Navigator.pop(context);
              await context.read<AuthService>().signOut();
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showEmergencyHotlinesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.phone_in_talk, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('Crisis Hotlines'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You are not alone. Reach out if you need help.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              _buildHotlineItem(
                'National Center for Mental Health',
                '0917-899-USAP (8727)\n988 (Landline)',
              ),
              _buildHotlineItem(
                'In Touch Community Services',
                '0917-800-1123\n0922-893-8944',
              ),
              _buildHotlineItem(
                'Hopeline Philippines',
                '2919 (Globe/TM)\n0917-558-4673',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Emote',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.mood,
          size: 40,
          color: Theme.of(context).primaryColor,
        ),
      ),
      children: [
        const SizedBox(height: 16),
        const Text(
          'Emote is a safe space tailored to help you track your emotions, identify triggers, and build resilience.',
        ),
        const SizedBox(height: 12),
        const Text(
          'Developed with 🩷 for mental health awareness.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildHotlineItem(String title, String number) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          SelectableText(
            number,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar(User? user, {Color textColor = Colors.white}) {
    final displayName = user?.displayName ?? user?.email ?? 'Guest';
    final initials = _getInitials(displayName);

    return Text(
      initials,
      style: TextStyle(
        color: textColor,
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
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'How are you feeling today?',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
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
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.emoji_emotions,
            color: Theme.of(context).colorScheme.primary,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              DailyMessages.getMessageOfTheDay(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
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
            color: Theme.of(context).cardColor, // Use card color from theme
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
                    'Entries',
                    entryCount.toString(),
                    Theme.of(context).colorScheme.primary,
                    icon: Icons.edit_note,
                  ),
                  _buildAnalyticCard(
                    'Avg Intensity',
                    avgIntensity,
                    Theme.of(context).colorScheme.secondary,
                    icon: Icons.trending_up,
                  ),
                  _buildAnalyticCard(
                    'Most Common',
                    mostCommonMood,
                    widgetIcon: Lottie.network(
                      MoodAssets.getCategoryUrl(mostCommonMood),
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
