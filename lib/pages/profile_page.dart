// pages/profile_page.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/student_service.dart';
import '../models/user.dart';
import 'student_list_page.dart';
import 'login_page.dart';
import '../services/websocket_service.dart';

// Цвета из Figma
const Color accentBlue = Color(0xFF0088FF);
const Color borderColor = Color(0xFFC5C6D0);
const Color successGreen = Color(0xFF34C759);
const Color errorRed = Color(0xFFFF383C);
const Color warningOrange = Color(0xFFFF9800);
const Color neutralGray = Color(0xFFA0A0A0);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = true;
  bool _isServiceRunning = true;
  bool _isTogglingService = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkServiceStatus();
  }

  Future<void> _checkServiceStatus() async {
    setState(() {
      _isServiceRunning = WebSocketService.isConnected;
    });
  }

  Future<void> _toggleBackgroundService() async {
    setState(() {
      _isTogglingService = true;
    });

    try {
      if (_isServiceRunning) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Отключение фонового сервиса'),
            content: const Text(
              'Вы уверены, что хотите отключить фоновый сервис?\n\n'
              'После отключения вы не будете получать команды от сервера '
              '(звонки, сообщения, уведомления).\n\n'
              'Вы сможете включить его снова в любой момент.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Отключить', style: TextStyle(color: errorRed)),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          WebSocketService.disconnect();
          WebSocketService.stopBackgroundService();
          setState(() {
            _isServiceRunning = false;
          });
          _showMessage('Фоновый сервис отключен', Colors.grey);
        }
      } else {
        await WebSocketService.initBackgroundService();
        await Future.delayed(const Duration(seconds: 2));
        
        final token = await _authService.getToken();
        if (token != null) {
          await WebSocketService.connect(token);
        }
        
        setState(() {
          _isServiceRunning = WebSocketService.isConnected;
        });
        
        if (_isServiceRunning) {
          _showMessage('Фоновый сервис включен', successGreen);
        } else {
          _showMessage('Не удалось включить сервис', errorRed);
        }
      }
    } catch (e) {
      _showMessage('Ошибка: $e', errorRed);
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingService = false;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getProfile();
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Ошибка загрузки профиля: $e');
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти из системы?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Выйти', style: TextStyle(color: errorRed)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      WebSocketService.disconnect();
      WebSocketService.stopBackgroundService();
      await _authService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: errorRed),
    );
  }

  void _navigateToStudentsList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StudentsListPage()),
    );
  }

  Widget _buildInfoCard(String title, String value, String iconPath) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Image.asset(
              iconPath,
              width: 24,
              height: 24,
              color: accentBlue,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.error, color: accentBlue, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECF5FD),
      appBar: AppBar(
        title: const Text(
          'Профиль',
          style: TextStyle(color: accentBlue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFECF5FD),
        elevation: 0,
        leadingWidth: 44,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: GestureDetector(
            onTap: _navigateToStudentsList,
            child: SizedBox(
              width: 28,
              height: 28,
              child: Image.asset(
                'assets/icons/home.png',
                width: 20,
                height: 20,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.home, size: 20, color: accentBlue),
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () async {
                try {
                  final studentService = StudentService();
                  await studentService.runParser();
                  _showMessage('Парсер запущен', successGreen);
                } catch (e) {
                  _showError('Ошибка запуска парсера: $e');
                }
              },
              child: Image.asset(
                'assets/icons/parse2.png',
                width: 28,
                height: 28,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.cloud_upload, size: 28, color: accentBlue),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: _logout,
              child: Image.asset(
                'assets/icons/logout.png',
                width: 28,
                height: 28,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.logout, size: 28, color: errorRed),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('Профиль не найден'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Аватар и имя
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: borderColor, width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: accentBlue.withOpacity(0.1),
                                child: Text(
                                  _user!.fullName.isNotEmpty
                                      ? _user!.fullName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: accentBlue,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _user!.fullName,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: (_user!.isAdmin ? errorRed : successGreen)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _user!.isAdmin ? errorRed : successGreen,
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  _user!.isAdmin ? 'Администратор' : 'Пользователь',
                                  style: TextStyle(
                                    color: _user!.isAdmin ? errorRed : successGreen,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Кнопка управления фоновым сервисом
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: borderColor, width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/icons/parse.png',
                                    width: 24,
                                    height: 24,
                                    color: accentBlue,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.settings_backup_restore, color: accentBlue, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Фоновый сервис',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Сервис получает команды от сервера для автоматических '
                                'звонков, сообщений и уведомлений. Работает даже когда '
                                'приложение свернуто.',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _isTogglingService ? null : _toggleBackgroundService,
                                      icon: Icon(
                                        _isServiceRunning ? Icons.pause : Icons.play_arrow,
                                        size: 20,
                                      ),
                                      label: Text(
                                        _isServiceRunning ? 'Отключить сервис' : 'Включить сервис',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isServiceRunning ? errorRed : successGreen,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _isServiceRunning 
                                          ? successGreen.withOpacity(0.1) 
                                          : errorRed.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _isServiceRunning ? successGreen : errorRed,
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _isServiceRunning ? successGreen : errorRed,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _isServiceRunning ? 'Активен' : 'Отключен',
                                          style: TextStyle(
                                            color: _isServiceRunning ? successGreen : errorRed,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (_isTogglingService)
                                const Padding(
                                  padding: EdgeInsets.only(top: 12),
                                  child: LinearProgressIndicator(),
                                ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Информационные карточки с иконками из assets
                      _buildInfoCard('ID', _user!.id.toString(), 'assets/icons/id.png'),
                      const SizedBox(height: 12),
                      _buildInfoCard('Email', _user!.email, 'assets/icons/email.png'),
                      const SizedBox(height: 12),
                      _buildInfoCard('Роль', _user!.role, 'assets/icons/role.png'),
                    ],
                  ),
                ),
    );
  }
}