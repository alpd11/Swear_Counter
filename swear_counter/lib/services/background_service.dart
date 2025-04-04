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

    final speech = SpeechToText();
    final available = await speech.initialize(
      onError: (error) => print('Speech recognition error: $error'),
      onStatus: (status) => print('Speech recognition status: $status'),
    );

    if (!available) {
      print('Speech recognition not available');
      return;
    }

    print('Speech recognition initialized successfully');

    while (true) {
      print('Starting to listen...');
      await speech.listen(
        onResult: (result) {
          print('Speech recognition result: ${result.recognizedWords}');
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            print('Final result detected, sending to service...');
            service.invoke(
              'transcript',
              {'text': result.recognizedWords},
            );
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        listenMode: ListenMode.confirmation,
      );
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}

// Global key for accessing context in background
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>(); 