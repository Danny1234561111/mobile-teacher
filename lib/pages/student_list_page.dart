// pages/student_list_page.dart
import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/student_service.dart';
import '../services/auth_service.dart';
import '../utils/contact_service.dart';
import 'add_student_page.dart';
import 'student_detail_page.dart';
import 'profile_page.dart';

class StudentsListPage extends StatefulWidget {
  const StudentsListPage({super.key});

  @override
  _StudentsListPageState createState() => _StudentsListPageState();
}

class _StudentsListPageState extends State<StudentsListPage> {
  List<Student> students = [];
  List<Student> filteredStudents = [];
  bool _isLoading = true;
  final StudentService _studentService = StudentService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  String? _currentUserName;
  String _errorMessage = '';
  
  // Данные для фильтров
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _specialities = [];
  List<Map<String, dynamic>> _profiles = [];
  
  // Выбранные фильтры
  String? _selectedStatus;
  String? _selectedApplicationStatus;
  String? _selectedContactStatus;
  int? _selectedDepartmentId;
  int? _selectedSpecialityId;
  int? _selectedProfileId;
  
  // Опции для фильтров
  final List<String> _statusOptions = ['active', 'inactive'];
  final List<String> _applicationStatusOptions = ['pending', 'accepted', 'rejected', 'paid'];
  final List<String> _contactStatusOptions = ['new', 'met', 'interested', 'original_submitted', 'waiting_original', 'not_interested'];

  @override
  void initState() {
    super.initState();
    _loadUserAndStudents();
    _loadFilterData();
  }

  Future<void> _loadFilterData() async {
    try {
      final departments = await _studentService.getDepartments();
      final specialities = await _studentService.getSpecialities();
      final profiles = await _studentService.getProfiles();
      
      setState(() {
        _departments = departments;
        _specialities = specialities;
        _profiles = profiles;
      });
    } catch (e) {
      print('Ошибка загрузки данных для фильтров: $e');
    }
  }

  Future<void> _loadUserAndStudents() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final user = await _authService.getCurrentUser();
      if (user != null) {
        setState(() {
          _currentUserName = user.fullName;
        });
        await _loadStudents();
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
      final loadedStudents = await _studentService.getStudents(
        departmentId: _selectedDepartmentId,
        specialityId: _selectedSpecialityId,
      );
      setState(() {
        students = loadedStudents;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка загрузки студентов: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Student> result = students;
    
    // Поиск по тексту
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      result = result.where((student) {
        return student.fullName.toLowerCase().contains(query) ||
            student.phone.toLowerCase().contains(query) ||
            student.russianStudentId.toString().contains(query);
      }).toList();
    }
    
    // Фильтр по статусам
    if (_selectedStatus != null) {
      result = result.where((student) => 
          student.status?.toLowerCase() == _selectedStatus).toList();
    }
    
    if (_selectedApplicationStatus != null) {
      result = result.where((student) => 
          student.applicationStatus?.toLowerCase() == _selectedApplicationStatus).toList();
    }
    
    if (_selectedContactStatus != null) {
      result = result.where((student) => 
          student.contactStatus?.toLowerCase() == _selectedContactStatus).toList();
    }
    
    // Фильтр по направлению/специальности/профилю уже применен на сервере
    // при загрузке students через getStudents с параметрами
    
    setState(() {
      filteredStudents = result;
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = null;
      _selectedApplicationStatus = null;
      _selectedContactStatus = null;
      _selectedDepartmentId = null;
      _selectedSpecialityId = null;
      _selectedProfileId = null;
    });
    _loadStudents(); // Перезагружаем без фильтров
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
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _deleteStudent(int studentId) async {
    final student = students.firstWhere((s) => s.id == studentId);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить студента'),
        content: Text('Вы уверены, что хотите удалить студента "${student.fullName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Отмена')),
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
      
      setState(() {
        students.removeWhere((s) => s.id == studentId);
        _applyFilters();
        _isLoading = false;
      });
      
      _showSuccessSnackbar('Студент удален');
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Ошибка удаления: $e');
    }
  }

  Future<void> _refreshStudents() async {
    await _loadStudents();
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            padding: const EdgeInsets.all(20),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Фильтры',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Фильтр по направлению
                        DropdownButtonFormField<int?>(
                          value: _selectedDepartmentId,
                          decoration: const InputDecoration(
                            labelText: 'Направление',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Все направления'),
                            ),
                            ..._departments.map((dept) => DropdownMenuItem(
                              value: dept['id'] as int,
                              child: Text(dept['name'] ?? ''),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedDepartmentId = value;
                              _selectedSpecialityId = null; // Сбрасываем при смене направления
                              _selectedProfileId = null; // Сбрасываем профиль
                            });
                          },
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Фильтр по специальности
                        DropdownButtonFormField<int?>(
                          value: _selectedSpecialityId,
                          decoration: const InputDecoration(
                            labelText: 'Специальность',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Все специальности'),
                            ),
                            ..._specialities
                                .where((spec) => 
                                    _selectedDepartmentId == null || 
                                    spec['department_id'] == _selectedDepartmentId)
                                .map((spec) => DropdownMenuItem(
                                  value: spec['id'] as int,
                                  child: Text(spec['name'] ?? ''),
                                )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedSpecialityId = value;
                              _selectedProfileId = null; // Сбрасываем профиль
                            });
                          },
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Фильтр по профилю
                        DropdownButtonFormField<int?>(
                          value: _selectedProfileId,
                          decoration: const InputDecoration(
                            labelText: 'Профиль',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Все профили'),
                            ),
                            ..._profiles
                                .where((prof) => 
                                    _selectedSpecialityId == null || 
                                    prof['speciality_id'] == _selectedSpecialityId)
                                .map((prof) => DropdownMenuItem(
                                  value: prof['id'] as int,
                                  child: Text(prof['name'] ?? ''),
                                )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedProfileId = value;
                            });
                          },
                        ),
                        
                        const Divider(height: 32),
                        
                        // Фильтр по общему статусу
                        DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Общий статус',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Все статусы')),
                            ..._statusOptions.map((status) => DropdownMenuItem(
                              value: status,
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(_getStatusDisplayName(status)),
                                ],
                              ),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedStatus = value;
                            });
                          },
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Фильтр по статусу заявления
                        DropdownButtonFormField<String>(
                          value: _selectedApplicationStatus,
                          decoration: const InputDecoration(
                            labelText: 'Статус заявления',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Все статусы')),
                            ..._applicationStatusOptions.map((status) => DropdownMenuItem(
                              value: status,
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _getApplicationStatusColor(status),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(_getApplicationStatusDisplayName(status)),
                                ],
                              ),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedApplicationStatus = value;
                            });
                          },
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Фильтр по статусу контакта
                        DropdownButtonFormField<String>(
                          value: _selectedContactStatus,
                          decoration: const InputDecoration(
                            labelText: 'Статус контакта',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Все статусы')),
                            ..._contactStatusOptions.map((status) => DropdownMenuItem(
                              value: status,
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _getContactStatusColor(status),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(_getContactStatusDisplayName(status)),
                                ],
                              ),
                            )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedContactStatus = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _loadStudents(); // Перезагружаем с новыми фильтрами
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Применить'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedDepartmentId = null;
                            _selectedSpecialityId = null;
                            _selectedProfileId = null;
                            _selectedStatus = null;
                            _selectedApplicationStatus = null;
                            _selectedContactStatus = null;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Сбросить все'),
                      ),
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
        title: const Text('Студенты'),
        centerTitle: true,
        actions: [
          // Кнопка фильтров с индикатором
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterDialog,
                tooltip: 'Фильтры',
              ),
              if (_selectedDepartmentId != null || 
                  _selectedSpecialityId != null || 
                  _selectedProfileId != null ||
                  _selectedStatus != null || 
                  _selectedApplicationStatus != null || 
                  _selectedContactStatus != null)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            tooltip: 'Профиль',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStudents,
            tooltip: 'Обновить',
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
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                    
                    // Статистика
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Всего: ${students.length}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          if (filteredStudents.length != students.length)
                            Text(
                              'Показано: ${filteredStudents.length}',
                              style: TextStyle(color: Colors.blue.shade600, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Активные фильтры
                    if (_selectedDepartmentId != null || 
                        _selectedSpecialityId != null || 
                        _selectedProfileId != null ||
                        _selectedStatus != null || 
                        _selectedApplicationStatus != null || 
                        _selectedContactStatus != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (_selectedDepartmentId != null)
                                _buildActiveFilterChip(
                                  label: 'Напр: ${_getDepartmentName(_selectedDepartmentId!)}',
                                  color: Colors.blue,
                                  onDelete: () {
                                    setState(() {
                                      _selectedDepartmentId = null;
                                      _selectedSpecialityId = null;
                                      _selectedProfileId = null;
                                    });
                                    _loadStudents();
                                  },
                                ),
                              
                              if (_selectedSpecialityId != null)
                                _buildActiveFilterChip(
                                  label: 'Спец: ${_getSpecialityName(_selectedSpecialityId!)}',
                                  color: Colors.purple,
                                  onDelete: () {
                                    setState(() {
                                      _selectedSpecialityId = null;
                                      _selectedProfileId = null;
                                    });
                                    _loadStudents();
                                  },
                                ),
                              
                              if (_selectedProfileId != null)
                                _buildActiveFilterChip(
                                  label: 'Проф: ${_getProfileName(_selectedProfileId!)}',
                                  color: Colors.teal,
                                  onDelete: () {
                                    setState(() {
                                      _selectedProfileId = null;
                                    });
                                    _loadStudents();
                                  },
                                ),
                              
                              if (_selectedStatus != null)
                                _buildActiveFilterChip(
                                  label: 'Статус: ${_getStatusDisplayName(_selectedStatus!)}',
                                  color: _getStatusColor(_selectedStatus!),
                                  onDelete: () {
                                    setState(() {
                                      _selectedStatus = null;
                                    });
                                    _applyFilters();
                                  },
                                ),
                              
                              if (_selectedApplicationStatus != null)
                                _buildActiveFilterChip(
                                  label: 'Заявление: ${_getApplicationStatusDisplayName(_selectedApplicationStatus!)}',
                                  color: _getApplicationStatusColor(_selectedApplicationStatus!),
                                  onDelete: () {
                                    setState(() {
                                      _selectedApplicationStatus = null;
                                    });
                                    _applyFilters();
                                  },
                                ),
                              
                              if (_selectedContactStatus != null)
                                _buildActiveFilterChip(
                                  label: 'Контакт: ${_getContactStatusDisplayName(_selectedContactStatus!)}',
                                  color: _getContactStatusColor(_selectedContactStatus!),
                                  onDelete: () {
                                    setState(() {
                                      _selectedContactStatus = null;
                                    });
                                    _applyFilters();
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Список студентов с отступом снизу
                    Expanded(
                      child: filteredStudents.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _refreshStudents,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(8).copyWith(
                                  bottom: 80, // Отступ снизу для последней карточки
                                ),
                                itemCount: filteredStudents.length,
                                itemBuilder: (context, index) {
                                  final student = filteredStudents[index];
                                  return _buildStudentCard(student, index);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddStudent(),
        child: const Icon(Icons.add),
        tooltip: 'Добавить студента',
      ),
    );
  }

  Widget _buildActiveFilterChip({
    required String label,
    required Color color,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.close, size: 14, color: color),
          ),
        ],
      ),
    );
  }

  String _getDepartmentName(int id) {
    final dept = _departments.firstWhere((d) => d['id'] == id, orElse: () => {'name': '?'});
    return dept['name'] ?? '?';
  }

  String _getSpecialityName(int id) {
    final spec = _specialities.firstWhere((s) => s['id'] == id, orElse: () => {'name': '?'});
    return spec['name'] ?? '?';
  }

  String _getProfileName(int id) {
    final prof = _profiles.firstWhere((p) => p['id'] == id, orElse: () => {'name': '?'});
    return prof['name'] ?? '?';
  }

  Widget _buildStudentCard(Student student, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _navigateToStudentDetail(student),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Верхняя строка с ФИО и баллами
              Row(
                children: [
                  Expanded(
                    child: Text(
                      student.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (student.totalScore != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getScoreColor(student.totalScore!).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getScoreColor(student.totalScore!).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.emoji_events,
                            size: 14,
                            color: _getScoreColor(student.totalScore!),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${student.totalScore}',
                            style: TextStyle(
                              color: _getScoreColor(student.totalScore!),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Флажки статусов
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  // Общий статус
                  _buildStatusFlag(
                    label: _getStatusDisplayName(student.status),
                    color: _getStatusColor(student.status),
                  ),
                  
                  // Статус заявления
                  if (student.applicationStatus != null)
                    _buildStatusFlag(
                      label: _getApplicationStatusDisplayName(student.applicationStatus!),
                      color: _getApplicationStatusColor(student.applicationStatus!),
                    ),
                  
                  // Статус контакта
                  if (student.contactStatus != null)
                    _buildStatusFlag(
                      label: _getContactStatusDisplayName(student.contactStatus!),
                      color: _getContactStatusColor(student.contactStatus!),
                    ),
                  
                  // Согласие
                  if (student.consentStatus != null)
                    _buildStatusFlag(
                      label: student.consentStatus! ? 'Согласие' : 'Нет согласия',
                      color: student.consentStatus! ? Colors.green : Colors.red,
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Контактная информация
              Row(
                children: [
                  Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    student.displayPhone,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              Row(
                children: [
                  Icon(Icons.badge, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'ID: ${student.russianStudentId}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ],
              ),
              
              if (student.departmentName != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.school, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        student.departmentName!,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              
              if (student.lastCommunication != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      'Последняя связь: ${_formatDate(student.lastCommunication!)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 8),
              
              // Кнопки действий
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.call, color: Colors.green, size: 20),
                    onPressed: () => ContactService.callStudent(student.phone),
                    tooltip: 'Позвонить',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                  IconButton(
                    icon: Icon(Icons.message, color: Colors.blue, size: 20),
                    onPressed: () => ContactService.messageStudent(student.phone),
                    tooltip: 'Написать',
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (value) => _handlePopupMenu(value, student),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'add_contact',
                        child: Row(
                          children: [
                            Icon(Icons.contact_page, color: Colors.orange, size: 18),
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
                            Icon(Icons.delete, color: Colors.red, size: 18),
                            const SizedBox(width: 8),
                            const Text('Удалить'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFlag({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Цвета для статусов
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.red;
      case 'enrolled':
        return Colors.blue;
      case 'withdrawn':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getApplicationStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'paid':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getContactStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'new':
        return Colors.grey;
      case 'met':
      case 'был на встрече':
        return Colors.green;
      case 'interested':
      case 'заинтересован в поступлении':
        return Colors.lightGreen;
      case 'original_submitted':
      case 'подан оригинал':
        return Colors.blue;
      case 'waiting_original':
      case 'ждем оригинал':
        return Colors.orange;
      case 'not_interested':
      case 'не заинтересован/не интересно':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 250) return Colors.green;
    if (score >= 200) return Colors.lightGreen;
    if (score >= 150) return Colors.orange;
    return Colors.red;
  }

  // Отображение статусов
  String _getStatusDisplayName(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return 'Активный';
      case 'inactive':
        return 'Неактивный';
      case 'enrolled':
        return 'Зачислен';
      case 'withdrawn':
        return 'Отчислен';
      default:
        return status ?? 'Неизвестно';
    }
  }

  String _getApplicationStatusDisplayName(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'Ожидает';
      case 'accepted':
        return 'Принято';
      case 'rejected':
        return 'Отклонено';
      case 'paid':
        return 'Оплачено';
      default:
        return status ?? 'Неизвестно';
    }
  }

  String _getContactStatusDisplayName(String? status) {
    switch (status?.toLowerCase()) {
      case 'new':
        return 'Новый';
      case 'met':
      case 'был на встрече':
        return 'Был на встрече';
      case 'interested':
      case 'заинтересован в поступлении':
        return 'Заинтересован';
      case 'original_submitted':
      case 'подан оригинал':
        return 'Подан оригинал';
      case 'waiting_original':
      case 'ждем оригинал':
        return 'Ждем оригинал';
      case 'not_interested':
      case 'не заинтересован/не интересно':
        return 'Не заинтересован';
      default:
        return status ?? 'Неизвестно';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text('Загрузка студентов...', style: TextStyle(color: Colors.grey.shade600)),
          if (_currentUserName != null) ...[
            const SizedBox(height: 10),
            Text('Пользователь: $_currentUserName', style: const TextStyle(fontSize: 14, color: Colors.blue)),
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
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 20),
            Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.red)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _loadUserAndStudents,
              icon: const Icon(Icons.refresh),
              label: const Text('Попробовать снова'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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
          Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          const Text('Студенты не найдены', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 10),
          if (_selectedDepartmentId != null || 
              _selectedSpecialityId != null || 
              _selectedProfileId != null ||
              _selectedStatus != null || 
              _selectedApplicationStatus != null || 
              _selectedContactStatus != null)
            Column(
              children: [
                const Text('Попробуйте изменить фильтры', style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 10),
                ElevatedButton(onPressed: _clearFilters, child: const Text('Сбросить фильтры')),
              ],
            )
          else
            const Text('Нажмите + чтобы добавить первого студента', style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  void _navigateToStudentDetail(Student student) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StudentDetailPage(student: student)),
    );
  }

  void _navigateToAddStudent() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddStudentPage(onAdd: _addStudent)),
    );
  }

  void _handlePopupMenu(String value, Student student) {
    switch (value) {
      case 'add_contact':
        ContactService.addContactToPhone(student);
        break;
      case 'delete':
        _deleteStudent(student.id);
        break;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}