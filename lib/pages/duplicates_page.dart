// pages/duplicates_page.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import '../services/student_service.dart';

const Color accentBlue = Color(0xFF0088FF);
const Color borderColor = Color(0xFFC5C6D0);
const Color successGreen = Color(0xFF34C759);
const Color errorRed = Color(0xFFFF383C);
const Color warningOrange = Color(0xFFFF9800);
const Color neutralGray = Color(0xFFA0A0A0);
const Color lightBg = Color(0xFFECF5FD);

class DuplicatesPage extends StatefulWidget {
  final List<Map<String, dynamic>> duplicates;
  final XFile? pendingExcelFile;
  final Function(bool, String) onImportComplete;

  const DuplicatesPage({
    required this.duplicates,
    required this.pendingExcelFile,
    required this.onImportComplete,
    Key? key,
  }) : super(key: key);

  @override
  _DuplicatesPageState createState() => _DuplicatesPageState();
}

class _DuplicatesPageState extends State<DuplicatesPage> {
  final StudentService _studentService = StudentService();
  String _duplicateStrategy = 'skip';
  Set<int> _replaceIds = {};
  bool _isProcessing = false;

  Future<void> _processImport() async {
    if (widget.pendingExcelFile == null) {
      print('❌ Нет файла для импорта');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${widget.pendingExcelFile!.name}');
      await widget.pendingExcelFile!.saveTo(tempFile.path);
      
      List<int> replaceIdsArray = [];
      if (_duplicateStrategy == 'replace_selected') {
        replaceIdsArray = _replaceIds.toList();
        print('🆔 Выбранные ID для замены: $replaceIdsArray');
      }
      
      print('📤 Повторный импорт со стратегией: $_duplicateStrategy');
      
      final data = await _studentService.importExcel(
        tempFile,
        _duplicateStrategy,
        _duplicateStrategy == 'replace_selected' ? replaceIdsArray : null,
      );

      print('📊 Результат повторного импорта: $data');

      if (data['success'] == true) {
        widget.onImportComplete(true, data['message'] ?? 'Импорт завершен');
        if (mounted) Navigator.pop(context);
      } else {
        widget.onImportComplete(false, data['message'] ?? 'Ошибка импорта');
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      print('❌ Ошибка повторного импорта: $e');
      widget.onImportComplete(false, 'Ошибка импорта: $e');
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      appBar: AppBar(
        title: const Text(
          'Обработка дубликатов',
          style: TextStyle(color: accentBlue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: lightBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: accentBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: errorRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: errorRed.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: errorRed.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.warning_amber_rounded, color: errorRed, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Обнаружены дубликаты',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: errorRed),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Найдено ${widget.duplicates.length} абитуриентов, которые уже есть в системе',
                                style: const TextStyle(fontSize: 13, color: neutralGray),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Выберите способ обработки:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),

                  _buildOptionCard(
                    title: 'Пропустить все дубликаты',
                    subtitle: 'Существующие студенты не будут изменены',
                    value: 'skip',
                    groupValue: _duplicateStrategy,
                    onChanged: (value) {
                      setState(() {
                        _duplicateStrategy = value!;
                        if (value != 'replace_selected') _replaceIds.clear();
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  _buildOptionCard(
                    title: 'Заменить данные всех дубликатов',
                    subtitle: 'Обновить информацию существующих студентов',
                    value: 'replace_all',
                    groupValue: _duplicateStrategy,
                    onChanged: (value) {
                      setState(() {
                        _duplicateStrategy = value!;
                        if (value != 'replace_selected') _replaceIds.clear();
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  _buildOptionCard(
                    title: 'Выбрать дубликаты для замены вручную',
                    subtitle: 'Отметьте студентов, которых нужно обновить',
                    value: 'replace_selected',
                    groupValue: _duplicateStrategy,
                    onChanged: (value) {
                      setState(() {
                        _duplicateStrategy = value!;
                      });
                    },
                  ),

                  if (_duplicateStrategy == 'replace_selected') ...[
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: accentBlue.withOpacity(0.05),
                              border: Border(bottom: BorderSide(color: borderColor)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.person_search, size: 18, color: accentBlue),
                                const SizedBox(width: 8),
                                const Text(
                                  'Выберите студентов для замены:',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                                const Spacer(),
                                Text(
                                  '${_replaceIds.length} выбрано',
                                  style: TextStyle(fontSize: 12, color: accentBlue),
                                ),
                              ],
                            ),
                          ),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 350),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: widget.duplicates.length,
                              separatorBuilder: (context, index) => Divider(height: 0, color: borderColor),
                              itemBuilder: (context, index) {
                                final dup = widget.duplicates[index];
                                final isSelected = _replaceIds.contains(dup['id']);
                                return CheckboxListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                  title: Text(
                                    dup['full_name'] ?? 'Без имени',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Text(
                                    'ID: ${dup['id']} | ${dup['phone'] ?? 'Нет телефона'}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  value: isSelected,
                                  activeColor: accentBlue,
                                  onChanged: (selected) {
                                    setState(() {
                                      if (selected == true) {
                                        _replaceIds.add(dup['id']);
                                      } else {
                                        _replaceIds.remove(dup['id']);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                          if (_replaceIds.isEmpty && widget.duplicates.isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, size: 14, color: warningOrange),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Вы не выбрали ни одного студента. Будет использована стратегия "пропустить".',
                                      style: TextStyle(fontSize: 11, color: warningOrange),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: neutralGray,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: const BorderSide(color: borderColor),
                          ),
                          child: const Text('Отмена', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _processImport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Продолжить', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required Function(String?) onChanged,
  }) {
    final isSelected = groupValue == value;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? accentBlue : borderColor,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? accentBlue.withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged,
              activeColor: accentBlue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? accentBlue : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: neutralGray),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}