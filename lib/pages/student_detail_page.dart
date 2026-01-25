import 'package:flutter/material.dart';
import '../models/student.dart';
import '../utils/contact_service.dart';

class StudentDetailPage extends StatelessWidget {
  final Student student;

  const StudentDetailPage({required this.student, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(student.fullName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Редактирование будет добавлено позже'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      student.fullName.isNotEmpty
                          ? student.fullName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    student.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (student.russianStudentId.isNotEmpty)
                    Text(
                      'ID: ${student.russianStudentId}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              'Основная информация',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoCard([
              _buildInfoRow('Телефон', student.phone, Icons.phone),
              if (student.email != null)
                _buildInfoRow('Email', student.email!, Icons.email),
              if (student.dateOfBirth != null)
                _buildInfoRow(
                  'Дата рождения',
                  _formatDateString(student.dateOfBirth!),
                  Icons.cake,
                ),
              if (student.status != null)
                _buildInfoRow('Статус', student.statusText, Icons.flag),
            ]),
            const SizedBox(height: 24),

            if (student.departmentName != null ||
                student.specialityName != null ||
                student.priorityPlace != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Академическая информация',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    if (student.departmentName != null)
                      _buildInfoRow('Направление', student.departmentName!, Icons.school),
                    if (student.specialityName != null)
                      _buildInfoRow('Специальность', student.specialityName!, Icons.work),
                    if (student.priorityPlace != null)
                      _buildInfoRow(
                        'Место по приоритетам',
                        student.priorityPlace!.toString(),
                        Icons.format_list_numbered,
                      ),
                    if (student.assignedTeacherName != null)
                      _buildInfoRow(
                        'Закрепленный преподаватель',
                        student.assignedTeacherName!,
                        Icons.person,
                      ),
                    if (student.level != null)
                      _buildInfoRow('Уровень', student.level!, Icons.school),
                  ]),
                  const SizedBox(height: 24),
                ],
              ),

            if (student.additionalContacts != null && student.additionalContacts!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Дополнительные контакты',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: student.additionalContacts!.map((contact) {
                      return Chip(
                        label: Text(contact.toString()),
                        backgroundColor: Colors.grey.shade200,
                        avatar: const Icon(Icons.link, size: 16),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],
              ),

            if (student.lastCommunicationDate != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Последняя связь',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard([
                    _buildInfoRow(
                      'Дата последней связи',
                      '${student.lastCommunicationDate!.day}.${student.lastCommunicationDate!.month}.${student.lastCommunicationDate!.year}',
                      Icons.access_time,
                    ),
                  ]),
                  const SizedBox(height: 24),
                ],
              ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => ContactService.callStudent(student.phone),
                  icon: const Icon(Icons.call, size: 20),
                  label: const Text('Позвонить'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => ContactService.messageStudent(student.phone),
                  icon: const Icon(Icons.message, size: 20),
                  label: const Text('Написать'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => ContactService.addContactToPhone(student),
                  icon: const Icon(Icons.contact_page, size: 20),
                  label: const Text('В контакты'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            if (student.notes != null && student.notes!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  const Text(
                    'Заметки',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        student.notes!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),

            if (student.createdAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Text(
                  'Добавлен: ${_formatDateString(student.createdAt!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateString(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}.${date.month}.${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}