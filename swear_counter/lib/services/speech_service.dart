import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  stt.SpeechToText? _speech;
  bool _isInitialized = false;
  bool _isListening = false;

  // Create a fresh instance each time to avoid any state issues
  stt.SpeechToText _createFreshInstance() {
    print("🔄 Creating fresh speech recognition instance");
    return stt.SpeechToText();
  }

  Future<void> initialize(Function(String) callback) async {
    // Always stop any current listening first
    await forceStop();
    
    // Always create a fresh instance
    _speech = _createFreshInstance();
    
    print("⚙️ Initializing speech recognition");
    _isInitialized = await _speech!.initialize(
      onStatus: (status) {
        print("🎙️ Speech status: $status");
        if (status == 'done' || status == 'notListening') {
          _isListening = false;
        } else if (status == 'listening') {
          _isListening = true;
        }
      },
      onError: (error) {
        print("❌ Speech error: $error");
        _isListening = false;
      },
    );

    if (_isInitialized) {
      print("✅ Speech service initialized successfully");
    } else {
      print("❌ Speech service failed to initialize");
    }
  }

  Future<bool> startListening(Function(String) callback) async {
    print("🎯 Start listening requested");
    
    // If not initialized or listening failed, initialize fresh
    if (_speech == null || !_isInitialized) {
      print("🔄 Speech not initialized, initializing first");
      await initialize(callback);
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    // Stop any previous listening session
    if (_isListening) {
      print("⚠️ Already listening, stopping first");
      await forceStop();
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Create a new instance after force stop
      _speech = _createFreshInstance();
      await initialize(callback);
    }

    if (_speech != null && _isInitialized) {
      print("🎙️ Starting speech recognition");
      try {
        final result = await _speech!.listen(
          onResult: (result) {
            if (result.finalResult) {
              print("📝 Final result: ${result.recognizedWords}");
              if (result.recognizedWords.isNotEmpty) {
                callback(result.recognizedWords);
              }
            }
          },
          listenFor: const Duration(seconds: 15), // Shortened to be more responsive
          pauseFor: const Duration(seconds: 2),
          partialResults: true,
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: false,
        );
        
        if (!result) {
          print("❌ Failed to start listening");
          _isListening = false;
          return false;
        } else {
          print("✅ Listening started successfully");
          return true;
        }
      } catch (e) {
        print("❌ Exception during speech recognition: $e");
        _isListening = false;
        return false;
      }
    } else {
      print("❌ Cannot listen, speech service not initialized");
      return false;
    }
  }

  Future<void> stopListening() async {
    print("⏹️ Attempting to stop listening");
    if (_speech != null && _isInitialized && _isListening) {
      try {
        await _speech!.stop();
        print("⏹️ Speech recognition stopped");
      } catch (e) {
        print("❌ Error stopping speech recognition: $e");
      } finally {
        _isListening = false;
      }
    }
  }
  
  Future<void> forceStop() async {
    print("🛑 Force stopping speech recognition");
    if (_speech != null) {
      try {
        if (_isListening) {
          await _speech!.stop();
        }
      } catch (e) {
        print("❌ Error during force stop: $e");
      } finally {
        _isListening = false;
        _isInitialized = false;
      }
    }
  }
  
  Future<void> reset() async {
    // Complete reset of service
    await forceStop();
    _speech = null;
    _isInitialized = false;
    _isListening = false;
    print("🔄 Speech service fully reset");
  }

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
}

