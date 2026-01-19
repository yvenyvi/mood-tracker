import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mood_tracker/providers/theme_provider.dart';
import 'package:mood_tracker/utils/app_date_utils.dart';
import 'package:mood_tracker/services/auth_service.dart';
import 'package:mood_tracker/services/biometric_service.dart';
import 'package:mood_tracker/services/notification_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isAppLockEnabled = false;
  List<TimeOfDay> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadReminders();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAppLockEnabled = prefs.getBool('app_lock_enabled') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _updateAppLockSettings(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();

    // If enabling, check if available and authenticate first
    if (enabled) {
      final bioService = BiometricService();
      if (!await bioService.isBiometricAvailable()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometrics not available on this device'),
            ),
          );
        }
        return;
      }

      final authenticated = await bioService.authenticate();
      if (!authenticated) return;
    }

    await prefs.setBool('app_lock_enabled', enabled);
    setState(() {
      _isAppLockEnabled = enabled;
    });
  }

  Future<void> _loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> storedReminders = prefs.getStringList('reminders') ?? [];
    setState(() {
      _reminders = storedReminders.map((time) {
        final parts = time.split(':');
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }).toList();
      _reminders.sort((a, b) {
        if (a.hour != b.hour) return a.hour.compareTo(b.hour);
        return a.minute.compareTo(b.minute);
      });
    });
  }

  Future<void> _addReminder() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      if (_reminders.any(
        (t) => t.hour == picked.hour && t.minute == picked.minute,
      )) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reminder already exists.')),
          );
        }
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _reminders.add(picked);
        _reminders.sort((a, b) {
          if (a.hour != b.hour) return a.hour.compareTo(b.hour);
          return a.minute.compareTo(b.minute);
        });
      });

      await _saveReminders(prefs);
      await _scheduleReminders();
    }
  }

  Future<void> _deleteReminder(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _reminders.removeWhere(
        (t) => t.hour == time.hour && t.minute == time.minute,
      );
    });
    await _saveReminders(prefs);
    await _scheduleReminders();
  }

  Future<void> _saveReminders(SharedPreferences prefs) async {
    final List<String> timeStrings = _reminders
        .map((t) => '${t.hour}:${t.minute.toString().padLeft(2, '0')}')
        .toList();
    await prefs.setStringList('reminders', timeStrings);
  }

  Future<void> _scheduleReminders() async {
    await NotificationService().cancelAllNotifications();
    for (int i = 0; i < _reminders.length; i++) {
      await NotificationService().scheduleDailyNotification(
        id: i,
        time: _reminders[i],
        title: 'Time to log your mood!',
        body: 'How are you feeling right now?',
      );
    }
    await NotificationService().requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    // Access auth service to get current user ID
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return ListView(
                  children: [
                    const Divider(),

                    // Appearance Section
                    ListTile(
                      title: Text(
                        'Appearance',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    RadioGroup<ThemeMode>(
                      groupValue: themeProvider.themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          themeProvider.setThemeMode(value);
                        }
                      },
                      child: Column(
                        children: const [
                          RadioListTile<ThemeMode>(
                            title: Text('System Default'),
                            value: ThemeMode.system,
                          ),
                          RadioListTile<ThemeMode>(
                            title: Text('Light Theme'),
                            value: ThemeMode.light,
                          ),
                          RadioListTile<ThemeMode>(
                            title: Text('Dark Theme'),
                            value: ThemeMode.dark,
                          ),
                        ],
                      ),
                    ),

                    const Divider(),

                    // Security Section
                    ListTile(
                      title: Text(
                        'Security',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('App Lock'),
                      subtitle: const Text(
                        'Require FaceID/Fingerprint to unlock',
                      ),
                      value: _isAppLockEnabled,
                      onChanged: (value) {
                        _updateAppLockSettings(value);
                      },
                    ),

                    const Divider(),

                    // Reminders Section
                    ListTile(
                      title: Text(
                        'Reminders',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_alarm),
                        onPressed: _addReminder,
                        tooltip: 'Add Reminder',
                      ),
                    ),
                    if (_reminders.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Text(
                          'No reminders set. Tap + to add one.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ..._reminders.map(
                        (time) => ListTile(
                          leading: const Icon(Icons.notifications_active),
                          title: Text(time.format(context)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteReminder(time),
                          ),
                        ),
                      ),
                    if (_reminders.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await NotificationService().showInstantNotification(
                              id: 999,
                              title: 'Test Notification',
                              body: 'This is a test reminder from Emote.',
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Notification sent! (Wait a few seconds)',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.mark_chat_unread_outlined),
                          label: const Text('Send Test Notification'),
                        ),
                      ),
                    const Divider(),

                    // Data Management Section
                    ListTile(
                      title: Text(
                        'Data Management',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),

                    // Export Data
                    ListTile(
                      leading: const Icon(Icons.file_download),
                      title: const Text('Export Data'),
                      subtitle: const Text('Download all mood logs as JSON'),
                      onTap: () => _exportData(context, user?.uid),
                    ),

                    // Delete Data
                    ListTile(
                      leading: const Icon(
                        Icons.delete_forever,
                        color: Colors.red,
                      ),
                      title: const Text(
                        'Delete All Data',
                        style: TextStyle(color: Colors.red),
                      ),
                      subtitle: const Text(
                        'Permanently remove all mood entries',
                      ),
                      onTap: () => _showDeleteConfirmation(context, user?.uid),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Future<void> _exportData(BuildContext context, String? userId) async {
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not logged in.')));
      return;
    }

    try {
      // Show loading indicator
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preparing export...')));

      // 1. Fetch data
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('moods')
          .orderBy('timestamp', descending: true)
          .get();

      final data = querySnapshot.docs.map((doc) {
        final docData = doc.data();
        // Convert Timestamp to ISO8601 String for JSON
        docData['timestamp'] = AppDateUtils.getDateTime(
          docData['timestamp'],
        ).toIso8601String();
        return docData;
      }).toList();

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      // 2. Get Directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        // Fallback or request permissions usually handled by path_provider or intent
        // simpler approach for now using getDownloadsDirectory if available
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        // Desktop
        directory = await getDownloadsDirectory();
      }

      // Fallback if generic method fails or returns null
      directory ??= await getApplicationDocumentsDirectory();

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final file = File(
        '${directory.path}/mood_tracker_export_$timestamp.json',
      );

      await file.writeAsString(jsonString);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data exported to: ${file.path}'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    String? userId,
  ) async {
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Data?'),
        content: const Text(
          'This action cannot be undone. All your mood logs will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      _deleteAllData(context, userId);
    }
  }

  Future<void> _deleteAllData(BuildContext context, String userId) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Deleting data...')));

      final moods = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('moods');

      // Batch delete (limit 500 per batch)
      final snapshot = await moods.get();
      final batch = FirebaseFirestore.instance.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data successfully deleted.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }
}
