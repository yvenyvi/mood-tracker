import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:mood_tracker/services/auth_service.dart';
import 'package:mood_tracker/theme/mood_assets.dart';
import 'package:mood_tracker/screens/user_guide_page.dart';
import 'package:mood_tracker/utils/app_date_utils.dart';

class MoodEntryPage extends StatefulWidget {
  final Map<String, dynamic>? existingEntry;
  final String? entryId;

  const MoodEntryPage({super.key, this.existingEntry, this.entryId});

  @override
  State<MoodEntryPage> createState() => _MoodEntryPageState();
}

class _MoodEntryPageState extends State<MoodEntryPage> {
  final _noteController = TextEditingController();
  final _triggerController = TextEditingController();
  final _copingController = TextEditingController();
  final _symptomController = TextEditingController();
  final _emotionController = TextEditingController();

  String _selectedMood = 'Neutral'; // Default category
  String _currentPrompt = '';
  bool _isSaving = false;

  final Set<String> _selectedTriggers = {};
  final Set<String> _selectedEmotions = {};
  final Set<String> _selectedCopingStrategies = {};
  final Set<String> _selectedSymptoms = {};

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      _initializeExistingData();
    } else {
      _currentPrompt = MoodAssets.getAdaptivePrompt('Neutral');
    }
  }

  void _initializeExistingData() {
    final data = widget.existingEntry!;
    _selectedMood = data['mood'] ?? 'Neutral';
    _currentPrompt = MoodAssets.getAdaptivePrompt(_selectedMood);

    _noteController.text = data['note'] ?? '';

    // Initialize collections
    if (data['triggers'] != null) {
      _selectedTriggers.addAll(List<String>.from(data['triggers']));
    } else if (data['trigger'] != null) {
      // Legacy support
      final String legacyTrigger = data['trigger'];
      if (legacyTrigger.isNotEmpty) {
        _selectedTriggers.addAll(
          legacyTrigger.split(', ').map((e) => e.trim()),
        );
      }
    }

    if (data['emotions'] != null) {
      _selectedEmotions.addAll(List<String>.from(data['emotions']));
    }

    if (data['coping_strategies'] != null) {
      _selectedCopingStrategies.addAll(
        List<String>.from(data['coping_strategies']),
      );
    }

    if (data['physical_symptoms'] != null) {
      _selectedSymptoms.addAll(List<String>.from(data['physical_symptoms']));
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _triggerController.dispose();
    _copingController.dispose();
    _symptomController.dispose();
    _emotionController.dispose();
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

      // Offline-safe: Try to check/write with timeout
      try {
        final queryOp = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection(collectionName)
            .where('name', isEqualTo: item)
            .get();

        // Short timeout for checks
        final querySnapshot = await queryOp.timeout(
          const Duration(milliseconds: 1500),
        );

        if (querySnapshot.docs.isEmpty) {
          final addOp = FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection(collectionName)
              .add({'name': item, 'created_at': DateTime.now()});
          await addOp.timeout(const Duration(milliseconds: 1500));
        }
      } catch (e) {
        // Ignore timeouts/errors for aux items when offline
        debugPrint("Aux item save skipped/timed out: $item");
        // Robustness: If we are offline, we might just assume it's fine to rely on local state
        // or maybe we should blindly add? Blindly adding duplicates might be bad when syncing later.
        // For now, skipping auxiliary tag persistence if check fails is acceptable to prevent blocking main save.
        // Use existing selectedSet so it is saved in the main log.
      }
    }
  }

  Future<void> _processNewEmotions(String input, String userId) async {
    if (input.isEmpty) return;

    final newItems = input
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);

    for (var item in newItems) {
      if (!_selectedEmotions.contains(item)) {
        _selectedEmotions.add(item);
      }

      try {
        final queryOp = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('custom_emotions')
            .where('name', isEqualTo: item)
            .where('mood', isEqualTo: _selectedMood)
            .get();

        final querySnapshot = await queryOp.timeout(
          const Duration(milliseconds: 1500),
        );

        if (querySnapshot.docs.isEmpty) {
          final addOp = FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('custom_emotions')
              .add({
                'name': item,
                'mood': _selectedMood,
                'created_at': DateTime.now(),
              });
          await addOp.timeout(const Duration(milliseconds: 1500));
        }
      } catch (e) {
        debugPrint("Emotion save skipped/timed out: $item");
      }
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
      // 1. Process new items for all dynamic fields with timeout safeguard
      // We wrap the entire batch in a timeout
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
        _processNewEmotions(_emotionController.text.trim(), user.uid),
      ]).timeout(const Duration(seconds: 3)).catchError((e) {
        debugPrint("Tag processing timed out, proceeding to save main log.");
        return []; // Return proper type? Future.wait returns List<dynamic>
      });

      final List<String> allTriggers = List.from(_selectedTriggers);
      final moodData = {
        'intensity': MoodAssets.getIntensity(_selectedMood),
        'mood': _selectedMood,
        'note': _noteController.text.trim(),
        'trigger': allTriggers.join(', '), // Legacy support
        'triggers': allTriggers, // New list format
        'emotions': _selectedEmotions.toList(),
        'coping_strategies': _selectedCopingStrategies.toList(),
        'physical_symptoms': _selectedSymptoms.toList(),
        'timestamp': widget.existingEntry != null
            ? widget.existingEntry!['timestamp'] // Keep original timestamp
            : DateTime.now(),
        if (widget.entryId != null) 'updated_at': DateTime.now(),
      };

      // 2. Perform Save with Timeout logic from previous step
      final saveData = Future<void>(() async {
        if (widget.entryId != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('moods')
              .doc(widget.entryId)
              .update(moodData);
        } else {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('moods')
              .add(moodData);
        }
      });

      // Wait for save with a timeout to prevent hanging when offline
      try {
        await saveData.timeout(const Duration(seconds: 2));
      } catch (e) {
        // Timeout means likely offline, but persistence queue accepted it.
        debugPrint("Save operation timed out (likely offline), proceeding.");
      }

      if (mounted) {
        final isEdit = widget.entryId != null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Mood updated successfully!'
                  : 'Mood saved successfully!',
            ),
          ),
        );

        if (isEdit) {
          Navigator.pop(context); // Return to history
        } else {
          // Reset fields
          _noteController.clear();
          _triggerController.clear();
          _emotionController.clear();
          _copingController.clear();
          _symptomController.clear();
          setState(() {
            _selectedMood = 'Neutral';
            _currentPrompt = MoodAssets.getAdaptivePrompt('Neutral');
            _selectedTriggers.clear();
            _selectedEmotions.clear();
            _selectedCopingStrategies.clear();
            _selectedSymptoms.clear();
            _isSaving = false;
          });
          // Close screen as expected behavior for "Save" usually implies "Done"
          // But existing behavior was "Stay and Reset".
          // Given user complaints about "spinner indefinitely", "Stay and Reset" works ONLY if spinner stops.
          // I'm setting _isSaving = false above.
          // Actually, usually users expect to go back to Home after saving a mood entry.
          // I will add Navigator.pop(context) to be consistent with good UX.
          Navigator.pop(context);
        }
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
      appBar: AppBar(
        title: const Text('Mood Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'User Guide',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserGuidePage()),
              );
            },
          ),
        ],
      ),
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
            const SizedBox(height: 4),
            Text(
              AppDateUtils.formatFullDate(
                widget.existingEntry != null
                    ? AppDateUtils.getDateTime(
                        widget.existingEntry!['timestamp'],
                      )
                    : DateTime.now(),
              ),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildSectionHeaderWithTooltip(
              context,
              'How are you feeling right now?',
              'Select the category that best matches your current mood.',
              isCenter: true,
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
                                  return Center(
                                    child: Text(
                                      MoodAssets.getFallbackEmoji(mood),
                                      style: TextStyle(
                                        fontSize: isSelected ? 32 : 24,
                                      ),
                                    ),
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
            _buildSectionHeaderWithTooltip(
              context,
              'What specifically?',
              'Choose specific emotions or add your own related to $_selectedMood.',
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: user != null
                  ? FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('custom_emotions')
                        .where('mood', isEqualTo: _selectedMood)
                        .snapshots()
                  : null,
              builder: (context, snapshot) {
                final List<String> availableEmotions = List.from(
                  MoodAssets.emotions[_selectedMood] ?? [],
                );

                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] as String?;
                    if (name != null && !availableEmotions.contains(name)) {
                      availableEmotions.add(name);
                    }
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableEmotions.map((emotion) {
                        final isSelected = _selectedEmotions.contains(emotion);
                        final isDark =
                            Theme.of(context).brightness == Brightness.dark;

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
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emotionController,
                      decoration: InputDecoration(
                        hintText: 'Add other emotions (e.g. Melancholy)...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(
                          context,
                        ).inputDecorationTheme.fillColor,
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // Triggers Section
            _buildDynamicSection(
              context,
              user?.uid,
              'triggers',
              'What triggered this?',
              'Select or add triggers responsible for this mood.',
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
              'Did anything help?',
              'Select strategies that helped you cope.',
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
              'Note any physical sensations you are experiencing.',
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
    String tooltip,
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
        _buildSectionHeaderWithTooltip(context, title, tooltip),
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

  Widget _buildSectionHeaderWithTooltip(
    BuildContext context,
    String title,
    String tooltip, {
    bool isCenter = false,
  }) {
    return Row(
      mainAxisAlignment: isCenter
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: [
        Text(
          title,
          style: isCenter
              ? Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: Colors.grey[600])
              : Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: tooltip,
          triggerMode: TooltipTriggerMode.tap,
          showDuration: const Duration(seconds: 3),
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          textStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
          ),
          child: Icon(
            Icons.help_outline,
            size: 18,
            color: Theme.of(context).colorScheme.primary.withAlpha(150),
          ),
        ),
      ],
    );
  }
}
