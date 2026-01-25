import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import 'login_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final AuthService _authService = AuthService();
  User? _currentUser;
  bool _isLoading = true;
  String _errorMessage = '';
  
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const TeacherRequestsPage(),
    const UsersManagementPage(),
    const StatisticsPage(),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final user = await _authService.getCurrentUser();
      if (user == null) {
        throw Exception('Пользователь не найден');
      }

      if (user.role != 'admin') {
        throw Exception('У вас нет прав администратора');
      }

      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text('Загрузка данных администратора...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.red,
                ),
                const SizedBox(height: 20),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _logout,
                  child: const Text('Выйти в систему'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Панель администратора'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Заявки',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Пользователи',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Статистика',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}

class TeacherRequestsPage extends StatefulWidget {
  const TeacherRequestsPage({Key? key}) : super(key: key);

  @override
  _TeacherRequestsPageState createState() => _TeacherRequestsPageState();
}

class _TeacherRequestsPageState extends State<TeacherRequestsPage> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Здесь будет запрос к API для получения заявок
      // Пока используем mock данные
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _requests = [
          {
            'id': '1',
            'full_name': 'Иванов Иван Иванович',
            'email': 'teacher1@example.com',
            'phone': '+79991234567',
            'status': 'pending',
            'requested_at': '2024-01-20T10:30:00',
            'experience': '5 лет преподавания',
            'education': 'МГУ, факультет математики',
          },
          {
            'id': '2',
            'full_name': 'Петрова Мария Сергеевна',
            'email': 'teacher2@example.com',
            'phone': '+79992345678',
            'status': 'pending',
            'requested_at': '2024-01-21T14:20:00',
            'experience': '3 года работы со студентами',
            'education': 'СПбГУ, педагогическое образование',
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки заявок: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _approveRequest(String requestId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Одобрить заявку'),
        content: const Text('Вы уверены, что хотите одобрить эту заявку?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Здесь будет запрос к API для одобрения
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Заявка одобрена'),
                  backgroundColor: Colors.green,
                ),
              );
              await _loadRequests();
            },
            child: const Text('Одобрить'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectRequest(String requestId) async {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отклонить заявку'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Укажите причину отклонения:'),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Причина отклонения',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Введите причину отклонения'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              // Здесь будет запрос к API для отклонения
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Заявка отклонена'),
                  backgroundColor: Colors.orange,
                ),
              );
              await _loadRequests();
            },
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Заявки на регистрацию преподавателей',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadRequests,
              ),
            ],
          ),
        ),
        
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          )
        else if (_errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 40),
                const SizedBox(height: 10),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _loadRequests,
                  child: const Text('Попробовать снова'),
                ),
              ],
            ),
          )
        else if (_requests.isEmpty)
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check, size: 60, color: Colors.green),
                SizedBox(height: 20),
                Text(
                  'Нет новых заявок',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final request = _requests[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              request['full_name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Chip(
                              label: Text(
                                request['status'] == 'pending'
                                    ? 'Ожидает'
                                    : request['status'] == 'approved'
                                        ? 'Одобрено'
                                        : 'Отклонено',
                              ),
                              backgroundColor: request['status'] == 'pending'
                                  ? Colors.orange.shade100
                                  : request['status'] == 'approved'
                                      ? Colors.green.shade100
                                      : Colors.red.shade100,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.email, size: 16),
                            const SizedBox(width: 8),
                            Text(request['email']),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 16),
                            const SizedBox(width: 8),
                            Text(request['phone']),
                          ],
                        ),
                        if (request['experience'] != null) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Опыт работы:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(request['experience']),
                        ],
                        if (request['education'] != null) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Образование:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(request['education']),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (request['status'] == 'pending') ...[
                              OutlinedButton(
                                onPressed: () => _rejectRequest(request['id']),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Отклонить'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _approveRequest(request['id']),
                                child: const Text('Одобрить'),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class UsersManagementPage extends StatelessWidget {
  const UsersManagementPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 60, color: Colors.blue),
          SizedBox(height: 20),
          Text(
            'Управление пользователями',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 10),
          Text(
            'Этот раздел находится в разработке',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 60, color: Colors.purple),
          SizedBox(height: 20),
          Text(
            'Статистика',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 10),
          Text(
            'Этот раздел находится в разработке',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, size: 60, color: Colors.green),
          SizedBox(height: 20),
          Text(
            'Настройки системы',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 10),
          Text(
            'Этот раздел находится в разработке',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}