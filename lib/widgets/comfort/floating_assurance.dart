import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class FloatingAssurance extends StatefulWidget {
  const FloatingAssurance({super.key});

  @override
  State<FloatingAssurance> createState() => _FloatingAssuranceState();
}

class _FloatingAssuranceState extends State<FloatingAssurance> {
  final List<String> _words = [
    "You are safe",
    "Breathe",
    "This too shall pass",
    "One moment at a time",
    "You are enough",
    "It's okay to pause",
    "Exhale tension",
    "You are strong",
    "Peace begins with you",
    "Slow down",
    "Trust yourself",
    "Let go",
    "You are doing your best",
    "Here and now",
    "Gentle steps",
    "Softly",
    "Begin again",
    "Limitless",
    "Just be",
    "Unfold",
    "Stillness",
    "Release",
    "Calm",
    "Steady",
    "Flow",
    "Ease",
    "Grace",
    "Patience",
    "Healing",
    "Light",
    "Warmth",
    "Courage",
    "Hope",
    "Anchor",
    "Rest",
    "Simplify",
    "Space",
    "Clarity",
    "Drift",
    "Floating",
    "Open heart",
    "Forgiveness",
    "Present",
    "Silence",
    "Serenity",
    "Balance",
    "Harmony",
    "Grounding",
    "Nurture",
    "Acceptance",
    "Safety",
    "Within you",
    "Soft heart",
    "New day",
    "Deep breath",
  ];

  final List<_Bubble> _bubbles = [];
  Timer? _timer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Start spawning bubbles
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      _spawnBubble();
    });
    // Spawn initial batch
    Future.microtask(() {
      _spawnBubble();
      _spawnBubble();
      _spawnBubble();
    });
  }

  void _spawnBubble() {
    setState(() {
      // Clean up old bubbles (match new duration)
      _bubbles.removeWhere(
        (b) => DateTime.now().difference(b.createdAt).inSeconds > 20,
      );

      // Add new
      _bubbles.add(
        _Bubble(
          id:
              DateTime.now().millisecondsSinceEpoch.toString() +
              _random.nextInt(1000).toString(),
          text: _words[_random.nextInt(_words.length)],
          startLeft: _random.nextDouble(),
          speed: 0.5 + _random.nextDouble() * 0.5, // speed factor
          size: 14 + _random.nextDouble() * 10,
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      // Let touches pass through to underlying UI
      child: Stack(
        children: _bubbles.map((b) => _buildBubbleWidget(b)).toList(),
      ),
    );
  }

  Widget _buildBubbleWidget(_Bubble bubble) {
    return _BubbleItem(bubble: bubble);
  }
}

class _BubbleItem extends StatefulWidget {
  final _Bubble bubble;
  const _BubbleItem({required this.bubble});

  @override
  State<_BubbleItem> createState() => _BubbleItemState();
}

class _BubbleItemState extends State<_BubbleItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _yAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18), // Slower, longer animation
    );

    _yAnimation = Tween<double>(begin: 1.1, end: -0.2).animate(_controller);
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.6), weight: 20),
      TweenSequenceItem(tween: ConstantTween(0.6), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.0), weight: 20),
    ]).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only rebuild position logic here
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left:
              widget.bubble.startLeft *
              (screenWidth - 100), // constrain width slightly
          top: _yAnimation.value * screenHeight,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Text(
                widget.bubble.text,
                style: TextStyle(
                  fontSize: widget.bubble.size,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Bubble {
  final String id;
  final String text;
  final double startLeft; // 0.0 to 1.0
  final double speed;
  final double size;
  final DateTime createdAt;

  _Bubble({
    required this.id,
    required this.text,
    required this.startLeft,
    required this.speed,
    required this.size,
    required this.createdAt,
  });
}

// Re-writing _BubbleItemState logic simpler without 'SequenceAnimationBuilder' which might be from a package
