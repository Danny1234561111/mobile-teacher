// main.dart
import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/student_list_page.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Управление студентами',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
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
      
      // Проверяем соединение с сервером
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

      // Проверяем авторизацию
      final isLoggedIn = await authService.checkAndRestoreAuth();
      
      if (isLoggedIn && mounted) {
        final user = await authService.getCurrentUser();
        if (user != null) {
          print('👤 Пользователь авторизован: ${user.email}');
          setState(() {
            _initialPage = const StudentsListPage();
            _isLoading = false;
          });
          return;
        }
      }
      
      // Если не авторизован - показываем логин
      print('📄 Показываем страницу логина');
      if (mounted) {
        setState(() {
          _initialPage = const LoginPage();
          _isLoading = false;
        });
      }
      
    } catch (e) {
      print('❌ Ошибка определения начальной страницы: $e');
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
      return _buildLoadingScreen();
    }
    return _initialPage!;
  }

  Widget _buildLoadingScreen() {
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
}