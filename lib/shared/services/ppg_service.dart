import 'dart:async';
import 'package:flutter/services.dart';

class PPGService {
  static const MethodChannel _channel = MethodChannel('com.example.health_tracker/ppg');
  static const EventChannel _eventChannel = EventChannel('com.example.health_tracker/ppg_events');
  
  StreamSubscription? _subscription;
  
  Stream<Map<String, dynamic>>? _ppgStream;
  
  Stream<Map<String, dynamic>> get ppgStream {
    _ppgStream ??= _eventChannel.receiveBroadcastStream().map((event) => Map<String, dynamic>.from(event));
    return _ppgStream!;
  }
  
  Future<bool> startPPG() async {
    try {
      final result = await _channel.invokeMethod<bool>('startPPG');
      return result ?? false;
    } catch (e) {
      print('PPG start error: $e');
      return false;
    }
  }
  
  Future<bool> stopPPG() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopPPG');
      return result ?? false;
    } catch (e) {
      print('PPG stop error: $e');
      return false;
    }
  }
  
  Future<bool> isRunning() async {
    try {
      final result = await _channel.invokeMethod<bool>('isPPGRunning');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
  
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}