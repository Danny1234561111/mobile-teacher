// pages/add_student_page.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import '../services/student_service.dart';
import 'duplicates_page.dart';

const Color accentBlue = Color(0xFF0088FF);
const Color borderColor = Color(0xFFC5C6D0);
const Color successGreen = Color(0xFF34C759);
const Color errorRed = Color(0xFFFF383C);
const Color warningOrange = Color(0xFFFF9800);
const Color neutralGray = Color(0xFFA0A0A0);
const Color lightBg = Color(0xFFECF5FD);

class AddStudentPage extends StatefulWidget {
  final VoidCallback onSuccess;

  const AddStudentPage({required this.onSuccess, Key? key}) : super(key: key);

  @override
  _AddStudentPageState createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _russianIdController = TextEditingController();
  
  final StudentService _studentService = StudentService();
  bool _isLoading = false;
  int _currentTab = 0;
  
  XFile? _excelFile;
  bool _isImportingExcel = false;
  Map<String, dynamic>? _excelImportResult;
  
  XFile? _pendingExcelFile;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _russianIdController.dispose();
    super.dispose();
  }

  Future<void> _addStudentManually() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final studentData = {
        'full_name': _normalizeFullName(_nameController.text.trim()),
        'phone': _phoneController.text.trim(),
        'russian_student_id': int.parse(_russianIdController.text.trim()),
      };
      
      await _studentService.createStudent(studentData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Студент добавлен'), backgroundColor: successGreen),
        );
        widget.onSuccess();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _normalizeFullName(String name) {
    if (name.isEmpty) return '';
    String cleaned = name.replaceAll(RegExp(r'[*]'), '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    final words = cleaned.split(' ');
    final normalizedWords = words.map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    });
    return normalizedWords.join(' ');
  }

  Future<void> _pickExcelFile() async {
    try {
      const XTypeGroup excelType = XTypeGroup(
        label: 'Excel files',
        extensions: ['xlsx', 'xls'],
        mimeTypes: ['application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', 'application/vnd.ms-excel'],
      );
      
      final XFile? result = await openFile(acceptedTypeGroups: [excelType]);
      
      if (result != null) {
        setState(() {
          _excelFile = result;
          _excelImportResult = null;
          _pendingExcelFile = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выбора файла: $e'), backgroundColor: errorRed),
        );
      }
    }
  }

  Future<File> _copyXFileToTempFile(XFile xfile) async {
    final tempDir = await getTemporaryDirectory();
    final fileName = xfile.name;
    final tempFile = File('${tempDir.path}/$fileName');
    await xfile.saveTo(tempFile.path);
    return tempFile;
  }

  List<Map<String, dynamic>> _parseDuplicates(dynamic duplicatesRaw) {
    final List<Map<String, dynamic>> result = [];
    
    if (duplicatesRaw is List) {
      for (var item in duplicatesRaw) {
        if (item is Map) {
          result.add({
            'id': item['id'] ?? 0,
            'full_name': item['full_name'] ?? 'Неизвестно',
            'phone': item['phone'] ?? '',
          });
        } else if (item is int) {
          result.add({
            'id': item,
            'full_name': 'ID: $item',
            'phone': '',
          });
        }
      }
    }
    
    return result;
  }

  Future<void> _importExcel() async {
    if (_excelFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите файл Excel'), backgroundColor: warningOrange),
      );
      return;
    }

    setState(() {
      _isImportingExcel = true;
      _excelImportResult = null;
    });

    try {
      final tempFile = await _copyXFileToTempFile(_excelFile!);
      final data = await _studentService.importExcel(tempFile, 'skip');
      
      print('📊 Ответ от сервера: $data');
      
      if (data['success'] == true) {
        setState(() {
          _excelImportResult = data;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Импорт завершен'), backgroundColor: successGreen),
        );
        widget.onSuccess();
        _closeAllImportDialogs();
      } else {
        setState(() {
          _excelImportResult = data;
        });
        
        if (data.containsKey('duplicates_found') && data['duplicates_found'] != null) {
          final duplicates = _parseDuplicates(data['duplicates_found']);
          if (duplicates.isNotEmpty) {
            print('📋 Найдено дубликатов: ${duplicates.length}');
            setState(() {
              _pendingExcelFile = _excelFile;
            });
            _navigateToDuplicatesPage(duplicates);
            return;
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Ошибка импорта'), backgroundColor: errorRed),
        );
      }
    } catch (e) {
      print('❌ Ошибка импорта: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка импорта: $e'), backgroundColor: errorRed),
      );
    } finally {
      if (mounted) setState(() => _isImportingExcel = false);
    }
  }

  void _navigateToDuplicatesPage(List<Map<String, dynamic>> duplicates) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DuplicatesPage(
          duplicates: duplicates,
          pendingExcelFile: _pendingExcelFile,
          onImportComplete: (success, message) {
            if (success) {
              widget.onSuccess();
              _closeAllImportDialogs();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message), backgroundColor: successGreen),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message), backgroundColor: errorRed),
              );
            }
          },
        ),
      ),
    );
  }

  void _closeAllImportDialogs() {
    setState(() {
      _currentTab = 0;
      _excelFile = null;
      _excelImportResult = null;
      _pendingExcelFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: const Text(
          'Добавить студента',
          style: TextStyle(color: accentBlue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: lightBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: accentBlue),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildTab('Вручную', 0),
                _buildTab('Excel импорт', 1),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading || _isImportingExcel
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _currentTab == 0 ? _buildManualForm() : _buildExcelForm(),
            ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _currentTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? accentBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : neutralGray,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManualForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _russianIdController,
            decoration: const InputDecoration(
              labelText: 'Российский ID абитуриента *',
              border: OutlineInputBorder(),
              hintText: '1234567890',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Введите российский ID';
              if (int.tryParse(value) == null) return 'ID должен быть числом';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'ФИО студента *',
              border: OutlineInputBorder(),
              hintText: 'Иванов Иван Иванович',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Введите ФИО студента';
              if (value.length < 2) return 'ФИО слишком короткое';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Номер телефона *',
              border: OutlineInputBorder(),
              hintText: '+79991234567',
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Введите номер телефона';
              return null;
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _addStudentManually,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Добавить студента', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: neutralGray,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: borderColor),
            ),
            child: const Text('Отмена', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildExcelForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accentBlue.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Требования к Excel файлу:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text('• Обязательные колонки: ФИО, Телефон, ID поступающего',
                  style: TextStyle(fontSize: 12)),
              const Text('• Рекомендуемые: Профиль, Баллы, Приоритет, Форма обучения, Основа обучения',
                  style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _pickExcelFile,
          icon: const Icon(Icons.upload_file, color: accentBlue),
          label: const Text('Выбрать файл Excel'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: const BorderSide(color: borderColor),
          ),
        ),
        if (_excelFile != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: successGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: successGreen.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: successGreen, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Выбран файл: ${_excelFile!.name}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_excelImportResult != null && _excelImportResult!['success'] == false && 
            (_excelImportResult!['errors'] != null) && 
            (_excelImportResult!['duplicates_found'] == null || (_excelImportResult!['duplicates_found'] as List).isEmpty)) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: errorRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: errorRed.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_excelImportResult!['message'] ?? 'Ошибка импорта',
                    style: const TextStyle(color: errorRed)),
                if (_excelImportResult!['errors'] != null && (_excelImportResult!['errors'] as List).isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Ошибки:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...(_excelImportResult!['errors'] as List).take(5).map((err) => 
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('• Строка ${err['row']}: ${err['error']}',
                          style: const TextStyle(fontSize: 12, color: errorRed)),
                    ),
                  ),
                  if ((_excelImportResult!['errors'] as List).length > 5)
                    const Text('...и еще несколько ошибок', style: TextStyle(fontSize: 12)),
                ],
              ],
            ),
          ),
        ],
        if (_excelImportResult != null && _excelImportResult!['success'] == true) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: successGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: successGreen.withOpacity(0.3)),
            ),
            child: Text(_excelImportResult!['message'] ?? 'Импорт завершен',
                style: const TextStyle(color: successGreen)),
          ),
        ],
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _excelFile != null ? _importExcel : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: accentBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Импортировать', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: neutralGray,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: const BorderSide(color: borderColor),
          ),
          child: const Text('Отмена', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}