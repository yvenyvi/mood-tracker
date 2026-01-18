# Emote - Mood Tracker 🎭

A beautiful and personal mood tracking application built with Flutter. Track your emotions, analyze trends, and keep your journals private with biometric security.

## Features ✨

- **Mood Logging**: Log your daily mood using expressive, animated emojis (powered by Lottie).
- **Detailed Analytics**: Visualize your mood trends over time with interactive charts.
- **Calendar View**: See your mood history at a glance on a monthly calendar.
- **Journaling**: Add personal notes to every mood entry.
- **Biometric Lock**: Secure your personal data with FaceID or Fingerprint authentication.
- **Dark & Light Mode**: Seamless theme switching to match your preference.
- **Cloud Sync**: All data is securely backed up to Firebase Firestore.

## Tech Stack 🛠️

- **Framework**: Flutter
- **Backend**: Firebase (Authentication, Firestore)
- **State Management**: Provider
- **Animations**: Lottie
- **Charts**: FL Chart
- **Security**: Local Auth (Biometrics)

## Getting Started 🚀

### Prerequisites

- Flutter SDK
- Android Studio / Xcode (for iOS)
- A Firebase project configured (with `google-services.json` for Android)

### Installation

1.  **Clone the repository**

    ```bash
    git clone https://github.com/yvenyvi/mood-tracker.git
    cd mood-tracker
    ```

2.  **Install dependencies**

    ```bash
    flutter pub get
    ```

3.  **Run the app**
    ```bash
    flutter run
    ```

## Building for Release 📦

### Android

To build the release APK:

```bash
flutter build apk --release
```

The output file will be located at `build/app/outputs/flutter-apk/app-release.apk`.

## License 📄

This project is licensed under the MIT License.
