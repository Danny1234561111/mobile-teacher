import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/auth_service.dart';
import 'services/websocket_service.dart';
import 'pages/login_page.dart';
import 'pages/student_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Запрашиваем разрешения
  await _requestPermissions();
  
  // Запускаем приложение сначала
  runApp(const MyApp());
  
  // Инициализируем фоновый сервис после запуска UI
  Future.delayed(const Duration(seconds: 3), () async {
    try {
      print('🚀 Запуск фонового сервиса...');
      await WebSocketService.initBackgroundService();
      
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();
      print('📌 Фоновый сервис статус: ${isRunning ? "ЗАПУЩЕН" : "НЕ ЗАПУЩЕН"}');
      
      if (!isRunning) {
        print('🔄 Принудительный запуск фонового сервиса...');
        await service.startService();
      }
    } catch (e) {
      print('❌ Ошибка запуска фонового сервиса: $e');
    }
  });
}

// Запрос разрешений
Future<void> _requestPermissions() async {
  try {
    print('🔐 Запрос разрешений...');
    
    List<Permission> permissions = [
      Permission.phone,
      Permission.sms,
      Permission.contacts,
    ];
    
    // Для Android 10+ нужно специальное разрешение
    if (await Permission.systemAlertWindow.isRestricted) {
      permissions.add(Permission.systemAlertWindow);
    }
    
    Map<Permission, PermissionStatus> statuses = await permissions.request();
    
    bool allGranted = statuses.values.every((status) => status.isGranted);
    
    if (allGranted) {
      print('✅ Все разрешения получены');
    } else {
      print('⚠️ Некоторые разрешения не получены:');
      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          print('   - ${permission.toString()}: $status');
        }
      });
    }
  } catch (e) {
    print('❌ Ошибка запроса разрешений: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Мониторинг с задержкой
    Future.delayed(const Duration(seconds: 5), () {
      _monitorServiceStatus();
    });
  }
  
  void _monitorServiceStatus() async {
    try {
      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();
      print('🔍 [МОНИТОР] Фоновый сервис: ${isRunning ? "АКТИВЕН" : "НЕ АКТИВЕН"}');
      print('🔍 [МОНИТОР] WebSocket: ${WebSocketService.isConnected ? "ПОДКЛЮЧЕН" : "ОТКЛЮЧЕН"}');
    } catch (e) {
      print('❌ Ошибка мониторинга: $e');
    }
    
    // Повторяем проверку каждые 30 секунд
    Future.delayed(const Duration(seconds: 30), () => _monitorServiceStatus());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("🦋 Состояние приложения: $state");
    
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    } else if (state == AppLifecycleState.paused) {
      _onAppPaused();
    }
  }
  
  Future<void> _onAppResumed() async {
    print('☀️ Приложение на переднем плане');
    final authService = AuthService();
    final token = await authService.getToken();
    
    if (token != null && !WebSocketService.isConnected) {
      await WebSocketService.connect(token);
    }
    
    // Проверяем статус фонового сервиса
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    if (!isRunning) {
      print('⚠️ Фоновый сервис остановлен! Перезапускаем...');
      await WebSocketService.initBackgroundService();
    }
  }
  
  Future<void> _onAppPaused() async {
    print('🌙 Приложение в фоне');
    final service = FlutterBackgroundService();
    final isRunning = await service.isRunning();
    print('📌 Фоновый сервис при паузе: ${isRunning ? "АКТИВЕН" : "НЕ АКТИВЕН"}');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Управление студентами',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const InitialScreen(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/students': (context) => const StudentsListPage(),
      },
    );
  }
}

// InitialScreen
class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  _InitialScreenState createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  bool _isLoading = true;
  Widget? _initialPage;

  @override
  void initState() {
    super.initState();
    _determineInitialPage();
  }

  Future<void> _determineInitialPage() async {
    try {
      final authService = AuthService();
      
      final hasConnection = await authService.testConnection();
      if (!hasConnection) {
        print('⚠️ Нет соединения с сервером');
        if (mounted) {
          setState(() {
            _initialPage = const LoginPage();
            _isLoading = false;
          });
        }
        return;
      }

      final isLoggedIn = await authService.checkAndRestoreAuth();
      
      if (isLoggedIn && mounted) {
        final user = await authService.getCurrentUser();
        if (user != null) {
          print('👤 Пользователь авторизован: ${user.email}');
          
          final token = await authService.getToken();
          if (token != null && !WebSocketService.isConnected) {
            await WebSocketService.connect(token);
          }
          
          setState(() {
            _initialPage = const StudentsListPage();
            _isLoading = false;
          });
          return;
        }
      }
      
      print('📄 Показываем страницу логина');
      if (mounted) {
        setState(() {
          _initialPage = const LoginPage();
          _isLoading = false;
        });
      }
      
    } catch (e) {
      print('❌ Ошибка: $e');
      if (mounted) {
        setState(() {
          _initialPage = const LoginPage();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.blue.shade800,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school, size: 100, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                'Управление студентами',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text(
                'Проверка авторизации...',
                style: TextStyle(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 30),
              const CircularProgressIndicator(color: Colors.white, strokeWidth: 4),
            ],
          ),
        ),
      );
    }
    return _initialPage!;
  }
}