// pages/add_student_page.dart
import 'package:flutter/material.dart';
import '../../models/student.dart';

// Цвета из Figma
const Color accentBlue = Color(0xFF0088FF);
const Color borderColor = Color(0xFFC5C6D0);
const Color successGreen = Color(0xFF34C759);
const Color errorRed = Color(0xFFFF383C);
const Color warningOrange = Color(0xFFFF9800);
const Color neutralGray = Color(0xFFA0A0A0);

class AddStudentPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;

  const AddStudentPage({required this.onAdd, Key? key}) : super(key: key);

  @override
  _AddStudentPageState createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _russianIdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECF5FD),
      appBar: AppBar(
        title: const Text(
          'Добавить студента',
          style: TextStyle(color: accentBlue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFECF5FD),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: accentBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Российский ID
              TextFormField(
                controller: _russianIdController,
                decoration: const InputDecoration(
                  labelText: 'Российский ID абитуриента *',
                  border: OutlineInputBorder(),
                  hintText: '1234567890',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите российский ID абитуриента';
                  }
                  if (int.tryParse(value) == null) {
                    return 'ID должен быть числом';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),

              // ФИО
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'ФИО студента *',
                  border: OutlineInputBorder(),
                  hintText: 'Иванов Иван Иванович',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите ФИО студента';
                  }
                  if (value.length < 2) {
                    return 'ФИО слишком короткое';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),

              // Телефон
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Номер телефона *',
                  border: OutlineInputBorder(),
                  hintText: '+79991234567',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите номер телефона';
                  }
                  if (!RegExp(r'[\d\+]').hasMatch(value)) {
                    return 'Введите корректный номер телефона';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),

              // Кнопка добавления
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    String phone = _phoneController.text.trim();
                    
                    final studentData = {
                      'full_name': _nameController.text.trim(),
                      'russian_student_id': int.parse(_russianIdController.text.trim()),
                      'phone': phone,
                    };
                    
                    try {
                      await widget.onAdd(studentData);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ошибка: $e'),
                          backgroundColor: errorRed,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Добавить студента',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: neutralGray,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: borderColor),
                ),
                child: const Text('Отмена', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _russianIdController.dispose();
    super.dispose();
  }
}