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
    return moodLabels.entries
        .firstWhere(
          (entry) => entry.value.toLowerCase() == label.toLowerCase(),
          orElse: () => const MapEntry(3, 'Okay'),
        )
        .key;
  }
}
