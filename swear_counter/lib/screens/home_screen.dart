import 'package:flutter/material.dart';
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
    appBar: AppBar(
      title: const Text("Swear Counter"),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Reset Counter',
          onPressed: () {
            context.read<SwearProvider>().resetCounter();
          },
        )
      ],
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Detected Swear Words", style: TextStyle(fontSize: 22)),
            const SizedBox(height: 20),
            Text("$swearCount", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 40),
            RecordButton(
              isListening: isListening,
              onPressed: toggleListening,
            ),
            const SizedBox(height: 20),
            const Text("Say something... and let's see 👀"),
            const SizedBox(height: 20),
            SwearChart(swearCount: swearCount),
          ],
        ),
      ),
    ),
  );
  }
}


