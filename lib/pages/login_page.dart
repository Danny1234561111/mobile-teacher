import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/register_dto.dart';
import 'student_list_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginMode = true;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _selectedDate;
  String _errorMessage = '';
  String _selectedRole = 'teacher';
  final List<String> _roles = ['teacher', 'student', 'admin'];
  bool _showTeacherFields = false;

  @override
  void initState() {
    super.initState();
    // Для тестирования
    _emailController.text = '';
    _passwordController.text = '';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final authService = AuthService();
      
      if (_isLoginMode) {
        print('🔄 Попытка входа...');
        final response = await authService.login(
          _emailController.text,
          _passwordController.text,
        );
        
        print('✅ Успешный вход, пользователь: ${response.user.email}');
        
        // Переходим на соответствующую страницу в зависимости от роли
        if (mounted) {
          _navigateToDashboard(response.user.role);
        }
      } else {
        print('🔄 Попытка регистрации...');
        final registerDto = RegisterDto(
          fullName: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
          dateOfBirth: _selectedDate,
          role: _selectedRole,
          maxStudents: _selectedRole == 'teacher' ? 20 : null,
        );
        
        // Для преподавателей используем отдельный эндпоинт
        if (_selectedRole == 'teacher') {
          final result = await authService.registerTeacherRequest(registerDto);
          
          if (mounted) {
            _showRegistrationSuccessDialog(result);
          }
        } else {
          final response = await authService.register(registerDto);
          
          print('✅ Успешная регистрация, пользователь: ${response.user.email}');
          
          if (mounted) {
            _navigateToDashboard(response.user.role);
          }
        }
      }
    } catch (e) {
      print('❌ Ошибка: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      _showError('Ошибка: $e');
    }
  }

  void _navigateToDashboard(String role) {
    if (role == 'admin') {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/admin',
        (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const StudentsListPage(),
        ),
        (route) => false,
      );
    }
  }

  void _showRegistrationSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Заявка отправлена'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '✅ Ваша заявка на регистрацию преподавателя успешно отправлена!',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ваша заявка будет рассмотрена администратором. После одобрения вы получите email с данными для входа.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            if (result['request_id'] != null)
              Text(
                'ID заявки: ${result['request_id']}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isLoginMode = true;
                _isLoading = false;
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _switchMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _errorMessage = '';
      if (!_isLoginMode) {
        _nameController.clear();
        _phoneController.clear();
        _selectedDate = null;
        _selectedRole = 'teacher';
        _showTeacherFields = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Логотип и заголовок
                Column(
                  children: [
                    Icon(
                      Icons.school,
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Управление студентами',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isLoginMode ? 'Вход в систему' : 'Регистрация',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Поле для имени (только при регистрации)
                if (!_isLoginMode) ...[
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'ФИО*',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите ваше ФИО';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Выбор роли
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Роль*',
                      prefixIcon: Icon(Icons.work),
                      border: OutlineInputBorder(),
                    ),
                    items: _roles.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(
                          role == 'teacher' ? 'Преподаватель' :
                          role == 'student' ? 'Студент' : 'Администратор',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                        _showTeacherFields = value == 'teacher';
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Выберите роль';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Поле для email
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email*',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Введите корректный email';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Поле для пароля
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Пароль*',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите пароль';
                    }
                    if (value.length < 6) {
                      return 'Пароль должен быть не менее 6 символов';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Дополнительные поля для регистрации
                if (!_isLoginMode) ...[
                  // Дата рождения
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: TextEditingController(
                          text: _selectedDate != null
                              ? '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}'
                              : '',
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Дата рождения',
                          prefixIcon: Icon(Icons.cake),
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Телефон',
                      prefixIcon: Icon(Icons.phone),
                      border: OutlineInputBorder(),
                      hintText: '+79991234567',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Дополнительные поля для преподавателей
                  if (_showTeacherFields) ...[
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Информация для преподавателя',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Опыт работы',
                                hintText: 'Опишите ваш опыт...',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                              onChanged: (value) {
                                // Сохраняем в отдельной переменной
                              },
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Образование',
                                hintText: 'Ваше образование...',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                              onChanged: (value) {
                                // Сохраняем в отдельной переменной
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
                
                // Сообщение об ошибке
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Кнопка входа/регистрации
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isLoginMode ? 'Войти' : 'Зарегистрироваться',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
                
                const SizedBox(height: 20),
                
                // Переключение между входом и регистрацией
                TextButton(
                  onPressed: _isLoading ? null : _switchMode,
                  child: Text(
                    _isLoginMode
                        ? 'Нет аккаунта? Зарегистрироваться'
                        : 'Уже есть аккаунт? Войти',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                
                // Информация о двухэтапной регистрации
                if (!_isLoginMode && _selectedRole == 'teacher')
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '⚠️ Регистрация преподавателя проходит в два этапа: '
                      'сначала вы отправляете заявку, затем администратор её рассмотрит '
                      'и отправит вам данные для входа.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}