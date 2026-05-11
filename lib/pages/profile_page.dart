// pages/profile_page.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/student_service.dart';
import '../models/user.dart';
import 'student_list_page.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
      await _authService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const StudentsListPage()),
          (route) => false,
        );
      }
    }
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

  Widget _buildInfoCard(String title, String value, IconData icon) {
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
            Icon(icon, color: accentBlue, size: 24),
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
              width: 28,  // ограничиваем ширину
              height: 28, // ограничиваем высоту
              child: Image.asset(
                'assets/icons/home.png',
                width: 20,
                height: 20,
                fit: BoxFit.contain, // чтобы картинка вписалась в размер
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.home, size: 20, color: accentBlue),
              ),
            ),
          ),
        ),
        actions: [
          // Кнопка парсера
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () async {
                try {
                  final studentService = StudentService();
                  await studentService.runParser();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Парсер запущен'), backgroundColor: successGreen),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка запуска парсера: $e'), backgroundColor: errorRed),
                  );
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
          // Кнопка выхода
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
                      
                      // Информация
                      _buildInfoCard('ID', _user!.id.toString(), Icons.badge),
                      const SizedBox(height: 12),
                      _buildInfoCard('Email', _user!.email, Icons.email),
                      const SizedBox(height: 12),
                      _buildInfoCard('Роль', _user!.role, Icons.work),
                    ],
                  ),
                ),
    );
  }
}