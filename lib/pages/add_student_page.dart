// pages/add_student_page.dart
import 'package:flutter/material.dart';
import '../../models/student.dart';

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
      appBar: AppBar(
        title: const Text('Добавить студента'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Российский ID
              TextFormField(
                controller: _russianIdController,
                decoration: InputDecoration(
                  labelText: 'Российский ID абитуриента*',
                  prefixIcon: const Icon(Icons.badge),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  hintText: '1234567890',
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
              const SizedBox(height: 15),

              // ФИО
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'ФИО студента*',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
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
              const SizedBox(height: 15),

              // Телефон
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Номер телефона*',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  hintText: '+79991234567',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите номер телефона';
                  }
                  // Упрощенная валидация - просто проверяем что есть цифры
                  if (!RegExp(r'[\d\+]').hasMatch(value)) {
                    return 'Введите корректный номер телефона';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 30),

              // Кнопка добавления
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // Форматируем номер телефона
                    String phone = _phoneController.text.trim();
                    
                    // Подготавливаем данные для отправки - ТОЛЬКО 3 ПОЛЯ!
                    final studentData = {
                      'full_name': _nameController.text.trim(),
                      'russian_student_id': int.parse(_russianIdController.text.trim()),
                      'phone': phone,
                    };
                    
                    print('📦 Отправка данных: $studentData');
                    
                    try {
                      await widget.onAdd(studentData);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Ошибка: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Text(
                    'Добавить студента',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Text('Отмена'),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
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