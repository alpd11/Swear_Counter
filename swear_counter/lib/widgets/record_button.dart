import 'package:flutter/material.dart';

class RecordButton extends StatelessWidget {
  final bool isListening;
  final VoidCallback onPressed;

  const RecordButton({
    super.key,
    required this.isListening,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        backgroundColor: isListening ? Colors.red : Colors.green,
      ),
      icon: Icon(isListening ? Icons.stop : Icons.mic),
      label: Text(isListening ? 'Stop Listening' : 'Start Listening'),
      onPressed: onPressed,
    );
  }
}
