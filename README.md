Sure! Here is a README file for your Swear Counter application:

---

# Swear Counter

Swear Counter is a Flutter application that helps users track and manage their swearing habits. It features user authentication, friend management, real-time and Firestore database integration, and a modern UI.

## Features

- User authentication with Firebase Auth (email, Google, etc.)
- Track your swear count and view statistics
- Add, remove, and manage friends
- Send and receive friend requests
- Real-time updates using Firebase Realtime Database and Firestore
- Profile management (including avatar upload)
- Debug and admin tools for database management
- Responsive UI for mobile and desktop

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Firebase Project](https://console.firebase.google.com/)
- [Dart SDK](https://dart.dev/get-dart)
- Android Studio, VS Code, or another IDE

### Setup

1. **Clone the repository:**
   ```
   git clone <your-repo-url>
   cd swear_counter
   ```

2. **Install dependencies:**
   ```
   flutter pub get
   ```

3. **Configure Firebase:**
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the appropriate directories.
   - Make sure your Firebase project has Authentication, Firestore, and Realtime Database enabled.

4. **Run the app:**
   ```
   flutter run
   ```

### Folder Structure

- `lib/` - Main Dart code (UI, services, models)
- `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/` - Platform-specific code
- pubspec.yaml - Project dependencies

### Main Packages Used

- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `firebase_database`
- `firebase_storage`
- `google_sign_in`
- `provider`
- `shared_preferences`
- `speech_to_text`
- `google_fonts`
- `fl_chart`
- `image_picker`

## Usage

- Sign up or log in with your email or Google account.
- Track your swearing by incrementing your count.
- Add friends by searching for their email or username.
- Accept or decline friend requests.
- View your and your friends' swear statistics.

## Debug Tools

- Access debug tools from the settings screen to force-create users or collections, and check database status.

## Contributing

Pull requests are welcome! For major changes, please open an issue first to discuss what you would like to change.

## License

This project is for educational purposes.

---

For more information, see the [Flutter documentation](https://flutter.dev/docs).
