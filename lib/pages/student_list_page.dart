import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/student_service.dart';
import '../services/auth_service.dart';
import '../utils/contact_service.dart';
import 'add_student_page.dart';
import 'student_detail_page.dart';
import 'profile_page.dart';
import 'admin_page.dart'; // Новая страница администратора

class StudentsListPage extends StatefulWidget {
  const StudentsListPage({super.key});

  @override
  _StudentsListPageState createState() => _StudentsListPageState();
}

class _StudentsListPageState extends State<StudentsListPage> {
  List<Student> students = [];
  List<Student> filteredStudents = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  final StudentService _studentService = StudentService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserRole;
  String _errorMessage = '';
  
  // Фильтры
  String? _selectedDepartment;
  String? _selectedSpeciality;
  String? _selectedStatus;
  List<String> _departments = [];
  List<String> _specialities = [];
  final List<String> _statusOptions = ['active', 'inactive', 'graduated', 'dropped'];

  @override
  void initState() {
    super.initState();
    _loadUserAndStudents();
  }

  Future<void> _loadUserAndStudents() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Получаем текущего пользователя
      final user = await _authService.getCurrentUser();
      if (user != null) {
        setState(() {
          _currentUserId = user.id;
          _currentUserName = user.fullName;
          _currentUserRole = user.role;
        });

        // Если пользователь - админ, перенаправляем на админ-панель
        if (user.role == 'admin') {
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminPage(),
              ),
              (route) => false,
            );
          }
          return;
        }

        // Загружаем студентов и доступные фильтры
        await _loadStudents();
        await _loadFilters();
      } else {
        setState(() {
          _errorMessage = 'Пользователь не найден. Пожалуйста, войдите снова.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки данных: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStudents() async {
    try {
      if (_currentUserId == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Загружаем студентов с учетом фильтров
      final loadedStudents = await _studentService.getMyStudents();
      setState(() {
        students = loadedStudents;
        _applyFilters();
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки студентов: $e';
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _loadFilters() async {
    // В реальном приложении здесь был бы запрос к API для получения списков
    // Сейчас используем извлечение из существующих студентов
    final departmentsSet = <String>{};
    final specialitiesSet = <String>{};
    
    for (var student in students) {
      if (student.departmentId != null && student.departmentId!.isNotEmpty) {
        departmentsSet.add(student.departmentId!);
      }
      if (student.specialityId != null && student.specialityId!.isNotEmpty) {
        specialitiesSet.add(student.specialityId!);
      }
    }
    
    setState(() {
      _departments = departmentsSet.toList();
      _specialities = specialitiesSet.toList();
    });
  }

  void _applyFilters() {
    List<Student> result = students;
    
    // Поиск по тексту
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      result = result.where((student) {
        return student.fullName.toLowerCase().contains(query) ||
            student.phone.toLowerCase().contains(query) ||
            student.russianStudentId.toLowerCase().contains(query) ||
            (student.email?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    // Фильтр по направлению
    if (_selectedDepartment != null) {
      result = result.where((student) => 
          student.departmentId == _selectedDepartment).toList();
    }
    
    // Фильтр по специальности
    if (_selectedSpeciality != null) {
      result = result.where((student) => 
          student.specialityId == _selectedSpeciality).toList();
    }
    
    // Фильтр по статусу
    if (_selectedStatus != null) {
      result = result.where((student) => 
          student.status?.toLowerCase() == _selectedStatus).toList();
    }
    
    setState(() {
      filteredStudents = result;
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedDepartment = null;
      _selectedSpeciality = null;
      _selectedStatus = null;
      filteredStudents = students;
    });
  }

  Future<void> _addStudent(Map<String, dynamic> studentData) async {
    try {
      setState(() => _isLoading = true);
      
      final createdStudent = await _studentService.createStudent(studentData);
      setState(() {
        students.add(createdStudent);
        _applyFilters();
        _isLoading = false;
      });
      
      if (mounted) {
        Navigator.pop(context);
        _showSuccessSnackbar('Студент добавлен');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorSnackbar('Ошибка добавления студента: $e');
      }
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _deleteStudent(String studentId) async {
    final student = students.firstWhere((s) => s.id == studentId);
    final studentFullName = student.fullName;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить студента'),
        content: Text('Вы уверены, что хотите удалить студента "$studentFullName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoading = true);
      await _studentService.deleteStudent(studentId);
      
      if (mounted) {
        setState(() {
          students.removeWhere((s) => s.id == studentId);
          _applyFilters();
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Студент "$studentFullName" удален'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackbar('Ошибка удаления: $e');
      }
    }
  }

  Future<void> _refreshStudents() async {
    setState(() => _isRefreshing = true);
    await _loadStudents();
    await _loadFilters();
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Фильтры',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Фильтр по направлению
                if (_departments.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _selectedDepartment,
                    decoration: const InputDecoration(
                      labelText: 'Направление',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Все направления'),
                      ),
                      ..._departments.map((dept) {
                        return DropdownMenuItem(
                          value: dept,
                          child: Text(dept),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedDepartment = value;
                      });
                    },
                  ),
                
                const SizedBox(height: 12),
                
                // Фильтр по специальности
                if (_specialities.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _selectedSpeciality,
                    decoration: const InputDecoration(
                      labelText: 'Специальность',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Все специальности'),
                      ),
                      ..._specialities.map((spec) {
                        return DropdownMenuItem(
                          value: spec,
                          child: Text(spec),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSpeciality = value;
                      });
                    },
                  ),
                
                const SizedBox(height: 12),
                
                // Фильтр по статусу
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Статус',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Все статусы'),
                    ),
                    ..._statusOptions.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(_getStatusDisplayName(status)),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  },
                ),
                
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _applyFilters();
                        },
                        child: const Text('Применить фильтры'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedDepartment = null;
                          _selectedSpeciality = null;
                          _selectedStatus = null;
                        });
                        Navigator.pop(context);
                        _clearFilters();
                      },
                      child: const Text('Сбросить'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои студенты'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Фильтры',
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfilePage(),
                ),
              );
            },
            tooltip: 'Профиль',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshStudents,
            tooltip: 'Обновить список',
          ),
        ],
      ),
      body: _isLoading && students.isEmpty
          ? _buildLoadingScreen()
          : _errorMessage.isNotEmpty
              ? _buildErrorScreen()
              : Column(
                  children: [
                    // Поисковая строка
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Поиск по имени, телефону или ID...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _applyFilters();
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) => _applyFilters(),
                      ),
                    ),
                    
                    // Информация о количестве и активные фильтры
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Всего студентов: ${students.length}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              if (filteredStudents.length != students.length)
                                Text(
                                  'Показано: ${filteredStudents.length}',
                                  style: TextStyle(
                                    color: Colors.blue.shade600,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          
                          // Показ активных фильтров
                          if (_selectedDepartment != null || 
                              _selectedSpeciality != null || 
                              _selectedStatus != null)
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (_selectedDepartment != null)
                                  Chip(
                                    label: Text('Направление: $_selectedDepartment'),
                                    deleteIcon: const Icon(Icons.close, size: 16),
                                    onDeleted: () {
                                      setState(() {
                                        _selectedDepartment = null;
                                        _applyFilters();
                                      });
                                    },
                                  ),
                                if (_selectedSpeciality != null)
                                  Chip(
                                    label: Text('Специальность: $_selectedSpeciality'),
                                    deleteIcon: const Icon(Icons.close, size: 16),
                                    onDeleted: () {
                                      setState(() {
                                        _selectedSpeciality = null;
                                        _applyFilters();
                                      });
                                    },
                                  ),
                                if (_selectedStatus != null)
                                  Chip(
                                    label: Text('Статус: ${_getStatusDisplayName(_selectedStatus!)}'),
                                    deleteIcon: const Icon(Icons.close, size: 16),
                                    onDeleted: () {
                                      setState(() {
                                        _selectedStatus = null;
                                        _applyFilters();
                                      });
                                    },
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Список студентов
                    Expanded(
                      child: filteredStudents.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _refreshStudents,
                              child: _buildStudentsList(filteredStudents),
                            ),
                    ),
                  ],
                ),
      floatingActionButton: _isLoading || _currentUserRole == 'admin'
          ? null
          : FloatingActionButton(
              onPressed: () => _navigateToAddStudent(),
              child: const Icon(Icons.add),
              tooltip: 'Добавить студента',
            ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            'Загрузка студентов...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          if (_currentUserName != null) ...[
            const SizedBox(height: 10),
            Text(
              'Преподаватель: $_currentUserName',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.blue,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
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
            ElevatedButton.icon(
              onPressed: _loadUserAndStudents,
              icon: const Icon(Icons.refresh),
              label: const Text('Попробовать снова'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              child: const Text('Выйти и войти снова'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          const Text(
            'Студенты не найдены',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          if (_selectedDepartment != null || 
              _selectedSpeciality != null || 
              _selectedStatus != null)
            Column(
              children: [
                const Text(
                  'Попробуйте изменить фильтры',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _clearFilters,
                  child: const Text('Сбросить фильтры'),
                ),
              ],
            )
          else
            const Text(
              'Нажмите + чтобы добавить первого студента',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          const SizedBox(height: 30),
          if (_currentUserName != null)
            Text(
              'Преподаватель: $_currentUserName',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentsList(List<Student> studentsToShow) {
    return ListView.builder(
      itemCount: studentsToShow.length,
      itemBuilder: (context, index) {
        final student = studentsToShow[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _navigateToStudentDetail(student),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Аватар
                  CircleAvatar(
                    backgroundColor: _getAvatarColor(index),
                    child: Text(
                      student.fullName.isNotEmpty
                          ? student.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Информация
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(
                              student.phone,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        if (student.russianStudentId.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'ID: ${student.russianStudentId}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        if (student.departmentName != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            student.departmentName!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                        if (student.status != null) ...[
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: student.status == 'active' 
                                  ? Colors.green.shade100 
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getStatusDisplayName(student.status!),
                              style: TextStyle(
                                fontSize: 10,
                                color: student.status == 'active' 
                                    ? Colors.green 
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (student.lastCommunicationDate != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Последняя связь: ${_formatDate(student.lastCommunicationDate!)}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Быстрые действия
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) => _handlePopupMenu(value, student),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'call',
                        child: Row(
                          children: [
                            Icon(Icons.call, size: 20, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Позвонить'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'message',
                        child: Row(
                          children: [
                            Icon(Icons.message, size: 20, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Написать'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'add_contact',
                        child: Row(
                          children: [
                            Icon(Icons.contact_page, size: 20, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('В контакты'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            const SizedBox(width: 8),
                            const Text('Удалить'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Активный';
      case 'inactive':
        return 'Неактивный';
      case 'graduated':
        return 'Выпустился';
      case 'dropped':
        return 'Отчислился';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  Color _getAvatarColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }

  void _navigateToStudentDetail(Student student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentDetailPage(student: student),
      ),
    );
  }

  void _navigateToAddStudent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddStudentPage(onAdd: _addStudent),
      ),
    );
  }

  void _handlePopupMenu(String value, Student student) {
    switch (value) {
      case 'call':
        ContactService.callStudent(student.phone);
        break;
      case 'message':
        ContactService.messageStudent(student.phone);
        break;
      case 'add_contact':
        ContactService.addContactToPhone(student);
        break;
      case 'delete':
        if (student.id != null) {
          _deleteStudent(student.id!);
        }
        break;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}