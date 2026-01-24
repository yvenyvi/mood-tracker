import 'package:flutter/material.dart';
import 'package:mood_tracker/theme/mood_assets.dart';
import 'package:mood_tracker/utils/app_date_utils.dart';

class EmotionalFlow extends StatefulWidget {
  final List<Map<String, dynamic>> entries;
  final double height;

  const EmotionalFlow({super.key, required this.entries, this.height = 120});

  @override
  State<EmotionalFlow> createState() => _EmotionalFlowState();
}

class _EmotionalFlowState extends State<EmotionalFlow> {
  // Currently touched entry index (or null)
  int? _hoverIndex;
  Offset? _touchPosition;

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(child: Text("No data for flow")),
      );
    }

    // Sort entries by time (should already be sorted but ensure)
    final sorted = List<Map<String, dynamic>>.from(widget.entries);
    sorted.sort((a, b) {
      final ta = AppDateUtils.getDateTime(a['timestamp']);
      final tb = AppDateUtils.getDateTime(b['timestamp']);
      return ta.compareTo(tb);
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanStart: (details) =>
              _updateTouch(details.localPosition, constraints.maxWidth, sorted),
          onPanUpdate: (details) =>
              _updateTouch(details.localPosition, constraints.maxWidth, sorted),
          onPanEnd: (_) => setState(() => _hoverIndex = null),
          onTapDown: (details) =>
              _updateTouch(details.localPosition, constraints.maxWidth, sorted),
          onTapUp: (_) => setState(() => _hoverIndex = null),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // 1. The Gradient Stream
              Container(
                height: widget.height * 0.6,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).shadowColor.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  gradient: LinearGradient(
                    colors: sorted.map((e) {
                      return MoodAssets.getMoodColor(e['mood'] ?? 'Neutral');
                    }).toList(),
                    // Distribute stops evenly
                    stops: _generateStops(sorted.length),
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),

              // 2. Wave overlay (SVG or CustomPaint for "Fluid" look) - Optional polish
              // For now, simpler gradient is fine.

              // 3. Floating Bubble
              if (_hoverIndex != null && _touchPosition != null)
                Positioned(
                  left: _calculateBubbleLeft(
                    _touchPosition!.dx,
                    constraints.maxWidth,
                  ),
                  top: -60, // Float above
                  child: _buildBubble(context, sorted[_hoverIndex!]),
                ),

              // 4. Indicator line
              if (_hoverIndex != null && _touchPosition != null)
                Positioned(
                  left: _touchPosition!.dx,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _updateTouch(
    Offset localPosition,
    double width,
    List<Map<String, dynamic>> sorted,
  ) {
    if (sorted.isEmpty) return;

    // Map x-position to index
    // 0 -> 0, width -> sorted.length - 1
    double ratio = (localPosition.dx / width).clamp(0.0, 1.0);
    int index = (ratio * (sorted.length - 1)).round();

    // Snap X to the exact center of that segment?
    // Actually, ribbon is continuous. Let's just track the index.

    setState(() {
      _hoverIndex = index;
      // We keep the touch X for the line, but bubble shows content of index
      _touchPosition = Offset(localPosition.dx, localPosition.dy);
    });
  }

  List<double> _generateStops(int count) {
    if (count <= 1) return [0.0];
    final step = 1.0 / (count - 1);
    return List.generate(count, (i) => i * step);
  }

  double _calculateBubbleLeft(double touchX, double totalWidth) {
    // Keep bubble within bounds
    const bubbleWidth = 140.0;
    double left = touchX - (bubbleWidth / 2);
    if (left < 0) left = 0;
    if (left + bubbleWidth > totalWidth) left = totalWidth - bubbleWidth;
    return left;
  }

  Widget _buildBubble(BuildContext context, Map<String, dynamic> entry) {
    final mood = entry['mood'] ?? 'Neutral';
    final timestamp = AppDateUtils.getDateTime(entry['timestamp']);
    final note = entry['note'] as String? ?? entry['rant'] as String? ?? '';
    final color = MoodAssets.getMoodColor(mood);

    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                MoodAssets.getFallbackEmoji(mood),
                style: const TextStyle(fontSize: 16),
              ), // Use Emoji for compactness
              const SizedBox(width: 4),
              Text(
                AppDateUtils.formatTime(timestamp),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }
}
