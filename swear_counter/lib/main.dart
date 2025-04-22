import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'providers/swear_provider.dart';
import 'screens/app_root.dart';
import 'screens/login_screen.dart';
import 'services/background_service.dart';
import 'services/firebase_service.dart'; // Added import for FirebaseService

// Add a global navigator key for use throughout the app
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize Firebase BEFORE using any Firebase service
  try {
    await Firebase.initializeApp();
    print("✅ Firebase initialized successfully");
    
    // Setup auth state listener to ensure all users are saved to Firestore
    final firebaseService = FirebaseService();
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        // Store or update user in Firestore whenever authentication state changes
        firebaseService.createUserIfNotExists(user);
      }
    });
    
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

  // Initialize background service
  await BackgroundService.initializeService();

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
      navigatorKey: navigatorKey,
      title: 'Swear Counter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: const Color(0xFF1E1E2C),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Poppins'),
      ),
      home: AuthGate(),
    );
  }
}

// Add a stream builder to listen to auth state changes
class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while connection state is active
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Check if the user is logged in
        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        } else {
          return const AppRoot();
        }
      },
    );
  }
}
