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
  final _triggerController = TextEditingController();

  String _selectedMood = 'Neutral'; // Default category
  bool _isSaving = false;
  final Set<String> _selectedEmotions = {};

  final List<String> _moodCategories = [
    'Happy',
    'Sad',
    'Neutral',
    'Angry',
    'Anxious',
    'Stress',
    'Excited',
    'Tired',
  ];

  final Map<String, List<String>> _emotionsData = {
    'Happy': ['Joy', 'Content', 'Gratitude'],
    'Sad': ['Low mood', 'Loneliness', 'Grief'],
    'Neutral': ['Calm', 'OK', 'Emotionally flat'],
    'Angry': ['Irritation', 'Frustration', 'Rage'],
    'Anxious': ['Worry', 'Nervousness', 'Fear'],
    'Stress': ['Pressure', 'Burnout'],
    'Excited': ['Anticipation', 'Motivation'],
    'Tired': ['Emotional exhaustion', 'Mental exhaustion'],
  };

  final Map<String, Color> _moodColors = {
    'Happy': Colors.amber,
    'Sad': const Color(0xFF42A5F5), // Blue 400
    'Neutral': Colors.grey,
    'Angry': const Color(0xFFEF5350), // Red 400
    'Anxious': const Color(0xFFAB47BC), // Purple 400
    'Stress': const Color(0xFFFF7043), // Orange 400
    'Excited': const Color(0xFF26A69A), // Teal 400
    'Tired': const Color(0xFF78909C), // Blue Grey 400
  };

  // Map categories to approximate intensity (1-5) for backward compatibility/analytics
  int _getIntensity(String mood) {
    switch (mood) {
      case 'Happy':
      case 'Excited':
        return 5;
      case 'Neutral':
        return 3;
      case 'Tired':
        return 2; // Low energy
      case 'Sad':
      case 'Angry':
      case 'Anxious':
      case 'Stress':
        return 1; // Negative
      default:
        return 3;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _triggerController.dispose();
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
            'intensity': _getIntensity(_selectedMood),
            'mood': _selectedMood,
            'note': _noteController.text.trim(),
            'trigger': _triggerController.text.trim(),
            'emotions': _selectedEmotions.toList(),
            'timestamp': DateTime.now(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mood saved successfully!')),
        );
        _noteController.clear();
        _triggerController.clear();
        setState(() {
          _selectedMood = 'Neutral';
          _selectedEmotions.clear();
        });
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
    final user = Provider.of<AuthService>(context).user;
    final displayName = user?.displayName ?? 'Friend';
    final currentColor = _moodColors[_selectedMood] ?? Colors.grey;

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

            // Primary Mood Selector (Grid of Categories)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _moodCategories.map((mood) {
                final isSelected = _selectedMood == mood;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMood = mood;
                      _selectedEmotions
                          .clear(); // Clear specific emotions when category changes
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.all(isSelected ? 4 : 0),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: _moodColors[mood] ?? Colors.grey,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Opacity(
                              opacity: isSelected ? 1.0 : 0.5,
                              child: Lottie.network(
                                MoodAssets.getCategoryUrl(mood),
                                width: isSelected ? 60 : 50,
                                height: isSelected ? 60 : 50,
                                animate: true, // Always animate
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.error,
                                    size: isSelected ? 48 : 40,
                                    color: Theme.of(
                                      context,
                                    ).unselectedWidgetColor,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mood,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? _moodColors[mood]
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Specific Emotions Chips (Context Aware)
            Text(
              'What specifically?',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_emotionsData[_selectedMood] ?? []).map((emotion) {
                final isSelected = _selectedEmotions.contains(emotion);
                final isDark = Theme.of(context).brightness == Brightness.dark;

                return FilterChip(
                  label: Text(emotion),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedEmotions.add(emotion);
                      } else {
                        _selectedEmotions.remove(emotion);
                      }
                    });
                  },
                  backgroundColor: Theme.of(
                    context,
                  ).inputDecorationTheme.fillColor,
                  selectedColor: currentColor.withAlpha(isDark ? 100 : 50),
                  checkmarkColor: isSelected
                      ? (isDark ? Colors.white : currentColor)
                      : null,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? (isDark ? Colors.white : currentColor)
                        : Theme.of(context).textTheme.bodyLarge?.color,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  side: isSelected
                      ? BorderSide(color: currentColor)
                      : BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Trigger Input
            Text(
              'What triggered this?',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _triggerController,
              decoration: const InputDecoration(
                hintText: 'e.g., Work deadline, Argument with friend...',
                border: OutlineInputBorder(),
              ),
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
                backgroundColor: currentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Save Entry',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
