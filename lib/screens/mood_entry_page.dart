import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:mood_tracker/services/auth_service.dart';
import 'package:mood_tracker/theme/mood_assets.dart';

class MoodEntryPage extends StatefulWidget {
  const MoodEntryPage({super.key});

  @override
  State<MoodEntryPage> createState() => _MoodEntryPageState();
}

class _MoodEntryPageState extends State<MoodEntryPage> {
  final _noteController = TextEditingController();
  int _selectedMood = 3; // Default to 'Okay' (3)
  bool _isSaving = false;

  final Map<int, String> _moodLabels = {
    1: 'Terrible',
    2: 'Bad',
    3: 'Okay',
    4: 'Good',
    5: 'Great',
  };

  final Map<int, Color> _moodColors = {
    1: Colors.red,
    2: Colors.orange,
    3: Colors.amber,
    4: Colors.lightGreen,
    5: Colors.green,
  };

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveMood() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to save.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('moods')
          .add({
            'intensity': _selectedMood,
            'mood': _moodLabels[_selectedMood],
            'note': _noteController.text.trim(),
            'timestamp': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mood saved successfully!')),
        );
        _noteController.clear();
        setState(() => _selectedMood = 3); // Reset
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving mood: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get user name if available
    final user = Provider.of<AuthService>(context).user;
    final displayName = user?.displayName ?? 'Friend';

    return Scaffold(
      appBar: AppBar(title: const Text('Mood Tracker')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Hi, $displayName!',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'How are you feeling right now?',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Mood Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _moodLabels.keys.map((moodValue) {
                final isSelected = _selectedMood == moodValue;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMood = moodValue),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.all(isSelected ? 4 : 0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: _moodColors[moodValue]!,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Opacity(
                          opacity: isSelected ? 1.0 : 0.5,
                          child: Lottie.network(
                            MoodAssets.getUrl(moodValue),
                            width: isSelected ? 60 : 50,
                            height: isSelected ? 60 : 50,
                            animate: true, // Always animate
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.error,
                                size: isSelected ? 48 : 40,
                                color: Colors.grey,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _moodLabels[moodValue]!,
                        style: TextStyle(
                          color: isSelected
                              ? _moodColors[moodValue]
                              : Colors.grey,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Note Input
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Add a note (optional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),

            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveMood,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _moodColors[_selectedMood],
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Entry', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
