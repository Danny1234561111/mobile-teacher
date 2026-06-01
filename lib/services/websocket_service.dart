import 'dart:async';
import 'dart:convert';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter/services.dart';
import 'auth_service.dart';

class WebSocketService {
  static WebSocketChannel? _channel;
  static bool _isConnected = false;
  static String? _currentToken;
  static int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static Timer? _heartbeatTimer;
  static Timer? _reconnectTimer;
  static bool _isReconnecting = false;
  static bool _isBackgroundRunning = false;
  
  static final MethodChannel _backgroundChannel = MethodChannel('com.example.student_registration/contact');

  static bool get isConnected => _isConnected;

  static Future<void> connect(String token) async {
    if (_isConnected) {
      print('WebSocket already connected');
      return;
    }
    
    _currentToken = token;
    final String wsUrl = 'ws://158.160.67.3:8000/ws/mobile/$token';
    print('Connecting to WebSocket: $wsUrl');
    
    try {
      _channel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        pingInterval: const Duration(seconds: 10),
      );
      
      _channel!.stream.listen((message) {
        _reconnectAttempts = 0;
        _isReconnecting = false;
        print('Received command: $message');
        _handleCommand(message);
      }, onDone: () {
        print('WebSocket connection closed');
        _isConnected = false;
        _stopHeartbeat();
        if (_isBackgroundRunning) {
          _attemptReconnect();
        }
      }, onError: (error) {
        print('WebSocket error: $error');
        _isConnected = false;
        _stopHeartbeat();
        if (_isBackgroundRunning) {
          _attemptReconnect();
        }
      });
      
      _isConnected = true;
      _reconnectAttempts = 0;
      print('WebSocket connected');
      _startHeartbeat();
      
    } catch (e) {
      print('WebSocket connection error: $e');
      _isConnected = false;
      if (_isBackgroundRunning) {
        _attemptReconnect();
      }
    }
  }

  static void _handleCommand(dynamic message) {
    try {
      final Map<String, dynamic> command = (message is String)
          ? jsonDecode(message)
          : message as Map<String, dynamic>;
      
      final type = command['type'];
      print('Executing command: $type');
      
      switch (type) {
        case 'connected':
          print('Connected to server');
          break;
          
        case 'pong':
          print('Pong received from server');
          break;
          
        case 'make_call':
          final phoneNumber = command['phone_number'] ?? '';
          final studentName = command['student_name'] ?? '';
          print('Call: $studentName ($phoneNumber)');
          _makeBackgroundCall(phoneNumber);
          break;
          
        case 'send_sms':
          final phoneNumber = command['phone_number'] ?? '';
          final messageText = command['message_text'] ?? '';
          final studentName = command['student_name'] ?? '';
          print('SMS: $studentName ($phoneNumber)');
          _sendBackgroundSms(phoneNumber, messageText);
          break;
          
        case 'open_telegram':
          final telegramContact = command['telegram_contact'] ?? '';
          final studentName = command['student_name'] ?? '';
          print('Telegram: $studentName (@$telegramContact)');
          _openBackgroundTelegram(telegramContact);
          break;
          
        case 'open_vk':
          final vkContact = command['vk_contact'] ?? '';
          final studentName = command['student_name'] ?? '';
          print('VK: $studentName ($vkContact)');
          _openBackgroundVK(vkContact);
          break;
          
        case 'open_url':
          final url = command['url'] ?? '';
          final studentName = command['student_name'] ?? '';
          print('Open URL: $studentName - $url');
          _openBackgroundUrl(url);
          break;
          
        case 'ping':
          print('Ping received, sending pong');
          _sendPong();
          break;
          
        default:
          print('Unknown command: $type');
      }
    } catch (e) {
      print('Command handling error: $e');
    }
  }

  static Future<void> _makeBackgroundCall(String phoneNumber) async {
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final callChannel = MethodChannel('calls');
      final result = await callChannel.invokeMethod('makeCall', {
        'phoneNumber': cleanNumber,
      });
      if (result == true) {
        print('Background call completed');
      }
    } catch (e) {
      print('Background call error: $e');
    }
  }

  static Future<void> _sendBackgroundSms(String phoneNumber, String message) async {
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final result = await _backgroundChannel.invokeMethod('sendSms', {
        'phoneNumber': cleanNumber,
        'message': message,
      });
      if (result == true) {
        print('Background SMS sent');
      }
    } catch (e) {
      print('Background SMS error: $e');
    }
  }

  static Future<void> _openBackgroundTelegram(String contact) async {
    try {
      String username = contact.trim().replaceFirst('@', '');
      username = username.replaceFirst(RegExp(r'^https?://(t\.me/|telegram\.me/)'), '');
      username = username.replaceFirst(RegExp(r'^t\.me/'), '');
      
      final result = await _backgroundChannel.invokeMethod('openTelegram', {
        'username': username,
      });
      if (result == true) {
        print('Background Telegram opened');
      }
    } catch (e) {
      print('Background Telegram error: $e');
    }
  }

  static Future<void> _openBackgroundVK(String contact) async {
    try {
      String vkId = contact;
      if (contact.contains('vk.com/')) {
        vkId = contact.split('vk.com/').last;
        vkId = vkId.split('?').first;
        vkId = vkId.split('#').first;
      }
      vkId = vkId.replaceAll('/', '');
      
      final result = await _backgroundChannel.invokeMethod('openVK', {
        'vkId': vkId,
      });
      if (result == true) {
        print('Background VK opened');
      }
    } catch (e) {
      print('Background VK error: $e');
    }
  }

  static Future<void> _openBackgroundUrl(String url) async {
    try {
      String finalUrl = url.trim();
      if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
        finalUrl = 'https://$finalUrl';
      }
      
      final result = await _backgroundChannel.invokeMethod('openUrl', {
        'url': finalUrl,
      });
      if (result == true) {
        print('Background URL opened');
      }
    } catch (e) {
      print('Background URL error: $e');
    }
  }

  static void _sendPong() {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode({'type': 'pong'}));
      print('Pong sent');
    }
  }

  static void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (timer) {
      if (_isConnected && _channel != null) {
        try {
          _channel!.sink.add(jsonEncode({'type': 'heartbeat'}));
          print('Heartbeat sent');
        } catch (e) {
          print('Heartbeat send error: $e');
        }
      }
    });
  }

  static void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  static void _attemptReconnect() {
    if (_isReconnecting) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('Max reconnect attempts reached');
      _reconnectAttempts = 0;
      return;
    }
    
    _isReconnecting = true;
    _reconnectAttempts++;
    final delay = _reconnectAttempts * 2;
    
    print('Reconnecting $_reconnectAttempts/$_maxReconnectAttempts in ${delay}s');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delay), () async {
      if (!_isConnected && _currentToken != null) {
        _isReconnecting = false;
        await connect(_currentToken!);
      } else {
        _isReconnecting = false;
      }
    });
  }

  static void disconnect() {
    print('Disconnecting WebSocket');
    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    _currentToken = null;
    _reconnectAttempts = 0;
    _isReconnecting = false;
  }

  static void stopBackgroundService() {
    print('Stopping background service...');
    disconnect();
    final service = FlutterBackgroundService();
    service.invoke('stopService');
    _isBackgroundRunning = false;
    print('Background service stopped');
  }

  static Future<void> initBackgroundService() async {
    print('Initializing background service...');
    
    final service = FlutterBackgroundService();
    
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onBackgroundStart,
        autoStart: true,
        isForegroundMode: false,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onBackgroundStart,
      ),
    );
    
    await service.startService();
    print("Background service initialized and started");
  }
}

@pragma('vm:entry-point')
void onBackgroundStart(ServiceInstance service) async {
  print('Background service started');
  
  WebSocketService._isBackgroundRunning = true;
  
  final authService = AuthService();
  await Future.delayed(const Duration(seconds: 1));
  
  final token = await authService.getToken();
  if (token != null) {
    print('Connecting WebSocket');
    await WebSocketService.connect(token);
  }
  
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    if (!WebSocketService.isConnected) {
      print('WebSocket disconnected, reconnecting...');
      final newToken = await authService.getToken();
      if (newToken != null) {
        await WebSocketService.connect(newToken);
      }
    }
  });
  
  service.on('stopService').listen((event) {
    WebSocketService.disconnect();
    service.stopSelf();
  });
}