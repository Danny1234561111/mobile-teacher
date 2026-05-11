// pages/student_detail_page.dart
import 'package:flutter/material.dart';
import '../models/student.dart';
import '../models/communication.dart';
import '../models/student_application.dart';
import '../models/group_statistics.dart';
import '../services/student_service.dart';
import '../utils/contact_service.dart';
import 'add_communication_page.dart';
import 'edit_student_page.dart';
import 'profile_page.dart';

// Цвета из Figma
const Color accentBlue = Color(0xFF0088FF);
const Color borderColor = Color(0xFFC5C6D0);
const Color successGreen = Color(0xFF34C759);
const Color errorRed = Color(0xFFFF383C);
const Color warningOrange = Color(0xFFFF9800);
const Color neutralGray = Color(0xFFA0A0A0);

class StudentDetailPage extends StatefulWidget {
  final Student student;

  const StudentDetailPage({required this.student, Key? key}) : super(key: key);

  @override
  _StudentDetailPageState createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  final StudentService _studentService = StudentService();
  List<Communication> _communications = [];
  List<StudentApplication> _applications = [];
  Map<int, Map<String, dynamic>> _competitiveInfoMap = {};
  Map<int, GroupStatistics?> _groupStatisticsMap = {};
  int? _selectedApplicationId;
  bool _loadingCommunications = false;
  bool _loadingApplications = false;
  bool _loadingCompetitive = false;
  late Student _currentStudent;
  
  // Для активного контакта
  Map<String, dynamic>? _activeContact;
  bool _isActiveContactLoading = false;

  @override
  void initState() {
    super.initState();
    _currentStudent = widget.student;
    _loadCommunications();
    _loadApplications();
    _loadActiveContact();
  }

  Future<void> _loadActiveContact() async {
    try {
      final contact = await _studentService.getActiveContact();
      setState(() {
        _activeContact = contact;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки активного контакта: $e');
    }
  }

  Future<void> _loadCommunications() async {
    setState(() => _loadingCommunications = true);
    try {
      final comms = await _studentService.getStudentCommunications(_currentStudent.id);
      setState(() {
        _communications = comms;
        _loadingCommunications = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки коммуникаций: $e');
      setState(() => _loadingCommunications = false);
    }
  }

  Future<void> _loadApplications() async {
    setState(() => _loadingApplications = true);
    try {
      final apps = await _studentService.getStudentApplications(_currentStudent.id);
      setState(() {
        _applications = apps;
        _loadingApplications = false;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки заявлений: $e');
      setState(() => _loadingApplications = false);
    }
  }

  Future<void> _loadCompetitiveInfoForApplication(StudentApplication app) async {
    setState(() {
      _selectedApplicationId = app.id;
      _loadingCompetitive = true;
    });
    try {
      final info = await _studentService.getStudentCompetitiveInfoForSpeciality(
        _currentStudent.id,
        app.specialityId,
      );
      setState(() {
        _competitiveInfoMap[app.specialityId] = info;
      });
    } catch (e) {
      debugPrint('Ошибка загрузки конкурсной информации: $e');
    } finally {
      setState(() => _loadingCompetitive = false);
    }
  }

  Future<void> _loadGroupStatistics(StudentApplication app) async {
    try {
      final allStats = await _studentService.getGroupStatistics();
      final statKey = app.profileId ?? app.specialityId;
      
      GroupStatistics? groupStat;
      if (app.profileId != null) {
        groupStat = allStats.firstWhere(
          (s) => s.profileId == app.profileId,
          orElse: () => GroupStatistics.empty(),
        );
      } else {
        final searchName = (app.specialityName ?? '').toLowerCase();
        groupStat = allStats.firstWhere(
          (s) => s.groupName.toLowerCase().contains(searchName),
          orElse: () => GroupStatistics.empty(),
        );
      }
      
      if (groupStat.groupName.isNotEmpty) {
        setState(() {
          _groupStatisticsMap[statKey] = groupStat;
        });
      }
    } catch (e) {
      debugPrint('Ошибка загрузки статистики группы: $e');
    }
  }

  void _onApplicationTap(StudentApplication app) async {
    if (_selectedApplicationId == app.id) {
      setState(() => _selectedApplicationId = null);
    } else {
      _selectedApplicationId = app.id;
      await _loadCompetitiveInfoForApplication(app);
      await _loadGroupStatistics(app);
    }
  }

  Future<void> _addCommunication(Map<String, dynamic> data) async {
    try {
      final newComm = await _studentService.createCommunication(_currentStudent.id, data);
      setState(() {
        _communications.insert(0, newComm);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Коммуникация добавлена'), backgroundColor: successGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: errorRed),
        );
      }
    }
  }

  Future<void> _updateStudent(Student updatedStudent) async {
    setState(() {
      _currentStudent = updatedStudent;
    });
    await _loadApplications();
    await _loadActiveContact();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Данные обновлены'), backgroundColor: successGreen),
      );
    }
  }

  Future<void> _toggleActiveContact() async {
    final priorContactValue = _currentStudent.priorContact;
    String? contactValue;
    
    String _getContactTypeForApi(String? priorContact) {
      if (priorContact == null || priorContact.isEmpty) return '';
      final value = priorContact.toLowerCase();
      
      if (value == 'telegram' || value == 'телеграмм') return 'telegram';
      if (value == 'messages' || value == 'sms' || value == 'просто сообщения') return 'sms';
      if (value == 'phone' || value == 'call' || value == 'звонок') return 'call';
      if (value == 'url' || value == 'ссылка') return 'url';
      
      return 'other';
    }
    
    final contactType = _getContactTypeForApi(priorContactValue);
    
    if (priorContactValue != null && priorContactValue.isNotEmpty) {
      final value = priorContactValue.toLowerCase();
      if (value == 'звонок' || value == 'call' || value == 'phone' ||
          value == 'просто сообщения' || value == 'messages' || value == 'sms') {
        contactValue = _currentStudent.phone;
      } else if (value == 'телеграмм' || value == 'telegram') {
        contactValue = _currentStudent.additionalContacts?['telegram'] ?? _currentStudent.phone;
      } else if (value == 'ссылка' || value == 'url') {
        contactValue = _currentStudent.additionalContacts?['url'];
      }
    }
    
    if (contactType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('У студента не указан приоритетный контакт'), backgroundColor: warningOrange),
      );
      return;
    }
    
    if (contactValue == null || contactValue.isEmpty) {
      String message = '';
      if (contactType == 'call' || contactType == 'sms') {
        message = 'У студента не указан номер телефона';
      } else if (contactType == 'telegram') {
        message = 'У студента не указан Telegram. Добавьте его в дополнительные контакты';
      } else if (contactType == 'url') {
        message = 'У студента не указана ссылка. Добавьте её в дополнительные контакты';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: warningOrange),
      );
      return;
    }
    
    setState(() => _isActiveContactLoading = true);
    
    try {
      final isActive = _activeContact != null && 
          _activeContact!['contact_value'] == contactValue;
      
      if (isActive) {
        await _studentService.deleteActiveContact();
        setState(() => _activeContact = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Активный контакт выключен'), backgroundColor: successGreen),
        );
      } else {
        final result = await _studentService.setActiveContact(contactType, contactValue);
        setState(() => _activeContact = result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Активный контакт включен'), backgroundColor: successGreen),
        );
      }
      await _loadActiveContact();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e'), backgroundColor: errorRed),
      );
    } finally {
      setState(() => _isActiveContactLoading = false);
    }
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'Не указано';
    return '${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getYesNo(bool? value) {
    if (value == null) return 'Не указано';
    return value ? 'Да' : 'Нет';
  }

  String _getApplicationStatusText(String? status) {
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

  String _getPriorContactDisplayName(String? priorContact) {
    if (priorContact == null || priorContact.isEmpty) return 'Не указан';
    
    final value = priorContact.toLowerCase();
    
    if (value == 'telegram' || value == 'телеграмм') return 'Telegram';
    if (value == 'messages' || value == 'sms' || value == 'просто сообщения') return 'SMS';
    if (value == 'phone' || value == 'call' || value == 'звонок') return 'Звонок';
    if (value == 'url' || value == 'ссылка') return 'Ссылка';
    
    return priorContact;
  }

  String _getMeetingStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'met': return 'Был на сборе';
      case 'not_met': return 'Не был на сборе';
      default: return status ?? 'Не указан';
    }
  }

  Color _getMeetingStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'met': return successGreen;
      case 'not_met': return errorRed;
      default: return neutralGray;
    }
  }

  String _getCallStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'reached': return 'Дозвонились';
      case 'not_reached': return 'Не дозвонились';
      default: return status ?? 'Не указан';
    }
  }

  Color _getCallStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'reached': return successGreen;
      case 'not_reached': return errorRed;
      default: return neutralGray;
    }
  }

  String _getDecisionStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'decided': return 'Решил поступать';
      case 'thinking': return 'Думает';
      default: return status ?? 'Не указан';
    }
  }

  Color _getDecisionStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'decided': return successGreen;
      case 'thinking': return warningOrange;
      default: return neutralGray;
    }
  }

  String _getDocumentsStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'original_submitted': return 'Подан оригинал';
      case 'waiting_original': return 'Ждем оригинал';
      case 'enrolled': return 'Зачислен';
      case 'not_submitted': return 'Нет заявл.';
      default: return status ?? 'Не указан';
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

  String _getContactStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'new': return 'Новый';
      case 'met': return 'Был на встрече';
      case 'interested': return 'Заинтересован';
      case 'original_submitted': return 'Подан оригинал';
      case 'waiting_original': return 'Ждем оригинал';
      case 'not_interested': return 'Не заинтересован';
      default: return status ?? 'Не указан';
    }
  }

  void _handleTelegram() {
    if (_currentStudent.additionalContacts?.containsKey('telegram') == true) {
      final telegram = _currentStudent.additionalContacts!['telegram']!;
      ContactService.openTelegram(telegram, _currentStudent.fullName);
    } else {
      ContactService.openTelegram(_currentStudent.phone, _currentStudent.fullName);
    }
  }

  void _handleUrl() {
    final url = _currentStudent.additionalContacts?['url'];
    if (url != null && url.isNotEmpty) {
      ContactService.openUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ссылка не указана'), backgroundColor: warningOrange),
      );
    }
  }

  void _handleCall() {
    if (_currentStudent.phone.isNotEmpty) {
      ContactService.callStudent(_currentStudent.phone);
    }
  }

  void _handleActiveContactClick() {
    if (_activeContact != null) {
      final contactType = _activeContact!['contact_type']?.toString().toLowerCase();
      final contactValue = _activeContact!['contact_value']?.toString();
      
      if (contactType == 'telegram') {
        ContactService.openTelegram(contactValue ?? '', _currentStudent.fullName);
      } else if (contactType == 'url') {
        if (contactValue != null && contactValue.isNotEmpty) {
          ContactService.openUrl(contactValue);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? contactValue = _getContactValueForActive();
    final bool isActiveContactEnabled = _activeContact != null && 
        _activeContact!['contact_value'] == contactValue;
    
    return Scaffold(
      backgroundColor: const Color(0xFFECF5FD),
      appBar: AppBar(
      title: Text(
        "Абитуриент",
        style: const TextStyle(color: accentBlue, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      backgroundColor: const Color(0xFFECF5FD),
      elevation: 0,
      leadingWidth: 80, // увеличиваем ширину области leading
      leading: Padding(
        padding: const EdgeInsets.only(left: 16), 
        child: IconButton(
          icon: Image.asset(
            'assets/icons/home.png',
            width: 28,
            height: 28,
            errorBuilder: (context, error, stackTrace) => 
                const Icon(Icons.home, size: 28, color: accentBlue),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        // 1. Кнопка парсера
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: () async {
              try {
                await _studentService.runParser();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Парсер запущен'), backgroundColor: successGreen),
                );
                await _loadCommunications();
                await _loadApplications();
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
        
        // 2. Кнопка профиля
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            child: Image.asset(
              'assets/icons/profile3.png',
              width: 28,
              height: 28,
              errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.person, size: 28, color: accentBlue),
            ),
          ),
        ),
        
        // 3. Кнопка звезда (активный контакт)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: _isActiveContactLoading ? null : _toggleActiveContact,
            child: Image.asset(
              isActiveContactEnabled 
                  ? 'assets/icons/star2.png' 
                  : 'assets/icons/star1.png',
              width: 24,
              height: 24,
              errorBuilder: (context, error, stackTrace) => Icon(
                isActiveContactEnabled ? Icons.star : Icons.star_border,
                color: isActiveContactEnabled ? Colors.amber : accentBlue,
                size: 24,
              ),
            ),
          ),
        ),
        
        // 4. Кнопка редактирования
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: () => _navigateToEditStudent(),
            child: Image.asset(
              'assets/icons/edit.png',
              width: 28,
              height: 28,
              errorBuilder: (context, error, stackTrace) => 
                  const Icon(Icons.edit, size: 28, color: accentBlue),
            ),
          ),
        ),
      ],
    ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildContactInfo(),
            const SizedBox(height: 16),
            _buildStudentStatuses(),
            const SizedBox(height: 16),
            _buildApplicationsSection(),
            const SizedBox(height: 16),
            _buildCommunicationsSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddCommunication(),
        backgroundColor: accentBlue,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  String? _getContactValueForActive() {
    final priorContact = _currentStudent.priorContact;
    if (priorContact == null || priorContact.isEmpty) return null;
    
    final value = priorContact.toLowerCase();
    
    if (value == 'звонок' || value == 'call' || value == 'phone' ||
        value == 'просто сообщения' || value == 'messages' || value == 'sms') {
      return _currentStudent.phone;
    } else if (value == 'телеграмм' || value == 'telegram') {
      return _currentStudent.additionalContacts?['telegram'] ?? _currentStudent.phone;
    } else if (value == 'ссылка' || value == 'url') {
      return _currentStudent.additionalContacts?['url'];
    }
    return null;
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.blue.shade100,
          child: Text(
            _currentStudent.fullName.isNotEmpty ? _currentStudent.fullName[0].toUpperCase() : '?',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: accentBlue),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentStudent.fullName,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _currentStudent.status == 'active' ? successGreen.withOpacity(0.1) : neutralGray.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _currentStudent.statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color: _currentStudent.status == 'active' ? successGreen : neutralGray,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ID: ${_currentStudent.russianStudentId ?? _currentStudent.id}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentStatuses() {
    return Card(
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
            const Text(
              'Статусы абитуриента',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentBlue),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildStatusChip(
                  'Статус документов',
                  _getDocumentsStatusText(_currentStudent.documentsStatus),
                  _getDocumentsStatusColor(_currentStudent.documentsStatus),
                ),
                _buildStatusChip(
                  'Был на сборе',
                  _getMeetingStatusText(_currentStudent.meetingStatus),
                  _getMeetingStatusColor(_currentStudent.meetingStatus),
                ),
                _buildStatusChip(
                  'Дозвонились',
                  _getCallStatusText(_currentStudent.callStatus),
                  _getCallStatusColor(_currentStudent.callStatus),
                ),
                _buildStatusChip(
                  'Решение',
                  _getDecisionStatusText(_currentStudent.decisionStatus),
                  _getDecisionStatusColor(_currentStudent.decisionStatus),
                ),
                _buildStatusChip(
                  'Общий статус',
                  _currentStudent.statusText,
                  _currentStudent.status == 'active' ? successGreen : neutralGray,
                ),
                _buildStatusChip(
                  'Статус контакта',
                  _getContactStatusText(_currentStudent.contactStatus),
                  Colors.blue,
                ),
                _buildStatusChip(
                  'Согласие',
                  _getYesNo(_currentStudent.consentStatus),
                  _currentStudent.consentStatus == true ? successGreen : errorRed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo() {
    final hasUrl = _currentStudent.additionalContacts?.containsKey('url') == true &&
                   _currentStudent.additionalContacts!['url']!.isNotEmpty;
    final hasTelegramInAdditional = _currentStudent.additionalContacts?.containsKey('telegram') == true &&
                                     _currentStudent.additionalContacts!['telegram']!.isNotEmpty;
    final priorContact = _currentStudent.priorContact;
    
    String priorContactDisplay = _getPriorContactDisplayName(priorContact);
    
    return Card(
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
            const Text(
              'Контактная информация',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentBlue),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Телефон', _currentStudent.displayPhone, Icons.phone, onTap: _currentStudent.phone.isNotEmpty ? _handleCall : null),
            const Divider(),
            _buildInfoRow('Приоритетный контакт', priorContactDisplay, Icons.star),
            if (_currentStudent.additionalContacts != null && _currentStudent.additionalContacts!.isNotEmpty) ...[
              const Divider(),
              _buildAdditionalContacts(),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (priorContact != null && (priorContact.toLowerCase() == 'phone' || priorContact.toLowerCase() == 'звонок') || _currentStudent.phone.isNotEmpty)
                  _buildActionButton('Позвонить', Icons.call, successGreen, _handleCall),
                if (priorContact != null && (priorContact.toLowerCase() == 'messages' || priorContact.toLowerCase() == 'просто сообщения') || _currentStudent.phone.isNotEmpty)
                  _buildActionButton('Написать', Icons.message, accentBlue, () => ContactService.messageStudent(_currentStudent.phone)),
                if (priorContact != null && (priorContact.toLowerCase() == 'telegram' || priorContact.toLowerCase() == 'телеграмм') || hasTelegramInAdditional)
                  _buildActionButton('Telegram', Icons.telegram, const Color(0xFF26A5E4), _handleTelegram),
                if (priorContact != null && (priorContact.toLowerCase() == 'url' || priorContact.toLowerCase() == 'ссылка') || hasUrl)
                  _buildActionButton('Ссылка', Icons.link, Colors.purple, _handleUrl),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: accentBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildAdditionalContacts() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Дополнительные контакты', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _currentStudent.additionalContacts!.entries.map((entry) {
              IconData icon;
              Color color;
              VoidCallback? onTap;
              switch (entry.key) {
                case 'telegram':
                  icon = Icons.telegram;
                  color = const Color(0xFF26A5E4);
                  onTap = _handleTelegram;
                  break;
                case 'url':
                  icon = Icons.link;
                  color = Colors.purple;
                  onTap = _handleUrl;
                  break;
                default:
                  icon = Icons.contact_phone;
                  color = Colors.orange;
                  onTap = null;
              }
              return GestureDetector(
                onTap: onTap,
                child: Chip(
                  avatar: Icon(icon, size: 16, color: color),
                  label: Text('${entry.key}: ${entry.value}'),
                  backgroundColor: Colors.grey.shade200,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildApplicationsSection() {
    if (_loadingApplications) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_applications.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Заявки на специальности',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentBlue),
        ),
        const SizedBox(height: 12),
        ..._applications.map((app) => _buildApplicationCard(app)),
      ],
    );
  }

  Widget _buildApplicationCard(StudentApplication app) {
    final isExpanded = _selectedApplicationId == app.id;
    final statKey = app.profileId ?? app.specialityId;
    final groupStat = _groupStatisticsMap[statKey];
    final competitiveInfo = _competitiveInfoMap[app.specialityId];
    final studyBasis = app.studyBasis?.toLowerCase() ?? '';
    final isBudget = studyBasis == 'бюджетная';
    final isPaid = studyBasis == 'платная';
    final isTarget = studyBasis == 'целевая';
    
    int placesTotal = 0;
    int placesFilled = 0;
    int applicantsWithConsent = 0;
    
    if (isBudget && groupStat != null) {
      placesTotal = groupStat.budget.total;
      placesFilled = groupStat.budget.filled;
      applicantsWithConsent = groupStat.budget.applicantsWithConsent;
    } else if (isPaid && groupStat != null) {
      placesTotal = groupStat.paid.total;
      placesFilled = groupStat.paid.filled;
      applicantsWithConsent = groupStat.paid.applicantsWithConsent;
    } else if (isTarget && groupStat != null) {
      placesTotal = groupStat.target.total;
      placesFilled = groupStat.target.filled;
      applicantsWithConsent = groupStat.target.applicantsWithConsent;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: borderColor, width: 1),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(12),
            title: Text(
              app.specialityName ?? 'Без названия',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: accentBlue),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (app.profileName != null && app.profileName!.isNotEmpty)
                  Text('Профиль: ${app.profileName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildChip('Место: ${app.position ?? '—'}', Colors.blue),
                    _buildChip('Баллы: ${app.totalScore ?? '—'}', successGreen),
                    _buildChip(_getApplicationStatusText(app.applicationStatus), _getApplicationStatusColor(app.applicationStatus)),
                    if (app.studyForm != null && app.studyForm!.isNotEmpty)
                      _buildChip(app.studyForm!, warningOrange),
                    if (app.studyBasis != null && app.studyBasis!.isNotEmpty)
                      _buildChip(
                        app.studyBasis!,
                        isBudget ? successGreen : isPaid ? warningOrange : Colors.purple,
                      ),
                  ],
                ),
              ],
            ),
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: accentBlue,
            ),
            onTap: () => _onApplicationTap(app),
          ),
          if (isExpanded && _loadingCompetitive)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (isExpanded && !_loadingCompetitive && groupStat != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildStatRow(
                    'Место в конкурсе',
                    '${competitiveInfo?['position'] ?? '—'} из ${groupStat.totalApplications}',
                  ),
                  if (placesTotal > 0) ...[
                    const SizedBox(height: 8),
                    _buildStatRow(
                      isBudget ? 'Бюджетных мест' : isPaid ? 'Платных мест' : 'Целевых мест',
                      '$placesFilled / $placesTotal',
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow('Конкурс', '${groupStat.competition.toStringAsFixed(2)} чел/место'),
                  ],
                  const SizedBox(height: 8),
                  _buildStatRow('Средний балл', groupStat.averageScore.toStringAsFixed(2)),
                  const SizedBox(height: 8),
                  _buildStatRow('Максимальный балл', groupStat.maxScore.toString()),
                  if (applicantsWithConsent > 0) ...[
                    const SizedBox(height: 8),
                    _buildStatRow('Подали согласие', applicantsWithConsent.toString()),
                  ],
                  const SizedBox(height: 8),
                  _buildStatRow('Ваши баллы', '${competitiveInfo?['student_score'] ?? app.totalScore ?? '—'}'),
                  const SizedBox(height: 8),
                  _buildStatRow('Статус заявления', _getApplicationStatusText(app.applicationStatus)),
                  const SizedBox(height: 8),
                  _buildStatRow('Согласие', _getYesNo(app.consentStatus)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildCommunicationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'История коммуникаций',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentBlue),
        ),
        const SizedBox(height: 12),
        if (_loadingCommunications)
          const Center(child: CircularProgressIndicator())
        else if (_communications.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text('Нет записей о коммуникациях', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              ..._communications.map((comm) => _buildCommunicationCard(comm)),
              const SizedBox(height: 80),
            ],
          ),
      ],
    );
  }

  Widget _buildCommunicationCard(Communication comm) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: _getCommTypeColor(comm.communicationType).withOpacity(0.2),
              child: Icon(
                _getCommTypeIcon(comm.communicationType),
                color: _getCommTypeColor(comm.communicationType),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comm.typeDisplayName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(comm.status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          comm.statusDisplayName,
                          style: TextStyle(fontSize: 10, color: _getStatusColor(comm.status)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    comm.notes,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTime(comm.dateTime),
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                      if (comm.durationMinutes != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.timer, size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '${comm.durationMinutes} мин',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ],
                  ),
                  if (comm.createdByName != null)
                    Text(
                      'Создал: ${comm.createdByName}',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCommTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'call': return Icons.call;
      case 'meeting': return Icons.group;
      case 'email': return Icons.email;
      default: return Icons.message;
    }
  }

  Color _getCommTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'call': return successGreen;
      case 'meeting': return warningOrange;
      case 'email': return errorRed;
      default: return accentBlue;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed': return successGreen;
      case 'planned': return accentBlue;
      case 'cancelled': return errorRed;
      default: return neutralGray;
    }
  }

  void _navigateToAddCommunication() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCommunicationPage(
          studentId: _currentStudent.id,
          studentName: _currentStudent.fullName,
          onAdd: _addCommunication,
        ),
      ),
    );
  }

  void _navigateToEditStudent() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditStudentPage(
          student: _currentStudent,
          onUpdate: _updateStudent,
        ),
      ),
    );
  }
}