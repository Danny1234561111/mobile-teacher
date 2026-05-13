// pages/student_list_page.dart - исправленная версия
import 'package:flutter/material.dart';
import '../models/student.dart';
import '../models/student_application.dart';
import '../services/student_service.dart';
import '../services/auth_service.dart';
import '../utils/contact_service.dart';
import 'add_student_page.dart';
import 'student_detail_page.dart';
import 'profile_page.dart';

// Цвета из Figma
const Color accentBlue = Color(0xFF0088FF);
const Color borderColor = Color(0xFFC5C6D0);
const Color blackBorder = Color(0xFF000000);
const Color greyText = Color(0xFF49454F);
const Color successGreen = Color(0xFF34C759);
const Color successGreenBg = Color(0x8F5CD86C);
const Color errorRed = Color(0xFFFF383C);
const Color errorRedBg = Color(0xFFFFABA1);
const Color neutralGray = Color(0xFFA0A0A0);
const Color neutralGrayBg = Color(0x8FA0A0A0);
const Color warningOrange = Color(0xFFFF9800);
const Color warningOrangeBg = Color(0x8FFFF9800);

class StudentsListPage extends StatefulWidget {
  const StudentsListPage({super.key});

  @override
  _StudentsListPageState createState() => _StudentsListPageState();
}

class _StudentsListPageState extends State<StudentsListPage> with WidgetsBindingObserver {
  List<Student> students = [];
  List<Student> filteredStudents = [];
  Map<int, List<StudentApplication>> _studentApplications = {};
  bool _isLoading = true;
  final StudentService _studentService = StudentService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  String? _currentUserName;
  String _errorMessage = '';
  
  Map<String, String>? _activeContact;
  
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _specialities = [];
  List<Map<String, dynamic>> _profiles = [];
  
  // Выбранные фильтры (множественный выбор) - используем названия профилей
  Set<String> _selectedProfileNames = {};
  Set<String> _selectedSpecialityNames = {};
  String? _selectedStatus;
  String? _selectedApplicationStatus;
  String? _selectedContactStatus;
  String? _selectedMeetingStatus;
  String? _selectedCallStatus;
  String? _selectedDecisionStatus;
  String? _selectedDocumentsStatus;
  int? _selectedDepartmentId;
  String? _selectedStudyForm;
  String? _selectedStudyBasis;
  bool? _selectedConsentStatus;
  
  String _sortBy = 'score';
  bool _sortDescending = true;
  
  int _page = 0;
  int _rowsPerPage = 10;
  final List<int> _rowsPerPageOptions = [5, 10, 25, 50];
  
  final List<Map<String, dynamic>> _statusOptions = [
    {'value': 'active', 'label': 'Активный', 'color': successGreen},
    {'value': 'inactive', 'label': 'Неактивный', 'color': errorRed},
    {'value': 'enrolled', 'label': 'Зачислен', 'color': accentBlue},
  ];
  
  final List<Map<String, dynamic>> _applicationStatusOptions = [
    {'value': 'pending', 'label': 'Ожидает', 'color': warningOrange},
    {'value': 'accepted', 'label': 'Принято', 'color': successGreen},
    {'value': 'rejected', 'label': 'Отклонено', 'color': errorRed},
    {'value': 'paid', 'label': 'Оплачено', 'color': accentBlue},
  ];
  
  final List<Map<String, dynamic>> _contactStatusOptions = [
    {'value': 'new', 'label': 'Новый', 'color': neutralGray},
    {'value': 'met', 'label': 'Встретились', 'color': successGreen},
    {'value': 'interested', 'label': 'Заинтересован', 'color': const Color(0xFF8BC34A)},
    {'value': 'original_submitted', 'label': 'Подан оригинал', 'color': accentBlue},
    {'value': 'waiting_original', 'label': 'Ждем оригинал', 'color': warningOrange},
    {'value': 'not_interested', 'label': 'Не заинтересован', 'color': errorRed},
  ];
  
  final List<Map<String, dynamic>> _meetingStatusOptions = [
    {'value': 'not_met', 'label': 'Не был на сборе', 'color': errorRed, 'bgColor': errorRedBg},
    {'value': 'met', 'label': 'Был на сборе', 'color': successGreen, 'bgColor': successGreenBg},
  ];
  
  final List<Map<String, dynamic>> _callStatusOptions = [
    {'value': 'not_reached', 'label': 'Не дозвонились', 'color': errorRed, 'bgColor': errorRedBg},
    {'value': 'reached', 'label': 'Дозвонились', 'color': successGreen, 'bgColor': successGreenBg},
  ];
  
  final List<Map<String, dynamic>> _decisionStatusOptions = [
    {'value': 'thinking', 'label': 'Думает', 'color': neutralGray, 'bgColor': neutralGrayBg},
    {'value': 'decided', 'label': 'Решил', 'color': successGreen, 'bgColor': successGreenBg},
  ];
  
  final List<Map<String, dynamic>> _documentsStatusOptions = [
    {'value': 'not_submitted', 'label': 'Нет заявл.', 'color': neutralGray, 'bgColor': neutralGrayBg},
    {'value': 'original_submitted', 'label': 'Подан оригинал', 'color': successGreen, 'bgColor': successGreenBg},
    {'value': 'waiting_original', 'label': 'Ждем оригинал', 'color': warningOrange, 'bgColor': warningOrangeBg},
    {'value': 'enrolled', 'label': 'Зачислен', 'color': accentBlue, 'bgColor': accentBlue.withOpacity(0.2)},
  ];
  
  final List<Map<String, dynamic>> _studyFormOptions = [
    {'value': 'Очная', 'label': 'Очная'},
    {'value': 'Очно-заочная', 'label': 'Очно-заочная'},
    {'value': 'Заочная', 'label': 'Заочная'},
  ];
  
  final List<Map<String, dynamic>> _studyBasisOptions = [
    {'value': 'Бюджетная', 'label': 'Бюджетная'},
    {'value': 'Платная', 'label': 'Платная'},
    {'value': 'Целевая', 'label': 'Целевая'},
  ];

  Set<String> get _allSpecialityNames {
  final names = <String>{};
  for (var applications in _studentApplications.values) {
    for (var app in applications) {
      if (app.specialityName != null && app.specialityName!.isNotEmpty) {
        names.add(app.specialityName!);
      }
    }
  }
  return names;
}

  // Уникальные названия профилей из заявлений всех студентов
  Set<String> get _allProfileNames {
    final names = <String>{};
    for (var applications in _studentApplications.values) {
      for (var app in applications) {
        if (app.profileName != null && app.profileName!.isNotEmpty) {
          names.add(app.profileName!);
        }
      }
    }
    return names;
  }

  String _getContactTypeFromPrior(String? priorContact) {
    if (priorContact == null || priorContact.isEmpty) return '';
    final mapping = {
      'TELEGRAM': 'telegram',
      'MESSAGES': 'sms',
      'PHONE': 'call',
      'URL': 'url',
      'телеграмм': 'telegram',
      'telegram': 'telegram',
      'просто сообщения': 'sms',
      'messages': 'sms',
      'звонок': 'call',
      'phone': 'call',
      'ссылка': 'url',
    };
    return mapping[priorContact] ?? '';
  }

  // Замени существующий метод _getPriorContactIcon на этот:
Widget _getPriorContactIconWidget(String? priorContact) {
  if (priorContact == null || priorContact.isEmpty) {
    return const Icon(Icons.help_outline, size: 28, color: Colors.grey);
  }
  
  final contactType = _getContactTypeFromPrior(priorContact);
  switch (contactType) {
  case 'telegram':
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/icons/telegram.png',
          width: 28,
          height: 28,
          errorBuilder: (context, error, stackTrace) => 
              const Icon(Icons.telegram, size: 28, color: Color(0xFF26A5E4)),
        ),
        const SizedBox(width: 25),
      ],
    );
  case 'sms':
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/icons/sms.png',
          width: 36,
          height: 36,
          errorBuilder: (context, error, stackTrace) => 
              const Icon(Icons.sms, size: 28, color: Colors.blue),
        ),
        const SizedBox(width: 25),
      ],
    );
  case 'call':
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/icons/phone.png',
          width: 28,
          height: 28,
          errorBuilder: (context, error, stackTrace) => 
              const Icon(Icons.phone, size: 28, color: Colors.green),
        ),
        const SizedBox(width: 25),
      ],
    );
  case 'url':
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/icons/link2.png',
          width: 32,
          height: 32,
          errorBuilder: (context, error, stackTrace) => 
              const Icon(Icons.link, size: 28, color: Colors.purple),
        ),
        const SizedBox(width: 25),
      ],
    );
  default:
    return const Icon(Icons.contact_phone, size: 28, color: Colors.grey);
}
}

  Color _getPriorContactColor(String? priorContact) {
    if (priorContact == null || priorContact.isEmpty) return Colors.grey;
    final mapping = {
      'TELEGRAM': const Color(0xFF26A5E4),
      'MESSAGES': const Color(0xFF2196F3),
      'PHONE': const Color(0xFF4CAF50),
      'URL': const Color(0xFF9C27B0),
      'телеграмм': const Color(0xFF26A5E4),
      'telegram': const Color(0xFF26A5E4),
      'просто сообщения': const Color(0xFF2196F3),
      'messages': const Color(0xFF2196F3),
      'звонок': const Color(0xFF4CAF50),
      'phone': const Color(0xFF4CAF50),
      'ссылка': const Color(0xFF9C27B0),
    };
    return mapping[priorContact] ?? Colors.purple;
  }

  String _getPriorContactDisplayName(String? priorContact) {
    if (priorContact == null || priorContact.isEmpty) return 'Контакт';
    final mapping = {
      'TELEGRAM': 'Telegram',
      'MESSAGES': 'SMS',
      'PHONE': 'Звонок',
      'URL': 'Ссылка',
      'телеграмм': 'Telegram',
      'telegram': 'Telegram',
      'просто сообщения': 'SMS',
      'messages': 'SMS',
      'звонок': 'Звонок',
      'phone': 'Звонок',
      'ссылка': 'Ссылка',
    };
    return mapping[priorContact] ?? 'Контакт';
  }

  Future<void> _loadActiveContact() async {
  try {
    final activeContact = await _studentService.getActiveContact();
    if (mounted) {
      setState(() {
        if (activeContact != null && activeContact['contact_type'] != null) {
          _activeContact = {
            'type': activeContact['contact_type'].toString().toLowerCase(),
            'value': activeContact['contact_value'].toString(),
          };
        } else {
          _activeContact = null;
        }
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _activeContact = null;
      });
    }
  }
}
  Future<void> _refreshAllData() async {
    await _loadActiveContact();
    await _loadStudents();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserAndStudents();
    _loadFilterData();
    _loadActiveContact();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAllData();
    }
  }

  Future<void> _loadFilterData() async {
    try {
      final departments = await _studentService.getDepartments();
      final specialities = await _studentService.getSpecialities();
      final profiles = await _studentService.getProfiles();
      
      if (mounted) {
        setState(() {
          _departments = departments;
          _specialities = specialities;
          _profiles = profiles;
        });
      }
    } catch (e) {
      print('Ошибка загрузки данных для фильтров: $e');
    }
  }

  Future<void> _loadUserAndStudents() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });
      }

      final user = await _authService.getCurrentUser();
      if (user != null) {
        if (mounted) {
          setState(() {
            _currentUserName = user.fullName;
          });
        }
        await _loadStudents();
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Пользователь не найден. Пожалуйста, войдите снова.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка загрузки данных: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadStudents() async {
    try {
      final loadedStudents = await _studentService.getStudents();
      
      final Map<int, List<StudentApplication>> applicationsMap = {};
      for (var student in loadedStudents) {
        try {
          final apps = await _studentService.getStudentApplications(student.id);
          applicationsMap[student.id] = apps;
        } catch (e) {
          print('Ошибка загрузки заявлений для студента ${student.id}: $e');
          applicationsMap[student.id] = [];
        }
      }
      
      if (mounted) {
        setState(() {
          students = loadedStudents;
          _studentApplications = applicationsMap;
          _applyFiltersAndSort();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ошибка загрузки студентов: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _applyFiltersAndSort() {
    List<Student> result = List.from(students);
    
    // Поиск
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      result = result.where((student) {
        return student.fullName.toLowerCase().contains(query) ||
            student.phone.toLowerCase().contains(query) ||
            student.russianStudentId.toString().contains(query);
      }).toList();
    }
    
    // Фильтр по профилям (по НАЗВАНИЯМ)
    if (_selectedProfileNames.isNotEmpty) {
      result = result.where((student) {
        final applications = _studentApplications[student.id];
        if (applications == null || applications.isEmpty) return false;
        return _selectedProfileNames.any((profileName) => 
            applications.any((app) => app.profileName == profileName));
      }).toList();
    }
    
    // Фильтр по специальностям
    if (_selectedSpecialityNames.isNotEmpty) {
      result = result.where((student) {
        final applications = _studentApplications[student.id];
        if (applications == null || applications.isEmpty) return false;
        return _selectedSpecialityNames.any((specialityName) => 
            applications.any((app) => app.specialityName == specialityName));
      }).toList();
    }
    
    // Фильтр по статусу
    if (_selectedStatus != null) {
      result = result.where((student) => 
          student.status?.toLowerCase() == _selectedStatus).toList();
    }
    
    // Фильтр по статусу заявления
    if (_selectedApplicationStatus != null) {
      result = result.where((student) {
        final applications = _studentApplications[student.id];
        if (applications == null) return false;
        return applications.any((app) => 
            app.applicationStatus?.toLowerCase() == _selectedApplicationStatus);
      }).toList();
    }
    
    // Фильтр по статусу контакта
    if (_selectedContactStatus != null) {
      result = result.where((student) => 
          student.contactStatus?.toLowerCase() == _selectedContactStatus).toList();
    }
    
    // Фильтр по статусу встречи
    if (_selectedMeetingStatus != null) {
      result = result.where((student) => 
          student.meetingStatus?.toLowerCase() == _selectedMeetingStatus).toList();
    }
    
    // Фильтр по статусу звонка
    if (_selectedCallStatus != null) {
      result = result.where((student) => 
          student.callStatus?.toLowerCase() == _selectedCallStatus).toList();
    }
    
    // Фильтр по решению
    if (_selectedDecisionStatus != null) {
      result = result.where((student) => 
          student.decisionStatus?.toLowerCase() == _selectedDecisionStatus).toList();
    }
    
    // Фильтр по статусу документов
    if (_selectedDocumentsStatus != null) {
      result = result.where((student) => 
          student.documentsStatus?.toLowerCase() == _selectedDocumentsStatus).toList();
    }
    
    // Фильтр по направлению
    if (_selectedDepartmentId != null) {
      result = result.where((student) => 
          student.departmentId == _selectedDepartmentId).toList();
    }
    
    // Фильтр по форме обучения
    if (_selectedStudyForm != null) {
      result = result.where((student) => 
          student.studyForm == _selectedStudyForm).toList();
    }
    
    // Фильтр по основе обучения
    if (_selectedStudyBasis != null) {
      result = result.where((student) => 
          student.studyBasis == _selectedStudyBasis).toList();
    }
    
    // Фильтр по согласию
    if (_selectedConsentStatus != null) {
      result = result.where((student) => 
          student.consentStatus == _selectedConsentStatus).toList();
    }
    
    // Сортировка
    result.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'score':
          final scoreA = a.totalScore ?? 0;
          final scoreB = b.totalScore ?? 0;
          comparison = scoreB.compareTo(scoreA);
          break;
        case 'name':
          comparison = a.fullName.compareTo(b.fullName);
          break;
        case 'id':
          comparison = a.russianStudentId.compareTo(b.russianStudentId);
          break;
        default:
          final scoreA = a.totalScore ?? 0;
          final scoreB = b.totalScore ?? 0;
          comparison = scoreB.compareTo(scoreA);
      }
      return _sortDescending ? comparison : -comparison;
    });
    
    if (mounted) {
      setState(() {
        filteredStudents = result;
        _page = 0;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedProfileNames.clear();
      _selectedSpecialityNames.clear();
      _selectedStatus = null;
      _selectedApplicationStatus = null;
      _selectedContactStatus = null;
      _selectedMeetingStatus = null;
      _selectedCallStatus = null;
      _selectedDecisionStatus = null;
      _selectedDocumentsStatus = null;
      _selectedDepartmentId = null;
      _selectedStudyForm = null;
      _selectedStudyBasis = null;
      _selectedConsentStatus = null;
      _sortBy = 'score';
      _sortDescending = true;
    });
    _applyFiltersAndSort();
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
        _studentApplications.remove(studentId);
        _applyFiltersAndSort();
        _isLoading = false;
      });
      
      _showSuccessSnackbar('Студент удален');
      await _refreshAllData();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Ошибка удаления: $e');
    }
  }

  Future<void> _refreshStudents() async {
    await _refreshAllData();
  }

  int _getActiveFiltersCount() {
    int count = 0;
    if (_selectedProfileNames.isNotEmpty) count++;
    if (_selectedSpecialityNames.isNotEmpty) count++;
    if (_selectedStatus != null) count++;
    if (_selectedApplicationStatus != null) count++;
    if (_selectedContactStatus != null) count++;
    if (_selectedMeetingStatus != null) count++;
    if (_selectedCallStatus != null) count++;
    if (_selectedDecisionStatus != null) count++;
    if (_selectedDocumentsStatus != null) count++;
    if (_selectedDepartmentId != null) count++;
    if (_selectedStudyForm != null) count++;
    if (_selectedStudyBasis != null) count++;
    if (_selectedConsentStatus != null) count++;
    return count;
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        Set<String> tempProfileNames = Set.from(_selectedProfileNames);
        Set<String> tempSpecialityNames = Set.from(_selectedSpecialityNames);
        String? tempStatus = _selectedStatus;
        String? tempApplicationStatus = _selectedApplicationStatus;
        String? tempContactStatus = _selectedContactStatus;
        String? tempMeetingStatus = _selectedMeetingStatus;
        String? tempCallStatus = _selectedCallStatus;
        String? tempDecisionStatus = _selectedDecisionStatus;
        String? tempDocumentsStatus = _selectedDocumentsStatus;
        int? tempDepartmentId = _selectedDepartmentId;
        String? tempStudyForm = _selectedStudyForm;
        String? tempStudyBasis = _selectedStudyBasis;
        bool? tempConsentStatus = _selectedConsentStatus;
        String tempSortBy = _sortBy;
        bool tempSortDescending = _sortDescending;
        
        final allProfileNames = _allProfileNames.toList();
        
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Фильтры и сортировка',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempProfileNames.clear();
                              tempSpecialityNames.clear();
                              tempStatus = null;
                              tempApplicationStatus = null;
                              tempContactStatus = null;
                              tempMeetingStatus = null;
                              tempCallStatus = null;
                              tempDecisionStatus = null;
                              tempDocumentsStatus = null;
                              tempDepartmentId = null;
                              tempStudyForm = null;
                              tempStudyBasis = null;
                              tempConsentStatus = null;
                              tempSortBy = 'score';
                              tempSortDescending = true;
                            });
                          },
                          style: TextButton.styleFrom(foregroundColor: accentBlue),
                          child: const Text('Сбросить все'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Сортировка
                    const Text('Сортировка', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'score', label: Text('По баллам')),
                              ButtonSegment(value: 'name', label: Text('По имени')),
                              ButtonSegment(value: 'id', label: Text('По ID')),
                            ],
                            selected: {tempSortBy},
                            style: ButtonStyle(
                              foregroundColor: WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return accentBlue;
                                }
                                return null;
                              }),
                              backgroundColor: WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return accentBlue.withOpacity(0.1);
                                }
                                return null;
                              }),
                            ),
                            onSelectionChanged: (Set<String> newSelection) {
                              setModalState(() {
                                tempSortBy = newSelection.first;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'desc', label: Text('По убыванию')),
                              ButtonSegment(value: 'asc', label: Text('По возрастанию')),
                            ],
                            selected: {tempSortDescending ? 'desc' : 'asc'},
                            style: ButtonStyle(
                              foregroundColor: WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return accentBlue;
                                }
                                return null;
                              }),
                              backgroundColor: WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return accentBlue.withOpacity(0.1);
                                }
                                return null;
                              }),
                            ),
                            onSelectionChanged: (Set<String> newSelection) {
                              setModalState(() {
                                tempSortDescending = newSelection.first == 'desc';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    const Divider(height: 24),
                    
                    // Профили (множественный выбор по названиям)
                    if (allProfileNames.isNotEmpty)
                      _buildMultiSelectFilter(
                        title: 'Профили обучения',
                        options: allProfileNames.map((name) => {
                          'value': name,
                          'label': name,
                          'color': accentBlue,
                        }).toList(),
                        selectedValues: tempProfileNames,
                        onChanged: (value, selected) {
                          setModalState(() {
                            if (selected) {
                              tempProfileNames.add(value);
                            } else {
                              tempProfileNames.remove(value);
                            }
                          });
                        },
                      ),
                    
                    if (allProfileNames.isNotEmpty) const SizedBox(height: 16),
                    
                    // Специальности
                    if (_allSpecialityNames.isNotEmpty)
                      _buildMultiSelectFilter(
                        title: 'Специальности',
                        options: _allSpecialityNames.map((name) => {
                          'value': name,
                          'label': name,
                          'color': Colors.purple,
                        }).toList(),
                        selectedValues: tempSpecialityNames,
                        onChanged: (value, selected) {
                          setModalState(() {
                            if (selected) {
                              tempSpecialityNames.add(value);
                            } else {
                              tempSpecialityNames.remove(value);
                            }
                          });
                        },
                      ),
                    
                    if (_allSpecialityNames.isNotEmpty) const SizedBox(height: 16),
                    
                    // Статус абитуриента
                    _buildFilterSelect(
                      title: 'Статус абитуриента',
                      value: tempStatus,
                      options: [
                        {'value': null, 'label': 'Все статусы'},
                        ..._statusOptions,
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          tempStatus = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Статус заявления
                    _buildFilterSelect(
                      title: 'Статус заявления',
                      value: tempApplicationStatus,
                      options: [
                        {'value': null, 'label': 'Все статусы'},
                        ..._applicationStatusOptions,
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          tempApplicationStatus = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Статус контакта
                    _buildFilterSelect(
                      title: 'Статус контакта',
                      value: tempContactStatus,
                      options: [
                        {'value': null, 'label': 'Все статусы'},
                        ..._contactStatusOptions,
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          tempContactStatus = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Был на сборе
                    _buildFilterSelect(
                      title: 'Был на сборе',
                      value: tempMeetingStatus,
                      options: [
                        {'value': null, 'label': 'Все'},
                        ..._meetingStatusOptions,
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          tempMeetingStatus = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Дозвонились
                    _buildFilterSelect(
                      title: 'Дозвонились',
                      value: tempCallStatus,
                      options: [
                        {'value': null, 'label': 'Все'},
                        ..._callStatusOptions,
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          tempCallStatus = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Решение
                    _buildFilterSelect(
                      title: 'Решение',
                      value: tempDecisionStatus,
                      options: [
                        {'value': null, 'label': 'Все'},
                        ..._decisionStatusOptions,
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          tempDecisionStatus = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Статус документов
                    _buildFilterSelect(
                      title: 'Статус документов',
                      value: tempDocumentsStatus,
                      options: [
                        {'value': null, 'label': 'Все'},
                        ..._documentsStatusOptions,
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          tempDocumentsStatus = value;
                        });
                      },
                    ),
                    
                    const Divider(height: 24),
                    
                    // Направление
                    _buildFilterSelect(
                      title: 'Направление',
                      value: tempDepartmentId,
                      options: [
                        {'value': null, 'label': 'Все направления'},
                        ..._departments.map((dept) => ({
                          'value': dept['id'],
                          'label': dept['name'] ?? '',
                        })),
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          tempDepartmentId = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Форма обучения
                    _buildFilterSelect(
                      title: 'Форма обучения',
                      value: tempStudyForm,
                      options: [
                        {'value': null, 'label': 'Все формы'},
                        ..._studyFormOptions,
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          tempStudyForm = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Основа обучения
                    _buildFilterSelect(
                      title: 'Основа обучения',
                      value: tempStudyBasis,
                      options: [
                        {'value': null, 'label': 'Все основы'},
                        ..._studyBasisOptions,
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          tempStudyBasis = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Согласие
                    _buildFilterSelect(
                      title: 'Согласие',
                      value: tempConsentStatus,
                      options: const [
                        {'value': null, 'label': 'Все'},
                        {'value': true, 'label': 'Согласие получено'},
                        {'value': false, 'label': 'Согласие не получено'},
                      ],
                      onChanged: (value) {
                        setModalState(() {
                          tempConsentStatus = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedProfileNames = tempProfileNames;
                            _selectedSpecialityNames = tempSpecialityNames;
                            _selectedStatus = tempStatus;
                            _selectedApplicationStatus = tempApplicationStatus;
                            _selectedContactStatus = tempContactStatus;
                            _selectedMeetingStatus = tempMeetingStatus;
                            _selectedCallStatus = tempCallStatus;
                            _selectedDecisionStatus = tempDecisionStatus;
                            _selectedDocumentsStatus = tempDocumentsStatus;
                            _selectedDepartmentId = tempDepartmentId;
                            _selectedStudyForm = tempStudyForm;
                            _selectedStudyBasis = tempStudyBasis;
                            _selectedConsentStatus = tempConsentStatus;
                            _sortBy = tempSortBy;
                            _sortDescending = tempSortDescending;
                          });
                          _applyFiltersAndSort();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: accentBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Применить', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMultiSelectFilter({
    required String title,
    required List<Map<String, dynamic>> options,
    required Set<String> selectedValues,
    required Function(String, bool) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('Все'),
              selected: selectedValues.isEmpty,
              onSelected: (_) {
                for (var opt in options) {
                  final value = opt['value'].toString();
                  if (selectedValues.contains(value)) {
                    onChanged(value, false);
                  }
                }
              },
              backgroundColor: Colors.grey.shade200,
              selectedColor: accentBlue.withOpacity(0.2),
            ),
            ...options.map((opt) {
              final value = opt['value'].toString();
              final isSelected = selectedValues.contains(value);
              return FilterChip(
                label: Text(opt['label']),
                selected: isSelected,
                onSelected: (selected) => onChanged(value, selected),
                backgroundColor: Colors.grey.shade200,
                selectedColor: (opt['color'] as Color?)?.withOpacity(0.2) ?? accentBlue.withOpacity(0.2),
                checkmarkColor: opt['color'] ?? accentBlue,
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterSelect({
    required String title,
    required dynamic value,
    required List<Map<String, dynamic>> options,
    required Function(dynamic) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<dynamic>(
                value: value,
                isExpanded: true,
                hint: Text('Выберите $title', style: const TextStyle(color: greyText)),
                icon: const Icon(Icons.arrow_drop_down, color: accentBlue),
                alignment: AlignmentDirectional.centerStart,
                items: options.map((opt) {
                  return DropdownMenuItem<dynamic>(
                    value: opt['value'],
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      opt['label'],
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.start,
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getProfileNames(Set<String> profileNames) {
    if (profileNames.isEmpty) return '';
    return profileNames.join(', ');
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active': return successGreen;
      case 'inactive': return errorRed;
      case 'enrolled': return accentBlue;
      default: return neutralGray;
    }
  }

  String _getStatusDisplayName(String? status) {
    switch (status?.toLowerCase()) {
      case 'active': return 'Активный';
      case 'inactive': return 'Неактивный';
      case 'enrolled': return 'Зачислен';
      default: return status ?? '—';
    }
  }

  String getApplicationStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending': return 'Ожидает';
      case 'accepted': return 'Принято';
      case 'rejected': return 'Отклонено';
      case 'paid': return 'Оплачено';
      default: return status ?? '—';
    }
  }

  String _getApplicationStatusDisplayName(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending': return 'Ожидает';
      case 'accepted': return 'Принято';
      case 'rejected': return 'Отклонено';
      case 'paid': return 'Оплачено';
      default: return status ?? '—';
    }
  }

  Color _getApplicationStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending': return warningOrange;
      case 'accepted': return successGreen;
      case 'rejected': return errorRed;
      case 'paid': return accentBlue;
      default: return neutralGray;
    }
  }

  String _getContactStatusDisplayName(String? status) {
    switch (status?.toLowerCase()) {
      case 'new': return 'Новый';
      case 'met': return 'Встретились';
      case 'interested': return 'Заинтересован';
      case 'original_submitted': return 'Подан оригинал';
      case 'waiting_original': return 'Ждем оригинал';
      case 'not_interested': return 'Не заинтересован';
      default: return status ?? '—';
    }
  }

  Color _getContactStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'new': return neutralGray;
      case 'met': return successGreen;
      case 'interested': return const Color(0xFF8BC34A);
      case 'original_submitted': return accentBlue;
      case 'waiting_original': return warningOrange;
      case 'not_interested': return errorRed;
      default: return neutralGray;
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 200) return successGreen;
    if (score >= 150) return warningOrange;
    return errorRed;
  }

  Widget _buildActiveFilterChip({
    required String label,
    required Color color,
    required VoidCallback onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
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

  List<Student> _getPaginatedStudents() {
    final start = _page * _rowsPerPage;
    final end = start + _rowsPerPage;
    if (start >= filteredStudents.length) {
      return [];
    }
    return filteredStudents.sublist(start, end > filteredStudents.length ? filteredStudents.length : end);
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = _getActiveFiltersCount() > 0;
    final paginatedStudents = _getPaginatedStudents();
    final totalPages = filteredStudents.isEmpty ? 1 : (filteredStudents.length / _rowsPerPage).ceil();
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Абитуриенты',
          style: TextStyle(
            color: accentBlue,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.6),
          child: Container(
            height: 0.6,
            color: blackBorder,
          ),
        ),
        actions: [
          if (_activeContact != null)
                GestureDetector(
      onTap: () async {
        final contactType = _activeContact!['type']?.toLowerCase() ?? '';
        final contactValue = _activeContact!['value'] ?? '';
        
        // Используем ContactService как в карточке студента
            switch (contactType) {
              case 'telegram':
                await ContactService.openTelegram(contactValue, 'Активный контакт');
                break;
              case 'url':
                await ContactService.openUrl(contactValue);
                break;
              case 'call':
                await ContactService.makeCall(contactValue);
                break;
              case 'sms':
                await ContactService.sendSms(contactValue);
                break;
              default:
                print('Неизвестный тип контакта: $contactType');
            }
          },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Image.asset(
                  'assets/icons/link.png',
                  width: 24,
                  height: 24,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () async {
                try {
                  await _studentService.runParser();
                  _showSuccessSnackbar('Парсер запущен');
                  await _refreshStudents();
                } catch (e) {
                  _showErrorSnackbar('Ошибка запуска парсера');
                }
              },
              child: Image.asset(
                'assets/icons/parse2.png',
                width: 28,
                height: 28,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                ).then((_) => _refreshAllData());
              },
              child: Image.asset(
                'assets/icons/profile3.png',
                width: 28,
                height: 28,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading && students.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: Colors.red),
                      const SizedBox(height: 20),
                      Text(_errorMessage, textAlign: TextAlign.center),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: _loadUserAndStudents,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Попробовать снова'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: blackBorder, width: 0.6),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Поиск по ФИО, телефону, ID',
                            hintStyle: const TextStyle(color: greyText),
                            prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                            suffixIcon: Stack(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.filter_list,
                                    color: hasActiveFilters ? accentBlue : Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: _showFilterDialog,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                if (hasActiveFilters)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: accentBlue,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          onChanged: (value) => _applyFiltersAndSort(),
                        ),
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Всего: ${students.length}',
                            style: const TextStyle(color: greyText, fontSize: 12),
                          ),
                          if (filteredStudents.length != students.length)
                            Text(
                              'Показано: ${filteredStudents.length}',
                              style: TextStyle(color: accentBlue, fontSize: 12),
                            ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _sortDescending = !_sortDescending;
                                _applyFiltersAndSort();
                              });
                            },
                            child: Row(
                              children: [
                                Text(
                                  _sortBy == 'score' ? 'По баллам' : (_sortBy == 'name' ? 'По имени' : 'По ID'),
                                  style: const TextStyle(color: greyText, fontSize: 12),
                                ),
                                Icon(
                                  _sortDescending ? Icons.arrow_downward : Icons.arrow_upward,
                                  size: 12,
                                  color: greyText,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    if (hasActiveFilters)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (_selectedProfileNames.isNotEmpty)
                                _buildActiveFilterChip(
                                  label: 'Профили: ${_getProfileNames(_selectedProfileNames)}',
                                  color: accentBlue,
                                  onDelete: () {
                                    setState(() {
                                      _selectedProfileNames.clear();
                                    });
                                    _applyFiltersAndSort();
                                  },
                                ),
                              if (_selectedSpecialityNames.isNotEmpty)
                                _buildActiveFilterChip(
                                  label: 'Специальности: ${_selectedSpecialityNames.join(", ")}',
                                  color: Colors.purple,
                                  onDelete: () {
                                    setState(() {
                                      _selectedSpecialityNames.clear();
                                    });
                                    _applyFiltersAndSort();
                                  },
                                ),
                              if (_selectedStatus != null)
                                _buildActiveFilterChip(
                                  label: 'Статус: ${_getStatusDisplayName(_selectedStatus)}',
                                  color: _getStatusColor(_selectedStatus),
                                  onDelete: () {
                                    setState(() {
                                      _selectedStatus = null;
                                    });
                                    _applyFiltersAndSort();
                                  },
                                ),
                              if (_selectedApplicationStatus != null)
                                _buildActiveFilterChip(
                                  label: 'Заявление: ${_getApplicationStatusDisplayName(_selectedApplicationStatus)}',
                                  color: _getApplicationStatusColor(_selectedApplicationStatus),
                                  onDelete: () {
                                    setState(() {
                                      _selectedApplicationStatus = null;
                                    });
                                    _applyFiltersAndSort();
                                  },
                                ),
                              if (_selectedContactStatus != null)
                                _buildActiveFilterChip(
                                  label: 'Контакт: ${_getContactStatusDisplayName(_selectedContactStatus)}',
                                  color: _getContactStatusColor(_selectedContactStatus),
                                  onDelete: () {
                                    setState(() {
                                      _selectedContactStatus = null;
                                    });
                                    _applyFiltersAndSort();
                                  },
                                ),
                              if (_selectedMeetingStatus != null)
                                _buildActiveFilterChip(
                                  label: 'Встреча: ${_meetingStatusOptions.firstWhere((o) => o['value'] == _selectedMeetingStatus)['label']}',
                                  color: _meetingStatusOptions.firstWhere((o) => o['value'] == _selectedMeetingStatus)['color'],
                                  onDelete: () {
                                    setState(() {
                                      _selectedMeetingStatus = null;
                                    });
                                    _applyFiltersAndSort();
                                  },
                                ),
                              if (_selectedCallStatus != null)
                                _buildActiveFilterChip(
                                  label: 'Дозвон: ${_callStatusOptions.firstWhere((o) => o['value'] == _selectedCallStatus)['label']}',
                                  color: _callStatusOptions.firstWhere((o) => o['value'] == _selectedCallStatus)['color'],
                                  onDelete: () {
                                    setState(() {
                                      _selectedCallStatus = null;
                                    });
                                    _applyFiltersAndSort();
                                  },
                                ),
                              if (_selectedDecisionStatus != null)
                                _buildActiveFilterChip(
                                  label: 'Решение: ${_decisionStatusOptions.firstWhere((o) => o['value'] == _selectedDecisionStatus)['label']}',
                                  color: _decisionStatusOptions.firstWhere((o) => o['value'] == _selectedDecisionStatus)['color'],
                                  onDelete: () {
                                    setState(() {
                                      _selectedDecisionStatus = null;
                                    });
                                    _applyFiltersAndSort();
                                  },
                                ),
                              if (_selectedDocumentsStatus != null)
                                _buildActiveFilterChip(
                                  label: 'Документы: ${_documentsStatusOptions.firstWhere((o) => o['value'] == _selectedDocumentsStatus)['label']}',
                                  color: _documentsStatusOptions.firstWhere((o) => o['value'] == _selectedDocumentsStatus)['color'],
                                  onDelete: () {
                                    setState(() {
                                      _selectedDocumentsStatus = null;
                                    });
                                    _applyFiltersAndSort();
                                  },
                                ),
                              if (_selectedDepartmentId != null)
                                _buildActiveFilterChip(
                                  label: 'Направление: ${_getDepartmentName(_selectedDepartmentId!)}',
                                  color: Colors.blue,
                                  onDelete: () {
                                    setState(() {
                                      _selectedDepartmentId = null;
                                    });
                                    _applyFiltersAndSort();
                                  },
                                ),
                              if (_selectedStudyForm != null)
                                _buildActiveFilterChip(
                                  label: 'Форма: $_selectedStudyForm',
                                  color: Colors.blueGrey,
                                  onDelete: () {
                                    setState(() {
                                      _selectedStudyForm = null;
                                    });
                                    _applyFiltersAndSort();
                                  },
                                ),
                              if (_selectedStudyBasis != null)
                                _buildActiveFilterChip(
                                  label: 'Основа: $_selectedStudyBasis',
                                  color: Colors.teal,
                                  onDelete: () {
                                    setState(() {
                                      _selectedStudyBasis = null;
                                    });
                                    _applyFiltersAndSort();
                                  },
                                ),
                              if (_selectedConsentStatus != null)
                                _buildActiveFilterChip(
                                  label: _selectedConsentStatus! ? 'Согласие получено' : 'Согласие не получено',
                                  color: _selectedConsentStatus! ? successGreen : errorRed,
                                  onDelete: () {
                                    setState(() {
                                      _selectedConsentStatus = null;
                                    });
                                    _applyFiltersAndSort();
                                  },
                                ),
                              TextButton(
                                onPressed: _clearFilters,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: Size.zero,
                                  foregroundColor: accentBlue,
                                ),
                                child: const Text('Очистить все'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 8),
                    
                    Expanded(
                      child: filteredStudents.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline, size: 80, color: Colors.grey.shade400),
                                  const SizedBox(height: 20),
                                  const Text('Студенты не найдены', style: TextStyle(fontSize: 18, color: Colors.grey)),
                                  if (hasActiveFilters)
                                    Column(
                                      children: [
                                        const SizedBox(height: 10),
                                        const Text('Попробуйте изменить фильтры', style: TextStyle(fontSize: 14, color: Colors.grey)),
                                        const SizedBox(height: 10),
                                        ElevatedButton(
                                          onPressed: _clearFilters,
                                          style: ElevatedButton.styleFrom(backgroundColor: accentBlue),
                                          child: const Text('Сбросить фильтры'),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _refreshStudents,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                                itemCount: paginatedStudents.length,
                                itemBuilder: (context, index) => _buildStudentCard(paginatedStudents[index]),
                              ),
                            ),
                    ),
                      Padding(
                        padding: const EdgeInsets.only(top: 0, bottom: 45),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.first_page),
                              onPressed: _page > 0 ? () {
                                setState(() {
                                  _page = 0;
                                });
                              } : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: _page > 0 ? () {
                                setState(() {
                                  _page--;
                                });
                              } : null,
                            ),
                            Text(
                              '${_page + 1} / $totalPages',
                              style: const TextStyle(fontSize: 14),
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: _page < totalPages - 1 ? () {
                                setState(() {
                                  _page++;
                                });
                              } : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.last_page),
                              onPressed: _page < totalPages - 1 ? () {
                                setState(() {
                                  _page = totalPages - 1;
                                });
                              } : null,
                            ),
                            const SizedBox(width: 16),
                            DropdownButton<int>(
                              value: _rowsPerPage,
                              items: _rowsPerPageOptions.map((value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text('$value на стр.'),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _rowsPerPage = newValue;
                                    _page = 0;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 40), // чуть выше
            child: FloatingActionButton(
              onPressed: () => _navigateToAddStudent(),
              backgroundColor: accentBlue,
              child: const Icon(Icons.add, color: Colors.white, size: 32),
              tooltip: 'Добавить студента',
            ),
          ),
    );
  }

  Widget _buildStudentCard(Student student) {
  final documentsStatusOpt = _documentsStatusOptions.firstWhere(
    (o) => o['value'] == student.documentsStatus?.toLowerCase(),
    orElse: () => {'label': 'Нет заявл.', 'color': neutralGray, 'bgColor': neutralGrayBg},
  );
  final meetingStatusOpt = _meetingStatusOptions.firstWhere(
    (o) => o['value'] == student.meetingStatus?.toLowerCase(),
    orElse: () => {'label': 'Не был на сборе', 'color': errorRed, 'bgColor': errorRedBg},
  );
  final callStatusOpt = _callStatusOptions.firstWhere(
    (o) => o['value'] == student.callStatus?.toLowerCase(),
    orElse: () => {'label': 'Не дозвонились', 'color': errorRed, 'bgColor': errorRedBg},
  );
  final decisionStatusOpt = _decisionStatusOptions.firstWhere(
    (o) => o['value'] == student.decisionStatus?.toLowerCase(),
    orElse: () => {'label': 'Думает', 'color': neutralGray, 'bgColor': neutralGrayBg},
  );
  
  final hasPriorContact = student.priorContact != null && student.priorContact!.isNotEmpty;
  final contactType = _getContactTypeFromPrior(student.priorContact);
  final isUrlContact = contactType == 'url';
  final hasUrl = student.additionalContacts?.containsKey('url') == true &&
                 student.additionalContacts!['url']!.isNotEmpty;
  final canContact = !isUrlContact || hasUrl;
  
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(0),
      side: BorderSide(color: borderColor, width: 2),
    ),
    child: InkWell(
      onTap: () => _navigateToStudentDetail(student),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Верхняя строка: имя и баллы
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    student.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: accentBlue,
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${student.totalScore}',
                      style: TextStyle(
                        color: _getScoreColor(student.totalScore!),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Блок статусов 2x2 и кнопки справа
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Статусы 2x2
                Column(
                      children: [
                        Row(
                          children: [
                            _buildRoundStatusChip(label: documentsStatusOpt['label'], color: documentsStatusOpt['color']),
                            _buildRoundStatusChip(label: meetingStatusOpt['label'], color: meetingStatusOpt['color']),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildRoundStatusChip(label: callStatusOpt['label'], color: callStatusOpt['color']),
                            _buildRoundStatusChip(label: decisionStatusOpt['label'], color: decisionStatusOpt['color']),
                          ],
                        ),
                      ],
                    ),
                // Кнопки справа
                const SizedBox(width: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (hasPriorContact && canContact)
                      Padding(
                        padding: const EdgeInsets.only(top: 25),
                        child: IconButton(
                          icon: _getPriorContactIconWidget(student.priorContact),
                          onPressed: () {
                            switch (contactType) {
                              case 'telegram':
                                final telegram = student.additionalContacts?['telegram'] ?? student.phone;
                                ContactService.openTelegram(telegram, student.fullName);
                                break;
                              case 'sms':
                                ContactService.sendSms(student.phone);
                                break;
                              case 'call':
                                ContactService.makeCall(student.phone);
                                break;
                              case 'url':
                            final url = student.additionalContacts?['url'];
                            if (url != null && url.isNotEmpty) {
                              ContactService.openUrl(url);
                            } else {
                              _showErrorSnackbar('Ссылка не указана');
                            }
                            break;
                        }
                      },
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              )
            else
              const SizedBox(width: 60, height: 48),
                      Align(
                      alignment: Alignment.centerRight,
                      child: PopupMenuButton<String>(
                        icon: Container(
                          width: 10,
                          height: 40,
                          alignment: Alignment.center,
                          child: Image.asset(
                            'assets/icons/threepoints.png',
                            height: 40,
                            width: 10,
                            errorBuilder: (context, error, stackTrace) => 
                                const Icon(Icons.more_vert, size: 24),
                          ),
                        ),
                        offset: const Offset(40, 80),
                      onSelected: (value) => _handleContactAction(value, student),
                      itemBuilder: (context) {
                        final hasTelegram = student.additionalContacts?.containsKey('telegram') == true &&
                                            student.additionalContacts!['telegram']!.isNotEmpty;
                        final hasUrlInAdditional = student.additionalContacts?.containsKey('url') == true &&
                                                    student.additionalContacts!['url']!.isNotEmpty;
                        
                        return [
                          const PopupMenuItem(
                            value: 'call',
                            child: Row(
                              children: [
                                Icon(Icons.phone, color: Colors.green, size: 20),
                                SizedBox(width: 12),
                                Text('Позвонить'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'sms',
                            child: Row(
                              children: [
                                Icon(Icons.sms, color: Colors.blue, size: 20),
                                SizedBox(width: 12),
                                Text('SMS'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'telegram',
                            child: Row(
                              children: [
                                Icon(Icons.telegram, color: const Color(0xFF26A5E4), size: 20),
                                const SizedBox(width: 12),
                                Text(hasTelegram ? 'Telegram (из доп. контактов)' : 'Telegram'),
                              ],
                            ),
                          ),
                          if (hasUrlInAdditional)
                            const PopupMenuItem(
                              value: 'url',
                              child: Row(
                                children: [
                                  Icon(Icons.link, color: Colors.purple, size: 20),
                                  SizedBox(width: 12),
                                  Text('Открыть ссылку'),
                                ],
                              ),
                            ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'add_contact',
                            child: Row(
                              children: [
                                Icon(Icons.contact_page, color: Colors.orange, size: 20),
                                SizedBox(width: 12),
                                Text('В контакты'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete, color: Colors.red, size: 20),
                                const SizedBox(width: 12),
                                const Text('Удалить'),
                              ],
                            ),
                          ),
                        ];
                      },
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

// Круглые статусы (как на DetailPage)
Widget _buildRoundStatusChip({required String label, required Color color}) {
  return SizedBox(
    width: 100, 
    height: 30,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ),
  );
}
  void _handleContactAction(String value, Student student) {
    switch (value) {
      case 'call':
        ContactService.makeCall(student.phone);
        break;
      case 'sms':
        ContactService.sendSms(student.phone);
        break;
      case 'telegram':
        if (student.additionalContacts?.containsKey('telegram') == true &&
            student.additionalContacts!['telegram']!.isNotEmpty) {
          ContactService.openTelegram(student.additionalContacts!['telegram']!, student.fullName);
        } else {
          ContactService.openTelegram(student.phone, student.fullName);
        }
        break;
      case 'url':
        final url = student.additionalContacts?['url'];
        if (url != null && url.isNotEmpty) {
          ContactService.openUrl(url);
        } else {
          _showErrorSnackbar('Ссылка не указана');
        }
        break;
      case 'add_contact':
        ContactService.addContactToPhone(student);
        break;
      case 'delete':
        _deleteStudent(student.id);
        break;
    }
  }

  void _navigateToStudentDetail(Student student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentDetailPage(student: student),
      ),
    ).then((_) {
      _refreshAllData();
    });
  }

  void _navigateToAddStudent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddStudentPage(onAdd: _addStudent),
      ),
    ).then((_) {
      _refreshAllData();
    });
  }

  Future<void> _addStudent(Map<String, dynamic> studentData) async {
    try {
      setState(() => _isLoading = true);
      
      final createdStudent = await _studentService.createStudent(studentData);
      setState(() {
        students.add(createdStudent);
        _applyFiltersAndSort();
        _isLoading = false;
      });
      
      if (mounted) {
        Navigator.pop(context);
        _showSuccessSnackbar('Студент добавлен');
        await _refreshAllData();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorSnackbar('Ошибка добавления студента: $e');
      }
    }
  }
}