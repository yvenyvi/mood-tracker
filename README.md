# Emote — Your Safe Space 🌿

Emote is a personal mood tracking app built with Flutter. It gives you a private, judgment-free place to check in with how you are feeling every day. You can log your emotions, write personal notes, track your mood history on a calendar, and see detailed analytics about your emotional patterns over time. Everything is securely stored in the cloud and protected with biometric authentication so only you can access your data.

This project was made by a third year National University student as a requirement to pass the subject Elective 2: Advanced Mobile Programming.

---

## What the App Does

### Daily Mood Check-In
Every day, you can open the app and log how you are feeling. You pick your mood using animated emoji icons that represent a range of emotional states — from Happy and Joyful to Tired, Anxious, or Sad. You can also set an intensity score from 1 to 10 to describe how strongly you feel that emotion.

### Mood Journal Notes
When logging a mood, you can attach a personal text note to describe what happened or what is on your mind. These notes are completely private and only visible to you.

### Emotion Tags
Beyond the main mood, you can tag specific emotions that are part of what you are feeling — things like Calm, Excited, Grateful, Overwhelmed, and more. This helps you be more specific about your emotional state.

### Coping Strategies
You can log which coping strategies you used during the day, such as exercising, meditating, journaling, talking to a friend, or listening to music. This helps you track what actually makes you feel better over time.

### Physical Symptoms Tracking
The app lets you record any physical symptoms you noticed alongside your mood, such as feeling energetic, having low energy, headaches, or poor sleep. This helps you notice patterns between how your body feels and your emotional state.

### Calendar View
Your mood history is displayed on a monthly calendar. Each day you logged a mood entry gets highlighted, so you can quickly see which days you checked in and tap on any day to review what you recorded.

### Mood Analytics
The Analytics screen gives you a visual breakdown of your mood data. You can see which moods you logged most frequently, your average mood intensity over time, and trends across the week or month. This helps you understand your emotional patterns at a glance.

### Biometric Security
Your mood data is personal. The app uses biometric authentication — either Face ID or Fingerprint — to lock the app so nobody else can open it and read your entries.

### Dark Mode
The entire app is designed with a sleek dark theme that is easy on the eyes, especially at night when you are doing your evening check-in.

### Cloud Sync with Firebase
All your mood entries are automatically saved to Firebase Firestore in the cloud. This means your data is safe even if you change devices, and it syncs securely to your account in real time.

### Google Sign-In
You can log into the app using your Google account for a fast, secure, and passwordless sign-in experience.

---

## Tech Stack

- **Framework**: Flutter (Dart)
- **Backend / Database**: Firebase Firestore
- **Authentication**: Firebase Auth with Google Sign-In
- **State Management**: Provider
- **Animations**: Lottie
- **Charts and Analytics**: FL Chart
- **Biometric Security**: Local Auth
- **Landing Page**: HTML + Tailwind CSS, deployed on Vercel

---

## Landing Page

The project includes a web landing page that explains the app, shows a real screenshot, and lets people download the APK directly.

- **Live Site**: [https://emote-flax.vercel.app](https://emote-flax.vercel.app)
- **GitHub Repo**: [https://github.com/yvenyvi/mood-tracker](https://github.com/yvenyvi/mood-tracker)

---

## Getting Started

### Prerequisites

- Flutter SDK installed
- Android Studio or VS Code with Flutter extension
- A Firebase project with `google-services.json` placed in `android/app/`

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yvenyvi/mood-tracker.git
   cd mood-tracker
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app on a connected device or emulator:
   ```bash
   flutter run
   ```

### Build Release APK

```bash
flutter build apk --release
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

---

## License

This project is licensed under the MIT License.
