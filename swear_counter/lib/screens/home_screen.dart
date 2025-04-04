import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import '../providers/swear_provider.dart';
import '../widgets/record_button.dart';
import '../widgets/swear_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isListening = false;
  final FlutterBackgroundService _backgroundService = FlutterBackgroundService();

  @override
  void initState() {
    super.initState();
    _setupBackgroundService();
  }

  void _setupBackgroundService() {
    _backgroundService.on('keepForeground').listen((event) {
      if (_backgroundService is AndroidServiceInstance) {
        (_backgroundService as AndroidServiceInstance).setForegroundNotificationInfo(
          title: 'Swear Counter',
          content: 'Listening for swears...',
        );
      }
    });

    _backgroundService.on('transcript').listen((event) {
      if (event != null) {
        context.read<SwearProvider>().checkSpeech(event['text']);
      }
    });
  }

  void toggleListening() {
    setState(() => isListening = !isListening);

    if (isListening) {
      _backgroundService.invoke('keepForeground');
    } else {
      _backgroundService.invoke('stopService');
    }
  }

  @override
  Widget build(BuildContext context) {
    final swearCount = context.watch<SwearProvider>().swearCount;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Swear Counter",
          style: GoogleFonts.poppins(
            textStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Reset Counter',
            onPressed: () => context.read<SwearProvider>().resetCounter(),
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2B5876),
              Color(0xFF4E4376),
              Color(0xFFFA709A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        swearCount.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 72,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Swears Detected",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: RecordButton(
                  isListening: isListening,
                  onPressed: toggleListening,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}