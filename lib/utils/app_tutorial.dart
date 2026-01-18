import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class AppTutorial {
  static const _prefKey = 'has_seen_tutorial';

  static Future<void> showTutorial(
    BuildContext context, {
    required GlobalKey welcomeKey,
    required GlobalKey addLogKey,
    required GlobalKey analyticsTabKey,
    required GlobalKey journalTabKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool(_prefKey) ?? false;

    if (hasSeen) return;

    if (!context.mounted) return;

    final targets = [
      TargetFocus(
        identify: "welcome",
        keyTarget: welcomeKey,
        alignSkip: Alignment.bottomLeft,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome to Emote! 👋",
                      style: _titleTextStyle(context),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        "Your safe space to track emotions and build resilience. Let's take a quick tour.",
                        style: _bodyTextStyle(context),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "add_log",
        keyTarget: addLogKey,
        alignSkip: Alignment.topLeft,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Log Your Mood 📝", style: _titleTextStyle(context)),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        "Tap this button to record how you're feeling, add triggers, and notes.",
                        style: _bodyTextStyle(context),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "analytics",
        keyTarget: analyticsTabKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("View Analytics 📊", style: _titleTextStyle(context)),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        "See insights about your mood patterns and emotional health over time.",
                        style: _bodyTextStyle(context),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "journal",
        keyTarget: journalTabKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Your Journal 📖", style: _titleTextStyle(context)),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        "Browse your past entries, grouped by day and month.",
                        style: _bodyTextStyle(context),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      TargetFocus(
        identify: "finish",
        keyTarget: welcomeKey,
        alignSkip: Alignment.bottomLeft,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("You're All Set! 🌟", style: _titleTextStyle(context)),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        "Start tracking, stay mindful, and enjoy your journey with Emote.",
                        style: _bodyTextStyle(context),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: const Color(0xFF1F1F1F), // Darker, neutral shadow
      skipWidget: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, color: Colors.white),
      ),
      paddingFocus: 10,
      opacityShadow: 0.85, // Higher contrast
      onFinish: () => prefs.setBool(_prefKey, true),
      onSkip: () {
        prefs.setBool(_prefKey, true);
        return true;
      },
    ).show(context: context);
  }

  static TextStyle _titleTextStyle(BuildContext context) {
    return const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 22,
      letterSpacing: 0.5,
    );
  }

  static TextStyle _bodyTextStyle(BuildContext context) {
    return const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5);
  }
}
