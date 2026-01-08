class DailyMessages {
  static final List<String> _messages = [
    "You are stronger than you think 💙",
    "Every feeling is valid, and you're doing great",
    "Take a deep breath. You've got this",
    "Your mental health matters, and so do you",
    "It's okay to not be okay sometimes",
    "Small steps are still progress",
    "You're worthy of love and care",
    "Be gentle with yourself today",
    "Your feelings are temporary, but you are resilient",
    "Today is a new opportunity to heal",
    "You are enough, just as you are",
    "Embrace your emotions with compassion",
    "Every day is a fresh start",
    "Your story matters, and so does your voice",
    "You're braver than you believe",
    "Take time to nurture your soul",
    "You deserve peace and happiness",
    "Progress, not perfection",
    "Your emotions don't define you",
    "You're doing better than you think",
    "Be proud of how far you've come",
    "Today, choose kindness for yourself",
    "You are not alone in this journey",
    "Your feelings are heard and valued",
    "Healing isn't linear, and that's okay",
    "You are creating your own sunshine",
    "Trust the process of your growth",
    "You're making a difference by showing up",
    "Your mental wellness is a priority",
    "Celebrate the small victories today",
    "You have the power to create change",
  ];

  /// Gets the message for today based on day of year
  /// This ensures the same message appears throughout the day
  static String getMessageOfTheDay() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final index = dayOfYear % _messages.length;
    return _messages[index];
  }
}
