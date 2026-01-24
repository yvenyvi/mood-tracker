import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mood_tracker/providers/comfort_provider.dart';
import 'package:mood_tracker/services/auth_service.dart';
import 'package:mood_tracker/widgets/comfort/breathing_circle.dart';

class ComfortView extends StatelessWidget {
  const ComfortView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header with Exit Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "COMFORT MODE",
                    style: TextStyle(
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      context.read<ComfortProvider>().disable();
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text("I'm feeling better"),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // 2. Breathing Circle
            const BreathingCircle(),

            const Spacer(),

            // 3. Safety Menu Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  const Icon(Icons.security, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    "YOUR SAFETY MENU",
                    style: TextStyle(
                      color: Colors.grey[600],
                      letterSpacing: 1.5,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Coping Strategies List
            Expanded(
              flex: 2,
              child: StreamBuilder<QuerySnapshot>(
                stream: user != null
                    ? FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('coping_strategies')
                          .orderBy('created_at', descending: true)
                          .snapshots()
                    : const Stream.empty(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildDefaultStrategies(context);
                  }

                  final docs = snapshot.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final name = data['name'] ?? '';
                      return _buildStrategyCard(context, name);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultStrategies(BuildContext context) {
    final defaults = [
      "Drink a glass of water",
      "Listen to calming music",
      "Step outside for fresh air",
      "Write down your thoughts",
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: defaults.length,
      itemBuilder: (context, index) {
        return _buildStrategyCard(context, defaults[index]);
      },
    );
  }

  Widget _buildStrategyCard(BuildContext context, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.spa,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Colors.grey,
        ),
        onTap: () {
          // In a real app, this might open details or a specific tool.
          // For now, it stays passive as a checklist/reminder.
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Focusing on: $title')));
        },
      ),
    );
  }
}
