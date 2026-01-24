import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mood_tracker/theme/app_theme.dart';
import 'package:mood_tracker/screens/mood_entry_page.dart';
import 'package:mood_tracker/screens/profile_page.dart';
import 'package:mood_tracker/screens/settings_page.dart';
import 'package:provider/provider.dart';
import 'package:mood_tracker/services/auth_service.dart';
import 'package:mood_tracker/screens/search_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mood_tracker/widgets/daily_message_card.dart';
import 'package:mood_tracker/widgets/mood_analytics_card.dart';
import 'package:mood_tracker/widgets/calendar_card.dart';
import 'package:mood_tracker/screens/user_guide_page.dart'; // Import Guide Page
import 'package:mood_tracker/providers/comfort_provider.dart';

class HomePage extends StatefulWidget {
  final GlobalKey? welcomeKey;

  const HomePage({super.key, this.welcomeKey});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInternet();
  }

  Future<void> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        if (mounted && _isOffline) setState(() => _isOffline = false);
      }
    } on SocketException catch (_) {
      if (mounted && !_isOffline) setState(() => _isOffline = true);
    }
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
      _checkInternet();
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
            tooltip: "Comfort Mode",
            icon: Icon(
              Icons.spa,
              color: Theme.of(context).colorScheme.primary, // Make it distinct
            ),
            onPressed: () {
              context.read<ComfortProvider>().enable();
            },
          ),
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
          IconButton(
            icon: Icon(
              Icons.help_outline,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            tooltip: 'User Guide',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserGuidePage()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: _isOffline
            ? PreferredSize(
                preferredSize: const Size.fromHeight(30),
                child: Container(
                  width: double.infinity,
                  color: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: const Text(
                    'You are offline. Logs will be synced later.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              )
            : PreferredSize(
                preferredSize: const Size.fromHeight(1.0),
                child: Container(
                  color: Theme.of(context).dividerColor,
                  height: 1.0,
                ),
              ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome & Daily Message Group
              Container(
                key: widget.welcomeKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeSection(user),
                    const SizedBox(height: 24),
                    const DailyMessageCard(),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Today's Mood Analytics
              const MoodAnalyticsCard(),
              const SizedBox(height: 32),

              // Calendar Section
              const CalendarCard(),
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
          // IMPORTANT: Emergency Support First
          ListTile(
            leading: Icon(
              Icons.emergency_outlined,
              color: AppTheme.blossomPink,
            ),
            title: Text(
              'Emergency Support',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showEmergencyHotlinesDialog(context);
            },
          ),
          Divider(color: Theme.of(context).dividerColor.withValues(alpha: 0.5)),
          // Core Navigation
          ListTile(
            leading: Icon(Icons.person_outline, color: colorScheme.onSurface),
            title: Text(
              'Profile',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            onTap: () {
              Navigator.pop(context);
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
          // Info & Tools
          ListTile(
            leading: Icon(Icons.info_outline, color: colorScheme.onSurface),
            title: Text(
              'About Emote',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            onTap: () {
              Navigator.pop(context);
              _showAboutDialog(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.help_outline, color: colorScheme.onSurface),
            title: Text(
              'Reset Tutorial',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            onTap: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('has_seen_tutorial');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Tutorial reset! Restart app to see it again.',
                    ),
                  ),
                );
              }
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
}
