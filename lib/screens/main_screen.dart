import 'package:flutter/material.dart';
import 'package:mood_tracker/screens/home_page.dart';
import 'package:mood_tracker/screens/mood_history_page.dart';
import 'package:mood_tracker/screens/analytics_page.dart';
import 'package:mood_tracker/utils/app_tutorial.dart';
import 'package:mood_tracker/screens/mood_entry_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final GlobalKey _welcomeKey = GlobalKey();
  final GlobalKey _addLogKey = GlobalKey();
  final GlobalKey _analyticsTabKey = GlobalKey();
  final GlobalKey _journalTabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Schedule tutorial to show after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Small delay to ensure everything is rendered
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          AppTutorial.showTutorial(
            context,
            welcomeKey: _welcomeKey,
            addLogKey: _addLogKey,
            analyticsTabKey: _analyticsTabKey,
            journalTabKey: _journalTabKey,
          );
        }
      });
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomePage(welcomeKey: _welcomeKey),
      const AnalyticsPage(),
      const MoodHistoryPage(), // Journal Tab
    ];
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      floatingActionButton: FloatingActionButton(
        key: _addLogKey,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MoodEntryPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined, key: _analyticsTabKey),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined, key: _journalTabKey),
            selectedIcon: Icon(Icons.history),
            label: 'Journal',
          ),
        ],
      ),
    );
  }
}
