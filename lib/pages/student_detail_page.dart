// pages/student_detail_page.dart
import 'package:flutter/material.dart';
import '../models/student.dart';
import '../models/communication.dart';
import '../services/student_service.dart';
import '../utils/contact_service.dart';
import 'add_communication_page.dart';
import 'edit_student_page.dart';

class StudentDetailPage extends StatefulWidget {
  final Student student;

  const StudentDetailPage({required this.student, Key? key}) : super(key: key);

  @override
  _StudentDetailPageState createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  final StudentService _studentService = StudentService();
  List<Communication> _communications = [];
  bool _loadingCommunications = false;
  late Student _currentStudent;

  @override
  void initState() {
    super.initState();
    _currentStudent = widget.student;
    _loadCommunications();
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
      setState(() => _loadingCommunications = false);
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
          const SnackBar(content: Text('Коммуникация добавлена'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateStudent(Student updatedStudent) async {
    setState(() {
      _currentStudent = updatedStudent;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Данные обновлены'), backgroundColor: Colors.green),
      );
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Не указано';
    return '${date.day}.${date.month}.${date.year}';
  }

  String _formatDateTime(DateTime? date) {
    if (date == null) return 'Не указано';
    return '${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getYesNo(bool? value) {
    if (value == null) return 'Не указано';
    return value ? 'Да' : 'Нет';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentStudent.fullName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _navigateToEditStudent(),
            tooltip: 'Редактировать',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Аватар и основная информация
            _buildHeader(_currentStudent),
            
            const SizedBox(height: 24),

            // Контактная информация
            _buildContactInfo(_currentStudent),
            
            const SizedBox(height: 24),

            // Академическая информация
            _buildAcademicInfo(_currentStudent),
            
            const SizedBox(height: 24),

            // Статусы
            _buildStatusInfo(_currentStudent),
            
            const SizedBox(height: 24),

            // Дополнительная информация
            _buildAdditionalInfo(_currentStudent),
            
            const SizedBox(height: 24),

            // Кнопки действий
            _buildActionButtons(),

            const SizedBox(height: 24),

            // История коммуникаций
            _buildCommunicationsSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddCommunication(),
        child: const Icon(Icons.add_comment),
        tooltip: 'Добавить коммуникацию',
      ),
    );
  }

  Widget _buildHeader(Student student) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              student.fullName.isNotEmpty ? student.fullName[0].toUpperCase() : '?',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            student.fullName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: student.status == 'active' ? Colors.green.shade100 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              student.statusText,
              style: TextStyle(
                color: student.status == 'active' ? Colors.green : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ID: ${student.russianStudentId}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(Student student) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Контактная информация',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Телефон', student.displayPhone, Icons.phone, canEdit: true),
            const Divider(),
            _buildInfoRow('Приоритетный контакт', student.priorContact ?? 'Не указан', Icons.star, canEdit: true),
            
            if (student.additionalContacts != null && student.additionalContacts!.isNotEmpty) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.link, color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Дополнительные контакты', 
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: student.additionalContacts!.entries.map((entry) {
                              return Chip(
                                label: Text('${entry.key}: ${entry.value}'),
                                backgroundColor: Colors.grey.shade200,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicInfo(Student student) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Академическая информация',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 16),
            
            if (student.departmentName != null) ...[
              _buildInfoRow('Направление', student.departmentName!, Icons.school, canEdit: true),
              const Divider(),
            ],
            
            if (student.specialityName != null) ...[
              _buildInfoRow('Специальность', student.specialityName!, Icons.work, canEdit: true),
              const Divider(),
            ],
            
            if (student.profileName != null) ...[
              _buildInfoRow('Профиль', student.profileName!, Icons.person_outline, canEdit: true),
              const Divider(),
            ],
            
            if (student.studyLevel != null) ...[
              _buildInfoRow('Уровень обучения', student.studyLevel!, Icons.school, canEdit: true),
              const Divider(),
            ],
            
            if (student.studyForm != null) ...[
              _buildInfoRow('Форма обучения', student.studyForm!, Icons.date_range, canEdit: true),
              const Divider(),
            ],
            
            if (student.studyBasis != null) ...[
              _buildInfoRow('Основа обучения', student.studyBasis!, Icons.attach_money, canEdit: true),
              const Divider(),
            ],
            
            if (student.totalScore != null) ...[
              _buildInfoRow('Общий балл', student.totalScore!.toString(), Icons.score, canEdit: false),
            ],
            
            if (student.kuratorId != null) ...[
              const Divider(),
              _buildInfoRow('ID куратора', student.kuratorId!.toString(), Icons.person, canEdit: false),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {bool canEdit = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (canEdit)
            IconButton(
              icon: Icon(Icons.edit, size: 18, color: Colors.grey.shade400),
              onPressed: () => _navigateToEditStudent(),
              tooltip: 'Редактировать',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusInfo(Student student) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Статусы',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 16),
            
            _buildStatusRow('Общий статус', student.statusText, 
              _getStatusColor(student.status), canEdit: true),
            const Divider(),
            
            _buildStatusRow('Статус заявления', student.applicationStatus ?? 'Не указан', 
              _getStatusColor(student.applicationStatus), canEdit: true),
            const Divider(),
            
            _buildStatusRow('Статус контакта', student.contactStatus ?? 'Не указан',
              _getStatusColor(student.contactStatus), canEdit: true),
            const Divider(),
            
            _buildStatusRow('Тип контакта', student.contactType ?? 'Не указан',
              Colors.blue, canEdit: true),
            const Divider(),
            
            _buildStatusRow('Согласие', _getYesNo(student.consentStatus),
              student.consentStatus == true ? Colors.green : Colors.orange, canEdit: true),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color, {bool canEdit = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontSize: 14)),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (canEdit)
            IconButton(
              icon: Icon(Icons.edit, size: 16, color: Colors.grey.shade400),
              onPressed: () => _navigateToEditStudent(),
              tooltip: 'Редактировать',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo(Student student) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Дополнительная информация',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 16),
            
            if (student.lastCommunication != null) ...[
              _buildInfoRow('Последняя связь', _formatDateTime(student.lastCommunication), Icons.access_time),
              if (student.lastCommunicationNote != null && student.lastCommunicationNote!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 32.0),
                  child: Text(
                    'Заметка: ${student.lastCommunicationNote}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
              const Divider(),
            ],
            
            if (student.createdAt != null) ...[
              _buildInfoRow('Создан', _formatDateTime(student.createdAt), Icons.add_circle_outline),
              const Divider(),
            ],
            
            if (student.updatedAt != null) ...[
              _buildInfoRow('Обновлен', _formatDateTime(student.updatedAt), Icons.update),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    
    switch (status.toLowerCase()) {
      case 'active':
      case 'completed':
      case 'accepted':
        return Colors.green;
      case 'pending':
      case 'waiting':
        return Colors.orange;
      case 'inactive':
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      case 'planned':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: () => ContactService.callStudent(_currentStudent.phone),
          icon: const Icon(Icons.call, size: 20),
          label: const Text('Позвонить'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => ContactService.messageStudent(_currentStudent.phone),
          icon: const Icon(Icons.message, size: 20),
          label: const Text('Написать'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
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
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        const SizedBox(height: 12),
        
        if (_loadingCommunications)
          const Center(child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ))
        else if (_communications.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text('Нет записей о коммуникациях', 
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text('Нажмите + чтобы добавить', 
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _communications.length,
            itemBuilder: (context, index) {
              final comm = _communications[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: comm.communicationType == 'call' ? Colors.green.shade100 :
                                   comm.communicationType == 'meeting' ? Colors.orange.shade100 :
                                   comm.communicationType == 'email' ? Colors.red.shade100 : Colors.blue.shade100,
                    child: Icon(
                      comm.communicationType == 'call' ? Icons.call :
                      comm.communicationType == 'meeting' ? Icons.group :
                      comm.communicationType == 'email' ? Icons.email : Icons.message,
                      color: comm.communicationType == 'call' ? Colors.green :
                             comm.communicationType == 'meeting' ? Colors.orange :
                             comm.communicationType == 'email' ? Colors.red : Colors.blue,
                      size: 24,
                    ),
                  ),
                  title: Row(
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
                          style: TextStyle(
                            fontSize: 10,
                            color: _getStatusColor(comm.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        comm.notes,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            comm.formattedDate,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                          if (comm.durationMinutes != null) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.timer, size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              comm.durationDisplay,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () => _showCommunicationDetails(comm),
                ),
              );
            },
          ),
      ],
    );
  }

  void _showCommunicationDetails(Communication comm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              comm.communicationType == 'call' ? Icons.call :
              comm.communicationType == 'meeting' ? Icons.group :
              comm.communicationType == 'email' ? Icons.email : Icons.message,
              color: Colors.blue,
            ),
            const SizedBox(width: 8),
            Text(comm.typeDisplayName),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Статус', comm.statusDisplayName),
              const SizedBox(height: 8),
              _buildDetailRow('Дата', comm.formattedDate),
              if (comm.durationMinutes != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Длительность', comm.durationDisplay),
              ],
              const SizedBox(height: 16),
              const Text('Заметки:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(comm.notes),
              ),
              if (comm.createdByName != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Создал: ${comm.createdByName}',
                  style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(child: Text(value)),
      ],
    );
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