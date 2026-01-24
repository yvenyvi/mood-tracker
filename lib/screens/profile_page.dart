import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mood_tracker/services/auth_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;
    final theme = Theme.of(context);

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Not logged in")));
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile & Tools'),
          bottom: const TabBar(
            isScrollable: false,
            tabs: [
              Tab(icon: Icon(Icons.bolt), text: "Triggers"),
              Tab(icon: Icon(Icons.favorite), text: "Safety"),
              Tab(icon: Icon(Icons.accessibility_new), text: "Body"),
              Tab(icon: Icon(Icons.mood), text: "Moods"),
            ],
          ),
        ),
        body: Column(
          children: [
            // User Header
            // User Header
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  color: theme.colorScheme.secondary.withAlpha(50),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          (user.displayName ?? 'U')[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName ?? 'Friend',
                            style: theme.textTheme.titleLarge,
                          ),
                          Text(
                            user.email ?? '',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 16,
                  child: IconButton(
                    icon: Icon(Icons.edit, color: theme.colorScheme.primary),
                    onPressed: () => _showEditProfileDialog(context, user),
                  ),
                ),
              ],
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                children: [
                  // Triggers Tab
                  _buildCrudList(
                    context,
                    userId: user.uid,
                    collection: 'triggers',
                    title: 'Triggers',
                    placeholder: 'e.g., Traffic, Deadline, Argument...',
                  ),
                  // Safety Menu Tab
                  _buildCrudList(
                    context,
                    userId: user.uid,
                    collection: 'coping_strategies',
                    title: 'Coping Mechanisms',
                    placeholder: 'e.g., Pet the dog, Deep breathing...',
                  ),
                  // Body Signals Tab
                  _buildCrudList(
                    context,
                    userId: user.uid,
                    collection: 'physical_symptoms',
                    title: 'Body Signals',
                    placeholder: 'e.g., Clenched jaw, Tight chest...',
                  ),
                  // Emotions Tab
                  _buildEmotionsTab(context, user.uid),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrudList(
    BuildContext context, {
    required String userId,
    required String collection,
    required String title,
    required String placeholder,
  }) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection(collection)
          .orderBy('created_at', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () => _showAddEditDialog(
                  context,
                  userId,
                  collection,
                  null,
                  null,
                  placeholder,
                ),
                icon: const Icon(Icons.add),
                label: Text('Add New $title'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
            Expanded(
              child: docs.isEmpty
                  ? Center(
                      child: Text(
                        'No items yet.\nAdd some to build your personal library.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final id = docs[index].id;
                        final name = data['name'] ?? '';

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            title: Text(name),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 20),
                                  onPressed: () => _showAddEditDialog(
                                    context,
                                    userId,
                                    collection,
                                    id,
                                    name,
                                    placeholder,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    size: 20,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () =>
                                      _deleteItem(userId, collection, id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmotionsTab(BuildContext context, String userId) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () =>
                _showAddEmotionDialog(context, userId, null, null, null),
            icon: const Icon(Icons.add),
            label: const Text('Add New Emotion'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('custom_emotions')
                .orderBy('created_at', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    'No custom moods yet.\nAdd specific feelings to your library.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                );
              }

              // Group by Mood
              final Map<String, List<DocumentSnapshot>> groupedEmotions = {};
              for (var doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                final mood = data['mood'] as String? ?? 'Neutral';
                if (!groupedEmotions.containsKey(mood)) {
                  groupedEmotions[mood] = [];
                }
                groupedEmotions[mood]!.add(doc);
              }

              return ListView.builder(
                itemCount: groupedEmotions.length,
                itemBuilder: (context, index) {
                  final mood = groupedEmotions.keys.elementAt(index);
                  final emotionDocs = groupedEmotions[mood]!;

                  return ExpansionTile(
                    title: Text(mood),
                    subtitle: Text('${emotionDocs.length} custom emotions'),
                    initiallyExpanded: true,
                    children: emotionDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['name'] ?? '';
                      final id = doc.id;

                      return ListTile(
                        title: Text(name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _showAddEmotionDialog(
                                context,
                                userId,
                                id,
                                name,
                                mood,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                size: 20,
                                color: Colors.redAccent,
                              ),
                              onPressed: () =>
                                  _deleteItem(userId, 'custom_emotions', id),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showAddEditDialog(
    BuildContext context,
    String userId,
    String collection,
    String? docId,
    String? currentName,
    String placeholder,
  ) async {
    final controller = TextEditingController(text: currentName);
    final isEditing = docId != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Item' : 'Add New Item'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: placeholder),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                if (isEditing) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection(collection)
                      .doc(docId)
                      .update({'name': text});
                } else {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection(collection)
                      .add({
                        'name': text,
                        'created_at': FieldValue.serverTimestamp(),
                      });
                }
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddEmotionDialog(
    BuildContext context,
    String userId,
    String? docId,
    String? currentName,
    String? currentMood,
  ) async {
    final nameController = TextEditingController(text: currentName);
    String selectedMood = currentMood ?? 'Happy';
    final isEditing = docId != null;

    // Importing MoodAssets locally if not available globally, or rely on hardcoded list if imports are tricky in this block.
    // Ideally we should import MoodAssets at top of file.
    // For now, I will hardcode the categories to avoid import errors if MoodAssets isn't imported,
    // but I see I should add the import to the file if it's missing.
    // Assuming MoodAssets is available or I'll add the import in a separate step if needed.
    // Wait, I can only replace one block. I should check if MoodAssets is imported.
    // Reviewing previous file view... MoodAssets is NOT imported in profile_page.dart.
    // I will use a hardcoded list for now or `MoodAssets.categories` if I add the import.
    // Since I can't add the import in this block effectively without reading the whole file again or risking index issues,
    // I I'll standardise the list here matching MoodAssets.
    final categories = [
      'Happy',
      'Sad',
      'Neutral',
      'Angry',
      'Anxious',
      'Stress',
      'Excited',
      'Tired',
      'I Don\'t Know',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Edit Emotion' : 'Add New Emotion'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: categories.contains(selectedMood)
                        ? selectedMood
                        : categories.first,
                    items: categories.map((mood) {
                      return DropdownMenuItem(value: mood, child: Text(mood));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedMood = value);
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Main Mood'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: 'Emotion Name (e.g. Overjoyed)',
                      labelText: 'Emotion Name',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    autofocus: true,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final text = nameController.text.trim();
                    if (text.isNotEmpty) {
                      if (isEditing) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .collection('custom_emotions')
                            .doc(docId)
                            .update({'name': text, 'mood': selectedMood});
                      } else {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .collection('custom_emotions')
                            .add({
                              'name': text,
                              'mood': selectedMood,
                              'created_at': FieldValue.serverTimestamp(),
                            });
                      }
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteItem(
    String userId,
    String collection,
    String docId,
  ) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection(collection)
        .doc(docId)
        .delete();
  }

  Future<void> _showEditProfileDialog(
    BuildContext context,
    dynamic user,
  ) async {
    final controller = TextEditingController(text: user.displayName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter your name'),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                try {
                  await Provider.of<AuthService>(
                    context,
                    listen: false,
                  ).updateDisplayName(newName);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
