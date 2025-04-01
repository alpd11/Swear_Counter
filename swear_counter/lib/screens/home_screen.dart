// 🌈 FINAL POLISH: SPOTIFY-INSPIRED UI WITH GORGEOUS TYPOGRAPHY

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/swear_provider.dart';
import '../services/speech_service.dart';
import '../widgets/record_button.dart';
import '../widgets/swear_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SpeechService _speechService = SpeechService();
  bool isListening = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _speechService.initialize((text) {
      context.read<SwearProvider>().checkSpeech(text);
    }).then((_) {
      setState(() => _ready = true);
    });
  }

  void toggleListening() {
    if (!_ready) {
      print("⚠️ Speech service not ready yet.");
      return;
    }

    setState(() => isListening = !isListening);

    if (isListening) {
      _speechService.startListening((text) {
        context.read<SwearProvider>().checkSpeech(text);
      });
    } else {
      _speechService.stopListening();
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                Text(
                  "Detected Swear Words",
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      fontSize: 20,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB347), Color(0xFFFF416C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Text(
                    "$swearCount",
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        fontSize: 50,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                RecordButton(
                  isListening: isListening,
                  onPressed: toggleListening,
                ),
                const SizedBox(height: 20),
                Text(
                  _ready ? "Say something... and let's see 👀" : "Loading speech service...",
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(fontSize: 16, color: Colors.white60),
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(child: SwearChart(swearCount: swearCount)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}