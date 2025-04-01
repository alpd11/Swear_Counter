import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  Function(String)? onResult;

  Future<void> initialize(Function(String) callback) async {
  _isInitialized = await _speech.initialize(
    onStatus: (status) => print("🎙️ Speech status: $status"),
    onError: (error) => print("❌ Speech error: $error"),
  );

  if (_isInitialized) {
    onResult = callback;
    print("✅ Speech service initialized");
  } else {
    print("❌ Speech service failed to initialize");
  }
}

  void startListening(Function(String) callback) {
    if (_isInitialized) {
      _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            callback(result.recognizedWords);
          }
        },
      );
    } else {
      print("❌ Cannot listen, speech service not initialized.");
    }
  }

  void stopListening() {
    if (_isInitialized) {
      _speech.stop();
    }
  }
}

