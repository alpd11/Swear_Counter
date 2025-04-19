import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_background_service_ios/flutter_background_service_ios.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:provider/provider.dart';
import '../providers/swear_provider.dart';

class BackgroundService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: true,
        foregroundServiceNotificationId: 888,
        initialNotificationTitle: 'Swear Counter',
        initialNotificationContent: 'Listening for swears...',
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  static Future<bool> onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    return true;
  }

  static void onStart(ServiceInstance service) async {
    if (service is AndroidServiceInstance) {
      service.on('stopService').listen((event) {
        service.stopSelf();
      });
    }

    service.on('keepForeground').listen((event) {
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'Swear Counter',
          content: 'Listening for swears...',
        );
      }
    });

    // Create a new speech recognition instance
    final SpeechToText speech = SpeechToText();
    bool isListening = false;
    bool needsReinit = true;
    DateTime lastRecognitionTime = DateTime.now();

    while (true) {
      try {
        // Check if we need to initialize or reinitialize
        if (needsReinit) {
          print('Initializing speech recognition service...');
          
          // Make sure any previous session is stopped
          try {
            if (isListening) {
              await speech.stop();
              isListening = false;
              // Give the system time to release resources
              await Future.delayed(const Duration(milliseconds: 500));
            }
          } catch (e) {
            print('Error stopping previous session: $e');
          }
          
          final available = await speech.initialize(
            onError: (error) => print('Speech recognition error: $error'),
            onStatus: (status) {
              print('Speech recognition status: $status');
              if (status == 'done' || status == 'notListening') {
                isListening = false;
              } else if (status == 'listening') {
                isListening = true;
                lastRecognitionTime = DateTime.now();
              }
            },
          );

          if (available) {
            print('Speech recognition initialized successfully');
            needsReinit = false;
          } else {
            print('Speech recognition not available, will retry...');
            await Future.delayed(const Duration(seconds: 3));
            continue;
          }
        }

        // Check if we're currently listening
        if (isListening) {
          // Check for timeout - if it's been too long, force a reset
          if (DateTime.now().difference(lastRecognitionTime).inSeconds > 60) {
            print('Speech recognition seems stuck, resetting...');
            try {
              await speech.stop();
            } catch (e) {
              print('Error stopping stuck session: $e');
            }
            isListening = false;
            needsReinit = true;
            await Future.delayed(const Duration(seconds: 1));
            continue;
          }
          
          // Still actively listening, wait a bit
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        }

        print('Starting to listen...');
        try {
          final bool started = await speech.listen(
            onResult: (result) {
              print('Speech recognition result: ${result.recognizedWords}');
              if (result.finalResult && result.recognizedWords.isNotEmpty) {
                print('Final result detected, sending to service...');
                service.invoke(
                  'transcript',
                  {'text': result.recognizedWords},
                );
                // Update timestamp after receiving a result
                lastRecognitionTime = DateTime.now();
              }
            },
            listenFor: const Duration(seconds: 30),
            pauseFor: const Duration(seconds: 3),
            partialResults: true,
            listenMode: ListenMode.confirmation,
            cancelOnError: false,
          );
          
          if (!started) {
            print('Failed to start listening, will reinitialize');
            needsReinit = true;
          } else {
            print('Listening started successfully');
            lastRecognitionTime = DateTime.now();
          }
        } catch (e) {
          print('Error during speech recognition: $e');
          isListening = false;
          needsReinit = true;
        }
      } catch (e) {
        print('Unexpected error in background service: $e');
        needsReinit = true;
      }
      
      // Add a delay before starting the next listening session
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}

// Global key for accessing context in background
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();