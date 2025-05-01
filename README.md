# 🤬 Swear Counter  
A Smart, Social, AI-Powered Language Awareness App  
![Flutter](https://img.shields.io/badge/Built%20with-Flutter-blue.svg) ![Firebase](https://img.shields.io/badge/Backend-Firebase-orange.svg) ![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android%20%7C%20Web-green.svg)

---

## 📱 About the App

**Swear Counter** is a cross-platform mobile application that helps users track and reduce their swearing habits. Built using Flutter and integrated with Firebase and LLM-based speech processing, the app detects swears from audio input and provides insightful stats.

Through real-time monitoring, progress tracking, and a friendly competitive environment, users can become more conscious of their language and build healthier habits—one word at a time.

---

## 🚀 Features

### ✅ Core Functionalities
- 🔐 **Firebase Authentication** (Email & Google)
- 🧠 **Real-time LLM-based Swear Detection** from speech input
- 📊 **Swear Statistics Dashboard** (daily, weekly, and total counts)
- 🧑‍🤝‍🧑 **Friends System**: Add, remove, view friend stats
- 🏆 **Leaderboard**: Rank yourself among your friends
- 👤 **User Profiles**: Upload avatars and personalize your experience
- 🛠️ **Admin Tools**: Debug users, collections, and monitor data flow
- 📱 **Responsive UI**: Optimized for both mobile and web

---

## 🧪 Try It Out

### ✨ Pages Overview

| Page | Description |
|------|-------------|
| **Home** | View your real-time swear count |
| **History** | Track historical data through charts |
| **Friends** | See friends' swear stats, send requests, and compare scores |
| **Settings** | Adjust preferences, manage profile, and access debug tools |

---

## 🛠️ Getting Started

### 🔧 Prerequisites
Make sure you have the following installed:
- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Dart SDK](https://dart.dev/get-dart)
- [Firebase Console Project](https://console.firebase.google.com/)
- IDE like VS Code or Android Studio

---

### ⚙️ Setup Instructions

1. **Clone the Repository**
   ```bash
   git clone https://github.com/alpd11/Swear_Counter.git
   cd swear_counter
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Add `google-services.json` (Android) under `android/app`
   - Add `GoogleService-Info.plist` (iOS) under `ios/Runner`
   - Ensure Firebase Authentication, Firestore, and Realtime Database are enabled

4. **Run the App**
   ```bash
   flutter run
   ```

---

## 📁 Project Structure

```
lib/
 ├── main.dart               # App entry point
 ├── pages/                  # Home, History, Friends, Settings
 ├── services/               # Firebase, Auth, Speech-to-text, etc.
 ├── models/                 # Data structures for users, swears, etc.
 ├── widgets/                # Reusable UI components
pubspec.yaml                 # Dependencies
```

---

## 📦 Packages & Plugins

| Category | Package |
|---------|---------|
| Firebase | `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_database`, `firebase_storage` |
| Auth & UI | `google_sign_in`, `provider`, `shared_preferences` |
| Speech & Analytics | `speech_to_text`, `fl_chart` |
| UI Enhancements | `google_fonts`, `image_picker` |

---

## 🧪 Debug Tools

You can access development tools in the **Settings** page:
- ✅ Force-create users/collections
- 🔍 View Firestore & Realtime DB status
- 🛠 Manually trigger LLM for testing

---

## 🤝 Contributing

We welcome contributions!  
Please fork the repo and submit a pull request with a clear description of your changes. For major features or bugs, open an issue first to discuss the proposal.

---

## 📄 License

This project is for educational use only.
