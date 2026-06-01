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
const Color errorRed = Color(0xFFFF383C);
const Color neutralGray = Color(0xFFA0A0A0);
const Color warningOrange = Color(0xFFFF9800);

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
    {'value': 'unknown', 'label': 'Не указано', 'color': neutralGray},
    {'value': 'not_met', 'label': 'Не был на сборе', 'color': errorRed},
    {'value': 'met', 'label': 'Был на сборе', 'color': successGreen},
  ];
  
  final List<Map<String, dynamic>> _callStatusOptions = [
    {'value': 'unknown', 'label': 'Не указано', 'color': neutralGray},
    {'value': 'not_reached', 'label': 'Не дозвонились', 'color': errorRed},
    {'value': 'reached', 'label': 'Дозвонились', 'color': successGreen},
  ];
  
  final List<Map<String, dynamic>> _decisionStatusOptions = [
    {'value': 'unknown', 'label': 'Не указано', 'color': neutralGray},
    {'value': 'thinking', 'label': 'Думает', 'color': warningOrange},
    {'value': 'decided', 'label': 'Решил', 'color': successGreen},
    {'value': 'denied', 'label': 'Отказано', 'color': errorRed},
  ];
  
  final List<Map<String, dynamic>> _documentsStatusOptions = [
    {'value': 'unknown', 'label': 'Не указано', 'color': neutralGray},
    {'value': 'not_submitted', 'label': 'Нет заявл.', 'color': neutralGray},
    {'value': 'original_submitted', 'label': 'Подан оригинал', 'color': successGreen},
    {'value': 'waiting_original', 'label': 'Ждем оригинал', 'color': warningOrange},
    {'value': 'enrolled', 'label': 'Зачислен', 'color': accentBlue},
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

  String _getMeetingStatusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'met': return 'Был на сборе';
      case 'not_met': return 'Не был на сборе';
      case 'unknown': return 'Не указано';
      default: return 'Не указано';
    }
  }

  Color _getMeetingStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'met': return successGreen;
      case 'not_met': return errorRed;
      default: return neutralGray;
    }
  }

  String _getCallStatusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'reached': return 'Дозвонились';
      case 'not_reached': return 'Не дозвонились';
      case 'unknown': return 'Не указано';
      default: return 'Не указано';
    }
  }

  Color _getCallStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'reached': return successGreen;
      case 'not_reached': return errorRed;
      default: return neutralGray;
    }
  }

  String _getDecisionStatusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'decided': return 'Решил';
      case 'thinking': return 'Думает';
      case 'denied': return 'Отказано';
      case 'unknown': return 'Не указано';
      default: return 'Не указано';
    }
  }

  Color _getDecisionStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'decided': return successGreen;
      case 'thinking': return warningOrange;
      case 'denied': return errorRed;
      default: return neutralGray;
    }
  }

  String _getDocumentsStatusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'original_submitted': return 'Подан оригинал';
      case 'waiting_original': return 'Ждем оригинал';
      case 'enrolled': return 'Зачислен';
      case 'not_submitted': return 'Нет заявл.';
      case 'unknown': return 'Не указано';
      default: return 'Не указано';
    }
  }

  Color _getDocumentsStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'original_submitted': return successGreen;
      case 'waiting_original': return warningOrange;
      case 'enrolled': return accentBlue;
      default: return neutralGray;
    }
  }

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

  Widget _getPriorContactIconWidget(String? priorContact) {
    if (priorContact == null || priorContact.isEmpty) {
      return const SizedBox(width: 36, height: 36);
    }
    
    final contactType = _getContactTypeFromPrior(priorContact);
    switch (contactType) {
      case 'telegram':
        return Container(
          width: 36,
          height: 36,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF26A5E4).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.asset(
            'assets/icons/telegram.png',
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) => 
                const Icon(Icons.telegram, size: 24, color: Color(0xFF26A5E4)),
          ),
        );
      case 'sms':
        return Container(
          width: 36,
          height: 36,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.asset(
            'assets/icons/sms.png',
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) => 
                const Icon(Icons.sms, size: 24, color: Colors.blue),
          ),
        );
      case 'call':
        return Container(
          width: 36,
          height: 36,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.asset(
            'assets/icons/phone.png',
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) => 
                const Icon(Icons.phone, size: 24, color: Colors.green),
          ),
        );
      case 'url':
        return Container(
          width: 36,
          height: 36,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Image.asset(
            'assets/icons/link2.png',
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) => 
                const Icon(Icons.link, size: 24, color: Colors.purple),
          ),
        );
      default:
        return const SizedBox(width: 36, height: 36);
    }
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
    
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      result = result.where((student) {
        return student.fullName.toLowerCase().contains(query) ||
            student.phone.toLowerCase().contains(query) ||
            student.russianStudentId.toString().contains(query);
      }).toList();
    }
    
    if (_selectedProfileNames.isNotEmpty) {
      result = result.where((student) {
        final applications = _studentApplications[student.id];
        if (applications == null || applications.isEmpty) return false;
        return _selectedProfileNames.any((profileName) => 
            applications.any((app) => app.profileName == profileName));
      }).toList();
    }
    
    if (_selectedSpecialityNames.isNotEmpty) {
      result = result.where((student) {
        final applications = _studentApplications[student.id];
        if (applications == null || applications.isEmpty) return false;
        return _selectedSpecialityNames.any((specialityName) => 
            applications.any((app) => app.specialityName == specialityName));
      }).toList();
    }
    
    if (_selectedStatus != null) {
      result = result.where((student) => 
          student.status?.toLowerCase() == _selectedStatus).toList();
    }
    
    if (_selectedApplicationStatus != null) {
      result = result.where((student) {
        final applications = _studentApplications[student.id];
        if (applications == null) return false;
        return applications.any((app) => 
            app.applicationStatus?.toLowerCase() == _selectedApplicationStatus);
      }).toList();
    }
    
    if (_selectedContactStatus != null) {
      result = result.where((student) => 
          student.contactStatus?.toLowerCase() == _selectedContactStatus).toList();
    }
    
    if (_selectedMeetingStatus != null) {
      result = result.where((student) => 
          (student.meetingStatus?.toLowerCase() ?? 'unknown') == _selectedMeetingStatus).toList();
    }
    
    if (_selectedCallStatus != null) {
      result = result.where((student) => 
          (student.callStatus?.toLowerCase() ?? 'unknown') == _selectedCallStatus).toList();
    }
    
    if (_selectedDecisionStatus != null) {
      result = result.where((student) => 
          (student.decisionStatus?.toLowerCase() ?? 'unknown') == _selectedDecisionStatus).toList();
    }
    
    if (_selectedDocumentsStatus != null) {
      result = result.where((student) => 
          (student.documentsStatus?.toLowerCase() ?? 'unknown') == _selectedDocumentsStatus).toList();
    }
    
    if (_selectedDepartmentId != null) {
      result = result.where((student) => 
          student.departmentId == _selectedDepartmentId).toList();
    }
    
    if (_selectedStudyForm != null) {
      result = result.where((student) => 
          student.studyForm == _selectedStudyForm).toList();
    }
    
    if (_selectedStudyBasis != null) {
      result = result.where((student) => 
          student.studyBasis == _selectedStudyBasis).toList();
    }
    
    if (_selectedConsentStatus != null) {
      result = result.where((student) => 
          student.consentStatus == _selectedConsentStatus).toList();
    }
    
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
                left: 16,
                right: 16,
                top: 16,
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
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    const SizedBox(height: 16),
                    
                    const Text('Сортировка', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
                    
                    const Divider(height: 20),
                    
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
                    
                    if (allProfileNames.isNotEmpty) const SizedBox(height: 12),
                    
                    if (_allSpecialityNames.isNotEmpty)
                      _buildMultiSelectFilter(
                        title: 'Специальности',
                        options: _allSpecialityNames.map((name) => ({
                          'value': name,
                          'label': name,
                          'color': Colors.purple,
                        })).toList(),
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
                    
                    if (_allSpecialityNames.isNotEmpty) const SizedBox(height: 12),
                    
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
                    
                    const SizedBox(height: 12),
                    
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
                    
                    const SizedBox(height: 12),
                    
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
                    
                    const SizedBox(height: 12),
                    
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
                    
                    const Divider(height: 20),
                    
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
                    
                    const SizedBox(height: 12),
                    
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
                    
                    const SizedBox(height: 12),
                    
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
                    
                    const SizedBox(height: 12),
                    
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
                    
                    const SizedBox(height: 24),
                    
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
          spacing: 6,
          runSpacing: 6,
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
                label: Text(opt['label'], style: const TextStyle(fontSize: 12)),
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
      margin: const EdgeInsets.only(right: 6, bottom: 6),
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
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.close, size: 12, color: color),
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
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          if (_activeContact != null)
            GestureDetector(
              onTap: () async {
                final contactType = _activeContact!['type']?.toLowerCase() ?? '';
                final contactValue = _activeContact!['value'] ?? '';
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
                  width: 22,
                  height: 22,
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
                width: 26,
                height: 26,
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
                width: 26,
                height: 26,
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
                      padding: const EdgeInsets.all(12),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: blackBorder, width: 0.6),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Поиск по ФИО, телефону, ID',
                            hintStyle: const TextStyle(color: greyText, fontSize: 14),
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (value) => _applyFiltersAndSort(),
                        ),
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
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
                                  label: 'Встреча: ${_getMeetingStatusLabel(_selectedMeetingStatus)}',
                                  color: _getMeetingStatusColor(_selectedMeetingStatus),
                                  onDelete: () {
                                    setState(() {
                                      _selectedMeetingStatus = null;
                                    });
                                    _applyFiltersAndSort();
                                  },
                                ),
                              if (_selectedCallStatus != null)
                                _buildActiveFilterChip(
                                  label: 'Дозвон: ${_getCallStatusLabel(_selectedCallStatus)}',
                                  color: _getCallStatusColor(_selectedCallStatus),
                                  onDelete: () {
                                    setState(() {
                                      _selectedCallStatus = null;
                                    });
                                    _applyFiltersAndSort();
                                  },
                                ),
                              if (_selectedDecisionStatus != null)
                                _buildActiveFilterChip(
                                  label: 'Решение: ${_getDecisionStatusLabel(_selectedDecisionStatus)}',
                                  color: _getDecisionStatusColor(_selectedDecisionStatus),
                                  onDelete: () {
                                    setState(() {
                                      _selectedDecisionStatus = null;
                                    });
                                    _applyFiltersAndSort();
                                  },
                                ),
                              if (_selectedDocumentsStatus != null)
                                _buildActiveFilterChip(
                                  label: 'Документы: ${_getDocumentsStatusLabel(_selectedDocumentsStatus)}',
                                  color: _getDocumentsStatusColor(_selectedDocumentsStatus),
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
                                child: const Text('Очистить все', style: TextStyle(fontSize: 11)),
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
                                  Icon(Icons.people_outline, size: 60, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  const Text('Студенты не найдены', style: TextStyle(fontSize: 16, color: Colors.grey)),
                                  if (hasActiveFilters)
                                    Column(
                                      children: [
                                        const SizedBox(height: 8),
                                        const Text('Попробуйте изменить фильтры', style: TextStyle(fontSize: 13, color: Colors.grey)),
                                        const SizedBox(height: 8),
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
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                                itemCount: paginatedStudents.length,
                                itemBuilder: (context, index) => _buildStudentCard(paginatedStudents[index]),
                              ),
                            ),
                    ),
                    
                    // Пагинация
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: borderColor, width: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.first_page, size: 20),
                            onPressed: _page > 0 ? () {
                              setState(() {
                                _page = 0;
                              });
                            } : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_left, size: 20),
                            onPressed: _page > 0 ? () {
                              setState(() {
                                _page--;
                              });
                            } : null,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: accentBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_page + 1} / $totalPages',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, size: 20),
                            onPressed: _page < totalPages - 1 ? () {
                              setState(() {
                                _page++;
                              });
                            } : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.last_page, size: 20),
                            onPressed: _page < totalPages - 1 ? () {
                              setState(() {
                                _page = totalPages - 1;
                              });
                            } : null,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: borderColor),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<int>(
                              value: _rowsPerPage,
                              items: _rowsPerPageOptions.map((value) {
                                return DropdownMenuItem<int>(
                                  value: value,
                                  child: Text('по $value', style: const TextStyle(fontSize: 13)),
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
                              underline: const SizedBox(),
                              icon: const Icon(Icons.arrow_drop_down, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: FloatingActionButton(
          onPressed: () => _navigateToAddStudent(),
          backgroundColor: accentBlue,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
          tooltip: 'Добавить студента',
        ),
      ),
    );
  }

  Widget _buildStudentCard(Student student) {
    final documentsLabel = _getDocumentsStatusLabel(student.documentsStatus);
    final documentsColor = _getDocumentsStatusColor(student.documentsStatus);
    
    final meetingLabel = _getMeetingStatusLabel(student.meetingStatus);
    final meetingColor = _getMeetingStatusColor(student.meetingStatus);
    
    final callLabel = _getCallStatusLabel(student.callStatus);
    final callColor = _getCallStatusColor(student.callStatus);
    
    final decisionLabel = _getDecisionStatusLabel(student.decisionStatus);
    final decisionColor = _getDecisionStatusColor(student.decisionStatus);
    
    final hasPriorContact = student.priorContact != null && student.priorContact!.isNotEmpty;
    final contactType = _getContactTypeFromPrior(student.priorContact);
    final isUrlContact = contactType == 'url';
    final hasUrl = student.additionalContacts?.containsKey('url') == true &&
                   student.additionalContacts!['url']!.isNotEmpty;
    final canContact = !isUrlContact || hasUrl;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: InkWell(
        onTap: () => _navigateToStudentDetail(student),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Верхняя строка: ФИО и баллы
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      student.fullName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: accentBlue,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (student.totalScore != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getScoreColor(student.totalScore!).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${student.totalScore}',
                        style: TextStyle(
                          color: _getScoreColor(student.totalScore!),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 10),
              
              // Статусы 2x2 и кнопки в одном ряду
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Статусы 2x2 - занимают 2/3 ширины
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildStatusChip(label: documentsLabel, color: documentsColor)),
                            const SizedBox(width: 6),
                            Expanded(child: _buildStatusChip(label: meetingLabel, color: meetingColor)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(child: _buildStatusChip(label: callLabel, color: callColor)),
                            const SizedBox(width: 6),
                            Expanded(child: _buildStatusChip(label: decisionLabel, color: decisionColor)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 10),
                  
                  // Кнопка контакта и меню - занимают 1/3 ширины
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (hasPriorContact && canContact)
                          GestureDetector(
                            onTap: () {
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
                            child: _getPriorContactIconWidget(student.priorContact),
                          ),
                        PopupMenuButton<String>(
                          icon: Image.asset(
                            'assets/icons/threepoints.png',
                            height: 24,
                            width: 24,
                            errorBuilder: (context, error, stackTrace) => 
                                const Icon(Icons.more_vert, size: 20),
                          ),
                          offset: const Offset(0, 40),
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
                                    Icon(Icons.phone, color: Colors.green, size: 18),
                                    SizedBox(width: 10),
                                    Text('Позвонить'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'sms',
                                child: Row(
                                  children: [
                                    Icon(Icons.sms, color: Colors.blue, size: 18),
                                    SizedBox(width: 10),
                                    Text('SMS'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'telegram',
                                child: Row(
                                  children: [
                                    Icon(Icons.telegram, color: const Color(0xFF26A5E4), size: 18),
                                    const SizedBox(width: 10),
                                    Text(hasTelegram ? 'Telegram (из доп. контактов)' : 'Telegram'),
                                  ],
                                ),
                              ),
                              if (hasUrlInAdditional)
                                const PopupMenuItem(
                                  value: 'url',
                                  child: Row(
                                    children: [
                                      Icon(Icons.link, color: Colors.purple, size: 18),
                                      SizedBox(width: 10),
                                      Text('Открыть ссылку'),
                                    ],
                                  ),
                                ),
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'add_contact',
                                child: Row(
                                  children: [
                                    Icon(Icons.contact_page, color: Colors.orange, size: 18),
                                    SizedBox(width: 10),
                                    Text('В контакты'),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete, color: Colors.red, size: 18),
                                    const SizedBox(width: 10),
                                    const Text('Удалить'),
                                  ],
                                ),
                              ),
                            ];
                          },
                        ),
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
  }

  Widget _buildStatusChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
        builder: (context) => AddStudentPage(
          onSuccess: _refreshAllData, 
        ),
      ),
    );
  }
}