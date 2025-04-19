import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import '../providers/swear_provider.dart';
import '../services/speech_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FlutterBackgroundService _backgroundService = FlutterBackgroundService();
  final SpeechService _speechService = SpeechService();

  @override
  void initState() {
    super.initState();
    _setupBackgroundService();
    _startContinuousListening();
  }

  void _setupBackgroundService() {
    _backgroundService.on('transcript').listen((event) {
      if (event != null && mounted) {
        print("Received transcript from background: ${event['text']}");
        context.read<SwearProvider>().checkSpeech(event['text']);
      }
    });
  }

  void _processRecognizedText(String text) {
    if (text.isNotEmpty && mounted) {
      print("Processing text: $text");
      context.read<SwearProvider>().checkSpeech(text);
    }
  }

  // Start listening automatically and continuously
  Future<void> _startContinuousListening() async {
    // Start with fresh initialization
    await _speechService.reset();
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Start listening with a fresh instance
    await _speechService.startListening(_processRecognizedText);
    
    // Set up a periodic restart to ensure continuous operation
    _setupPeriodicRestart();
  }
  
  void _setupPeriodicRestart() {
    // Every 5 minutes, restart the speech service to ensure it continues working
    Future.delayed(const Duration(minutes: 5), () async {
      if (mounted) {
        print("Periodic restart of speech service");
        await _speechService.reset();
        await Future.delayed(const Duration(milliseconds: 500));
        await _speechService.startListening(_processRecognizedText);
        _setupPeriodicRestart(); // Set up the next restart
      }
    });
  }

  @override
  void dispose() {
    _speechService.reset();
    super.dispose();
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
              // Record button removed
            ],
          ),
        ),
      ),
    );
  }
}