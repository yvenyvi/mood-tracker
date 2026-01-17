import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:mood_tracker/theme/mood_assets.dart';
import 'package:mood_tracker/utils/app_date_utils.dart';
import 'package:mood_tracker/widgets/single_entry_detail_sheet.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Map<String, dynamic>> _allLogs = [];
  List<Map<String, dynamic>> _filteredLogs = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchLogs();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterLogs();
    });
  }

  Future<void> _fetchLogs() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('moods')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      final logs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['timestamp'] = AppDateUtils.getDateTime(data['timestamp']);
        return data;
      }).toList();

      if (mounted) {
        setState(() {
          _allLogs = logs;
          _filteredLogs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching logs for search: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterLogs() {
    if (_searchQuery.isEmpty) {
      _filteredLogs = _allLogs;
      return;
    }

    _filteredLogs = _allLogs.where((log) {
      final note = (log['note'] as String? ?? '').toLowerCase();
      if (note.contains(_searchQuery)) return true;

      final mood = (log['mood'] as String? ?? '').toLowerCase();
      if (mood.contains(_searchQuery)) return true;

      if (log['triggers'] != null && log['triggers'] is List) {
        final triggers = (log['triggers'] as List).cast<String>();
        if (triggers.any((t) => t.toLowerCase().contains(_searchQuery))) {
          return true;
        }
      } else if (log['trigger'] != null && log['trigger'] is String) {
        if ((log['trigger'] as String).toLowerCase().contains(_searchQuery)) {
          return true;
        }
      }

      if (log['emotions'] != null && log['emotions'] is List) {
        final emotions = (log['emotions'] as List).cast<String>();
        if (emotions.any((e) => e.toLowerCase().contains(_searchQuery))) {
          return true;
        }
      }

      if (log['coping_strategies'] != null &&
          log['coping_strategies'] is List) {
        final strategies = (log['coping_strategies'] as List).cast<String>();
        if (strategies.any((s) => s.toLowerCase().contains(_searchQuery))) {
          return true;
        }
      }

      if (log['physical_symptoms'] != null &&
          log['physical_symptoms'] is List) {
        final symptoms = (log['physical_symptoms'] as List).cast<String>();
        if (symptoms.any((s) => s.toLowerCase().contains(_searchQuery))) {
          return true;
        }
      }

      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildCustomHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredLogs.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _filteredLogs.length,
                      itemBuilder: (context, index) {
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(
                            milliseconds: 400 + (index * 50).clamp(0, 500),
                          ), // Slight stagger for initial load
                          curve: Curves.easeOutQuart,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 20 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: _buildEnhancedLogItem(_filteredLogs[index]),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              color: Theme.of(context).colorScheme.onSurface,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).shadowColor.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search mood, notes, triggers...',
                  hintStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close,
                            color: Theme.of(context).disabledColor,
                          ),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
          );
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 48,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty
                  ? 'Explore your history'
                  : 'No matches found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Try searching for a different keyword\nor check your spelling.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).disabledColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedLogItem(Map<String, dynamic> log) {
    final mood = log['mood'] as String? ?? 'Neutral';
    final timestamp = AppDateUtils.getDateTime(log['timestamp']);
    final note = log['note'] as String? ?? '';
    final moodColor = MoodAssets.getMoodColor(mood);
    final dateStr = AppDateUtils.formatMediumDate(timestamp);
    final timeStr = AppDateUtils.formatTime(timestamp);

    // Identify matched chips
    List<Widget> matchedChips = [];
    final search = _searchQuery.toLowerCase();

    // Helper to build chips
    Widget buildChip(String label, {bool isMatch = false}) {
      return Container(
        margin: const EdgeInsets.only(right: 6, top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isMatch
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Theme.of(context).dividerColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: isMatch
              ? Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                )
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isMatch ? FontWeight.bold : FontWeight.normal,
            color: isMatch
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      );
    }

    if (search.isNotEmpty) {
      // Triggers
      if (log['triggers'] != null && log['triggers'] is List) {
        for (var t in (log['triggers'] as List)) {
          if (t.toString().toLowerCase().contains(search)) {
            matchedChips.add(buildChip(t.toString(), isMatch: true));
          }
        }
      }

      // Emotions
      if (log['emotions'] != null && log['emotions'] is List) {
        for (var e in (log['emotions'] as List)) {
          if (e.toString().toLowerCase().contains(search)) {
            matchedChips.add(buildChip(e.toString(), isMatch: true));
          }
        }
      }
    }

    return GestureDetector(
      onTap: () => _showEntryDetails(context, log),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Mood Indicator (Lottie or Icon)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: moodColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Lottie.network(
                      MoodAssets.getCategoryUrl(mood),
                      width: 32,
                      height: 32,
                      animate: false,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.mood, color: moodColor, size: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mood,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '$dateStr • $timeStr',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Theme.of(context).disabledColor,
                ),
              ],
            ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
            ],
            if (matchedChips.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(children: matchedChips),
            ],
          ],
        ),
      ),
    );
  }

  void _showEntryDetails(BuildContext context, Map<String, dynamic> log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SingleEntryDetailSheet(entry: log),
    );
  }
}
