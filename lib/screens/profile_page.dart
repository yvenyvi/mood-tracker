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
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile & Tools'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.favorite), text: "Safety Menu"),
              Tab(icon: Icon(Icons.accessibility_new), text: "Body Signals"),
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
