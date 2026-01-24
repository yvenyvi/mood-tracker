import 'package:flutter/material.dart';
import 'dart:math';

class MoodAssets {
  static const String _baseUrl =
      'https://fonts.gstatic.com/s/e/notoemoji/latest';

  static const Map<int, String> moodLottieUrls = {
    1: '$_baseUrl/1f621/lottie.json', // Terrible (Rage)
    2: '$_baseUrl/1f61e/lottie.json', // Bad (Sad)
    3: '$_baseUrl/1f610/lottie.json', // Okay (Neutral)
    4: '$_baseUrl/1f642/lottie.json', // Good (Slightly Happy)
    5: '$_baseUrl/1f929/lottie.json', // Great (Star-struck)
  };

  static const Map<String, String> categoryLottieUrls = {
    'Happy': '$_baseUrl/1f60a/lottie.json', // Smiling Face with Smiling Eyes
    'Sad': '$_baseUrl/1f622/lottie.json', // Crying Face
    'Neutral': '$_baseUrl/1f610/lottie.json', // Neutral Face
    'Angry': '$_baseUrl/1f621/lottie.json', // Pouting Face
    'Anxious':
        '$_baseUrl/1f630/lottie.json', // Face with Open Mouth and Cold Sweat
    'Stress': '$_baseUrl/1f92f/lottie.json', // Exploding Head
    'Excited': '$_baseUrl/1f929/lottie.json', // Star-Struck
    'Tired': '$_baseUrl/1f634/lottie.json', // Sleeping Face
    'I Don\'t Know': '$_baseUrl/1f914/lottie.json', // Thinking Face
  };

  static const Map<int, String> moodLabels = {
    1: 'Terrible',
    2: 'Bad',
    3: 'Okay',
    4: 'Good',
    5: 'Great',
  };

  static String getUrl(int intensity) {
    return moodLottieUrls[intensity] ?? moodLottieUrls[3]!;
  }

  static String getCategoryUrl(String category) {
    return categoryLottieUrls[category] ?? moodLottieUrls[3]!;
  }

  static int getIntensity(String label) {
    switch (label) {
      case 'Happy':
      case 'Excited':
      case 'Great': // Legacy
      case 'Good': // Legacy
        return 5;
      case 'Neutral':
      case 'Okay': // Legacy
        return 3;
      case 'Tired':
        return 2;
      case 'Sad':
      case 'Angry':
      case 'Anxious':
      case 'Stress':
      case 'Bad': // Legacy
      case 'Terrible': // Legacy
        return 1;
      case 'I Don\'t Know':
        return 0; // Distinct intensity for "Delayed Understanding"
      default:
        return 3;
    }
  }

  static const List<String> categories = [
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

  static const Map<String, List<String>> emotions = {
    'Happy': ['Joy', 'Content', 'Gratitude'],
    'Sad': ['Low mood', 'Loneliness', 'Grief'],
    'Neutral': ['Calm', 'OK', 'Emotionally flat'],
    'Angry': ['Irritation', 'Frustration', 'Rage'],
    'Anxious': ['Worry', 'Nervousness', 'Fear'],
    'Stress': ['Pressure', 'Burnout'],
    'Excited': ['Anticipation', 'Motivation', 'Enthusiasm'],
    'Tired': [
      'Emotional exhaustion',
      'Mental exhaustion',
      'Physical exhaustion',
    ],
    'I Don\'t Know': [], // No specific emotions for this state
  };

  static const Map<String, Color> _moodColors = {
    'Happy': Colors.amber,
    'Sad': Color(0xFF42A5F5), // Blue 400
    'Neutral': Colors.grey,
    'Bad': Color(0xFF42A5F5), // Blue 400 (Legacy)
    'Okay': Colors.grey, // (Legacy)
    'Angry': Color(0xFFEF5350), // Red 400
    'Terrible': Color(0xFFEF5350), // Red 400 (Legacy)
    'Anxious': Color(0xFFAB47BC), // Purple 400
    'Stress': Color(0xFFFF7043), // Orange 400
    'Excited': Color(0xFF26A69A), // Teal 400
    'Great': Color(0xFF26A69A), // Teal 400 (Legacy)
    'Tired': Color(0xFF78909C), // Blue Grey 400
    'I Don\'t Know': Color(0xFF5C6BC0), // Indigo 400
  };

  static Color getMoodColor(String category) {
    // Try direction match first, then case-insensitive
    if (_moodColors.containsKey(category)) {
      return _moodColors[category]!;
    }

    // Capitalize first letter to match keys just in case
    final capitalized = category.isNotEmpty
        ? '${category[0].toUpperCase()}${category.substring(1).toLowerCase()}'
        : category;

    return _moodColors[capitalized] ?? Colors.grey;
  }

  static String getAdaptivePrompt(String mood) {
    final random = Random();
    List<String> prompts;

    switch (mood) {
      case 'Happy':
      case 'Excited':
      case 'Great':
        prompts = [
          "What went well today?",
          "What made you smile recently?",
          "Who are you grateful for right now?",
        ];
        break;
      case 'Sad':
      case 'Bad':
        prompts = [
          "What's weighing on your mind?",
          "How can you be gentle with yourself today?",
          "What do you need most right now?",
        ];
        break;
      case 'Angry':
      case 'Frustrated':
        prompts = [
          "What made you feel this way?",
          "How does this anger feel in your body?",
          "What boundary was crossed?",
        ];
        break;
      case 'Anxious':
      case 'Worry':
        prompts = [
          "What would you tell a friend who felt this way?",
          "What is one small thing you can control?",
          "What evidence do you have against this fear?",
        ];
        break;
      case 'Stress':
        prompts = [
          "What can you do to be kind to yourself right now?",
          "What can you delegate or let go of?",
          "Take a deep breath. What's the next small step?",
        ];
        break;
      case 'Tired':
        prompts = [
          "What is draining your energy?",
          "How can you prioritize rest today?",
          "What does your body need right now?",
        ];
        break;
      case 'I Don\'t Know':
        prompts = [
          "Whatever you're feeling is valid. Be patient with yourself.",
          "Describe your physical sensations if you can't name the emotion.",
          "It's okay not to know. Just be here.",
        ];
        break;
      case 'Neutral':
      default:
        prompts = [
          "What's on your mind?",
          "How was your day so far?",
          "Anything you want to get off your chest?",
        ];
        break;
    }

    return prompts[random.nextInt(prompts.length)];
  }

  static const Map<String, String> offlineEmojis = {
    'Happy': '😊',
    'Sad': '😢',
    'Neutral': '😐',
    'Angry': '😡',
    'Anxious': '😰',
    'Stress': '🤯',
    'Excited': '🤩',
    'Tired': '😴',
    'I Don\'t Know': '🤔',
  };

  static String getFallbackEmoji(String category) {
    // Capitalize first letter to match keys
    final capitalized = category.isNotEmpty
        ? '${category[0].toUpperCase()}${category.substring(1).toLowerCase()}'
        : category;
    return offlineEmojis[capitalized] ?? '😐';
  }
}
