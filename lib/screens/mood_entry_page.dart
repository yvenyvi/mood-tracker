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
  final _copingController = TextEditingController();
  final _symptomController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize prompt
    _currentPrompt = MoodAssets.getAdaptivePrompt('Neutral');
  }

  String _selectedMood = 'Neutral'; // Default category
  String _currentPrompt = '';
  bool _isSaving = false;

  final Set<String> _selectedTriggers = {};
  final Set<String> _selectedEmotions = {};
  final Set<String> _selectedCopingStrategies = {};
  final Set<String> _selectedSymptoms = {};

  // Map categories to approximate intensity (1-5) for backward compatibility/analytics

  @override
  void dispose() {
    _noteController.dispose();
    _triggerController.dispose();
    _copingController.dispose();
    _symptomController.dispose();
    super.dispose();
  }

  Future<void> _processNewItems(
    String input,
    Set<String> selectedSet,
    String collectionName,
    String userId,
  ) async {
    if (input.isEmpty) return;

    final newItems = input
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);

    for (var item in newItems) {
      if (!selectedSet.contains(item)) {
        selectedSet.add(item);
      }

      // Persist for future validation
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection(collectionName)
          .where('name', isEqualTo: item)
          .get()
          .then((snapshot) {
            if (snapshot.docs.isEmpty) {
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection(collectionName)
                  .add({'name': item, 'created_at': DateTime.now()});
            }
          });
    }
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
      // 1. Process new items for all dynamic fields
      await Future.wait([
        _processNewItems(
          _triggerController.text.trim(),
          _selectedTriggers,
          'triggers',
          user.uid,
        ),
        _processNewItems(
          _copingController.text.trim(),
          _selectedCopingStrategies,
          'coping_strategies',
          user.uid,
        ),
        _processNewItems(
          _symptomController.text.trim(),
          _selectedSymptoms,
          'physical_symptoms',
          user.uid,
        ),
      ]);

      final List<String> allTriggers = List.from(_selectedTriggers);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('moods')
          .add({
            'intensity': MoodAssets.getIntensity(_selectedMood),
            'mood': _selectedMood,
            'note': _noteController.text.trim(),
            'trigger': allTriggers.join(', '), // Legacy support
            'triggers': allTriggers, // New list format

            'emotions': _selectedEmotions.toList(),
            'coping_strategies': _selectedCopingStrategies.toList(),
            'physical_symptoms': _selectedSymptoms.toList(),
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
          _currentPrompt = MoodAssets.getAdaptivePrompt('Neutral');

          _selectedTriggers.clear();
          _selectedEmotions.clear();
          _selectedCopingStrategies.clear();
          _selectedSymptoms.clear();
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
    final currentColor = MoodAssets.getMoodColor(_selectedMood);

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
              children: MoodAssets.categories.map((mood) {
                final isSelected = _selectedMood == mood;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMood = mood;
                      _currentPrompt = MoodAssets.getAdaptivePrompt(mood);
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
                                      color: MoodAssets.getMoodColor(mood),
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
                                    color: Colors.grey,
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
                              ? MoodAssets.getMoodColor(mood)
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
              children: (MoodAssets.emotions[_selectedMood] ?? []).map((
                emotion,
              ) {
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
                  selectedColor: currentColor.withValues(
                    alpha: isDark ? 0.4 : 0.2,
                  ),
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

            // Triggers Section
            _buildDynamicSection(
              context,
              user?.uid,
              'triggers',
              'What triggered this?',
              _selectedTriggers,
              _triggerController,
              'Add new trigger (e.g. Traffic, News)...',
            ),

            const SizedBox(height: 32),

            // Note Input
            // Note Input (Adaptive Prompt)
            Text(
              _currentPrompt,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Write your thoughts here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor,
              ),
              maxLines: 4,
            ),

            const SizedBox(height: 32),

            // Coping Strategies Section
            _buildDynamicSection(
              context,
              user?.uid,
              'coping_strategies',
              'Did anything help? (Safety Menu)',
              _selectedCopingStrategies,
              _copingController,
              'Add helpful activity (e.g. Walk, Music)...',
            ),

            const SizedBox(height: 32),

            // Physical Symptoms Section
            _buildDynamicSection(
              context,
              user?.uid,
              'physical_symptoms',
              'Physical Symptoms',
              _selectedSymptoms,
              _symptomController,
              'Add symptom (e.g. Headache, Tiredness)...',
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
                  : Text(
                      'Save Entry',
                      style: TextStyle(
                        fontSize: 18,
                        color:
                            ThemeData.estimateBrightnessForColor(
                                  currentColor,
                                ) ==
                                Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicSection(
    BuildContext context,
    String? userId,
    String collection,
    String title,
    Set<String> selectedSet,
    TextEditingController controller,
    String hintText,
  ) {
    if (userId == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = MoodAssets.getMoodColor(_selectedMood);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection(collection)
              .orderBy('created_at', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(
                'Error loading items: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              );
            }

            if (!snapshot.hasData) {
              return const SizedBox(
                height: 20,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }

            final docs = snapshot.data!.docs;
            // Only show if we have items, otherwise the adding prompt is enough
            if (docs.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] as String? ?? '';
                    final isSelected = selectedSet.contains(name);

                    return FilterChip(
                      label: Text(name),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedSet.add(name);
                          } else {
                            selectedSet.remove(name);
                          }
                        });
                      },
                      backgroundColor: Theme.of(
                        context,
                      ).inputDecorationTheme.fillColor,
                      selectedColor: primaryColor.withValues(
                        alpha: isDark ? 0.4 : 0.2,
                      ),
                      checkmarkColor: isSelected
                          ? (isDark ? Colors.white : primaryColor)
                          : null,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? (isDark ? Colors.white : primaryColor)
                            : Theme.of(context).textTheme.bodyLarge?.color,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      side: isSelected
                          ? BorderSide(color: primaryColor)
                          : BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }).toList(),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),

        // Text Input for adding new items
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Theme.of(context).inputDecorationTheme.fillColor,
          ),
        ),
      ],
    );
  }
}
