import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart'; // ✅ Firebase core import
import 'package:provider/provider.dart';
import 'providers/swear_provider.dart';
import 'screens/app_root.dart'; // ✅ Entry point with nav bar

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase BEFORE using any Firebase service
  try {
    await Firebase.initializeApp();
    print("✅ Firebase initialized successfully");
  } catch (e) {
    print("❌ Firebase initialization failed: $e");
  }

  // ✅ Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    print("✅ .env loaded successfully");
  } catch (e) {
    print("❌ Could not load .env: $e");
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SwearProvider()..loadSwearCount()),
      ],
      child: const SwearCounterApp(),
    ),
  );
}

class SwearCounterApp extends StatelessWidget {
  const SwearCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Swear Counter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.red),
      home: const AppRoot(), // ✅ Main navigation + animated screens
    );
  }
}
