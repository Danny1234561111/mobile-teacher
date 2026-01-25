import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/student_list_page.dart';
import 'pages/admin_page.dart';
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
        '/admin': (context) => const AdminPage(),
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
      
      // 1. Сначала проверяем, есть ли сохраненные данные
      final savedCredentials = await authService.getSavedCredentials();
      
      if (savedCredentials != null) {
        print('📧 Найдены сохраненные данные для: ${savedCredentials['email']}');
        print('🔄 Пытаемся авто-логин...');
        
        // Пробуем сделать авто-логин
        final autoLoginSuccess = await authService.tryAutoLoginIfPossible();
        
        if (autoLoginSuccess) {
          print('✅ Авто-логин успешен! Получаем профиль...');
          
          // Получаем профиль пользователя
          try {
            final user = await authService.getProfile();
            print('👤 Профиль получен: ${user.email}, роль: ${user.role}');
            
            if (mounted) {
              setState(() {
                _initialPage = _getPageByRole(user.role);
                _isLoading = false;
              });
            }
            return;
          } catch (e) {
            print('❌ Ошибка получения профиля после авто-логина: $e');
          }
        } else {
          print('❌ Авто-логин не удался');
        }
      } else {
        print('⚠️  Нет сохраненных данных для авто-логина');
      }
      
      // 2. Если авто-логин не удался или нет данных, проверяем существующий токен
      final token = await authService.getToken();
      if (token != null) {
        print('🔑 Найден токен, проверяем валидность...');
        try {
          final user = await authService.getProfile();
          print('✅ Токен валиден: ${user.email}, роль: ${user.role}');
          
          if (mounted) {
            setState(() {
              _initialPage = _getPageByRole(user.role);
              _isLoading = false;
            });
          }
          return;
        } catch (e) {
          print('❌ Токен невалиден: $e');
        }
      }
      
      // 3. Если ничего не сработало - показываем страницу логина
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

  Widget _getPageByRole(String role) {
    if (role == 'admin') {
      return const AdminPage();
    } else {
      return const StudentsListPage();
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
            const Icon(
              Icons.school,
              size: 100,
              color: Colors.white,
            ),
            const SizedBox(height: 20),
            const Text(
              'Управление студентами',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Проверка авторизации...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 4,
            ),
          ],
        ),
      ),
    );
  }
}