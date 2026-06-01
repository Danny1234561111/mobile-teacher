// services/student_service.dart - ИСПРАВЛЕННАЯ ВЕРСИЯ

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/student.dart';
import '../models/communication.dart';
import '../models/student_application.dart';
import '../models/group_statistics.dart';
import 'auth_service.dart';
import 'dart:io'; 

class StudentService {
  static const String BASE_URL = 'http://158.160.67.3:8000';
  
  final AuthService _authService = AuthService();
  
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      print('🔑 Заголовок Authorization: Bearer ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
    } else {
      print('⚠️ Токен отсутствует');
    }
    
    return headers;
  }

  Future<Uri> _buildUrl(String path, {Map<String, dynamic>? queryParams}) async {
    final uri = Uri.parse('$BASE_URL$path');
    return uri.replace(queryParameters: queryParams);
  }

  // ========== ПАРСЕР ==========

  Future<Map<String, dynamic>> runParser() async {
    try {
      final url = Uri.parse('$BASE_URL/api/parser/run');
      final headers = await _getHeaders();
      
      print('🔄 Запуск парсера: $url');

      final response = await http.post(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 60));

      print('📊 Статус парсера: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        await _authService.clearAuthData();
        throw Exception('Сессия истекла. Войдите снова.');
      } else {
        throw Exception('Ошибка запуска парсера: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка при запуске парсера: $e');
      throw Exception('Не удалось запустить парсер: $e');
    }
  }

  // ========== СТУДЕНТЫ ==========

  Future<List<Student>> getStudents({
    int skip = 0,
    int limit = 100,
    String? status,
    String? applicationStatus,
    String? contactStatus,
    String? consentStatus,
    int? departmentId,
    int? specialityId,
    String? search,
  }) async {
    try {
      final queryParams = {
        'skip': skip.toString(),
        'limit': limit.toString(),
        if (status != null && status.isNotEmpty) 'status': status,
        if (applicationStatus != null && applicationStatus.isNotEmpty) 'application_status': applicationStatus,
        if (contactStatus != null && contactStatus.isNotEmpty) 'contact_status': contactStatus,
        if (consentStatus != null && consentStatus.isNotEmpty) 'consent_status': consentStatus,
        if (departmentId != null) 'department_id': departmentId.toString(),
        if (specialityId != null) 'speciality_id': specialityId.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final url = await _buildUrl('/api/students', queryParams: queryParams);
      final headers = await _getHeaders();

      print('🔄 Запрос студентов: $url');

      final response = await http.get(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> studentsJson = data['students'] ?? [];
        return studentsJson.map((json) => Student.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        await _authService.clearAuthData();
        throw Exception('Сессия истекла. Пожалуйста, войдите снова.');
      } else {
        final error = json.decode(response.body);
        final errorMessage = error['detail'] ?? 'Ошибка загрузки студентов';
        throw Exception(errorMessage);
      }
    } on http.ClientException catch (e) {
      print('❌ Ошибка сети: $e');
      throw Exception('Нет соединения с сервером. Проверьте подключение.');
    } catch (e) {
      print('❌ Ошибка при загрузке студентов: $e');
      throw Exception('Не удалось загрузить студентов: $e');
    }
  }

  Future<Student> getStudentById(int studentId) async {
    try {
      final url = await _buildUrl('/api/students/$studentId');
      final headers = await _getHeaders();
      
      print('🔄 Получение студента по ID: $url');

      final response = await http.get(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Student.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Студент не найден');
      } else if (response.statusCode == 401) {
        await _authService.clearAuthData();
        throw Exception('Сессия истекла. Войдите снова.');
      } else {
        throw Exception('Ошибка загрузки студента: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка при загрузке студента: $e');
      throw Exception('Не удалось загрузить данные студента: $e');
    }
  }

  Future<List<StudentApplication>> getStudentApplications(int studentId) async {
    try {
      final url = await _buildUrl('/api/students/$studentId/applications');
      final headers = await _getHeaders();
      
      print('🔄 Получение заявлений студента: $url');

      final response = await http.get(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => StudentApplication.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else if (response.statusCode == 401) {
        await _authService.clearAuthData();
        throw Exception('Сессия истекла. Войдите снова.');
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Ошибка при загрузке заявлений: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getStudentCompetitiveInfoForSpeciality(
    int studentId, 
    int specialityId
  ) async {
    try {
      final url = await _buildUrl('/api/students/$studentId/competitive-info/$specialityId');
      final headers = await _getHeaders();
      
      print('🔄 Получение конкурсной информации для специальности $specialityId: $url');

      final response = await http.get(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        return {};
      } else if (response.statusCode == 401) {
        await _authService.clearAuthData();
        throw Exception('Сессия истекла. Войдите снова.');
      } else {
        return {};
      }
    } catch (e) {
      print('❌ Ошибка при загрузке конкурсной информации: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getStudentCompetitiveInfo(int studentId) async {
    try {
      final url = await _buildUrl('/api/students/$studentId/competitive-info');
      final headers = await _getHeaders();
      
      print('🔄 Получение общей конкурсной информации: $url');

      final response = await http.get(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        return {};
      } else if (response.statusCode == 401) {
        await _authService.clearAuthData();
        throw Exception('Сессия истекла. Войдите снова.');
      } else {
        return {};
      }
    } catch (e) {
      print('❌ Ошибка при загрузке конкурсной информации: $e');
      return {};
    }
  }

  Future<Student> createStudent(Map<String, dynamic> studentData) async {
    try {
      if (!studentData.containsKey('full_name') || 
          !studentData.containsKey('russian_student_id') || 
          !studentData.containsKey('phone')) {
        throw Exception('Необходимо указать ФИО, ID и телефон');
      }

      final url = await _buildUrl('/api/students');
      final headers = await _getHeaders();
      
      print('🔄 Создание студента: $url');

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(studentData),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return Student.fromJson(data);
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        final errorMessage = error['detail'] ?? 'Ошибка создания студента';
        throw Exception(errorMessage);
      } else if (response.statusCode == 401) {
        await _authService.clearAuthData();
        throw Exception('Сессия истекла. Войдите снова.');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка при создании студента: $e');
      throw Exception('Не удалось создать студента: $e');
    }
  }

  Future<Student> updateStudent(int id, Map<String, dynamic> updates) async {
    try {
      final url = await _buildUrl('/api/students/$id');
      final headers = await _getHeaders();
      
      print('🔄 Обновление студента: $url');

      final response = await http.put(
        url,
        headers: headers,
        body: json.encode(updates),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Student.fromJson(data);
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        final errorMessage = error['detail'] ?? 'Ошибка обновления студента';
        throw Exception(errorMessage);
      } else if (response.statusCode == 404) {
        throw Exception('Студент не найден');
      } else if (response.statusCode == 401) {
        await _authService.clearAuthData();
        throw Exception('Сессия истекла. Войдите снова.');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка при обновлении студента: $e');
      throw Exception('Не удалось обновить студента: $e');
    }
  }

  Future<void> deleteStudent(int id) async {
    try {
      final url = await _buildUrl('/api/students/$id');
      final headers = await _getHeaders();
      
      print('🔄 Удаление студента: $url');

      final response = await http.delete(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 404) {
        throw Exception('Студент не найден');
      } else if (response.statusCode == 401) {
        await _authService.clearAuthData();
        throw Exception('Сессия истекла. Войдите снова.');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка при удалении студента: $e');
      throw Exception('Не удалось удалить студента: $e');
    }
  }

  // ========== КОММУНИКАЦИИ ==========

  Future<List<Communication>> getStudentCommunications(
    int studentId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        'offset': offset.toString(),
      };

      final url = await _buildUrl(
        '/api/students/$studentId/communications',
        queryParams: queryParams,
      );
      final headers = await _getHeaders();

      print('🔄 Получение коммуникаций студента: $url');

      final response = await http.get(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Communication.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        await _authService.clearAuthData();
        throw Exception('Сессия истекла. Войдите снова.');
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Ошибка при загрузке коммуникаций: $e');
      return [];
    }
  }

  Future<Communication> createCommunication(
    int studentId,
    Map<String, dynamic> data,
  ) async {
    try {
      final url = await _buildUrl('/api/students/$studentId/communications');
      final headers = await _getHeaders();
      
      print('🔄 Создание коммуникации: $url');

      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(data),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return Communication.fromJson(responseData);
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        final errorMessage = error['detail'] ?? 'Ошибка создания коммуникации';
        throw Exception(errorMessage);
      } else if (response.statusCode == 401) {
        await _authService.clearAuthData();
        throw Exception('Сессия истекла. Войдите снова.');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка при создании коммуникации: $e');
      throw Exception('Не удалось создать запись о коммуникации: $e');
    }
  }

  Future<Communication> updateCommunication(
    int commId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final url = await _buildUrl('/api/students/communications/$commId');
      final headers = await _getHeaders();
      
      print('🔄 Обновление коммуникации: $url');

      final response = await http.put(
        url,
        headers: headers,
        body: json.encode(updates),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Communication.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Коммуникация не найдена');
      } else if (response.statusCode == 401) {
        await _authService.clearAuthData();
        throw Exception('Сессия истекла. Войдите снова.');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка при обновлении коммуникации: $e');
      throw Exception('Не удалось обновить коммуникацию: $e');
    }
  }

  Future<void> deleteCommunication(int commId) async {
    try {
      final url = await _buildUrl('/api/students/communications/$commId');
      final headers = await _getHeaders();
      
      print('🔄 Удаление коммуникации: $url');

      final response = await http.delete(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 404) {
        throw Exception('Коммуникация не найдена');
      } else if (response.statusCode == 401) {
        await _authService.clearAuthData();
        throw Exception('Сессия истекла. Войдите снова.');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка при удалении коммуникации: $e');
      throw Exception('Не удалось удалить коммуникацию: $e');
    }
  }

  Future<Map<String, dynamic>> getCommunicationStats({int daysBack = 30}) async {
    try {
      final queryParams = {'days_back': daysBack.toString()};
      final url = await _buildUrl(
        '/api/students/communications/stats',
        queryParams: queryParams,
      );
      final headers = await _getHeaders();

      print('🔄 Получение статистики коммуникаций: $url');

      final response = await http.get(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await _authService.clearAuthData();
        throw Exception('Сессия истекла. Войдите снова.');
      } else {
        return {};
      }
    } catch (e) {
      print('❌ Ошибка при загрузке статистики: $e');
      return {};
    }
  }

  Future<bool> testConnection() async {
    try {
      final url = Uri.parse('$BASE_URL/health');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Ошибка проверки соединения: $e');
      return false;
    }
  }

  // ========== СПРАВОЧНИКИ ==========

  Future<List<Map<String, dynamic>>> getDepartments() async {
    try {
      final url = await _buildUrl('/api/admin/departments');
      final headers = await _getHeaders();

      print('🔄 Получение списка направлений: $url');

      final response = await http.get(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Ошибка при загрузке направлений: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getSpecialities({int? departmentId}) async {
    try {
      final queryParams = <String, String>{};
      if (departmentId != null) {
        queryParams['department_id'] = departmentId.toString();
      }

      final url = await _buildUrl('/api/admin/specialities', queryParams: queryParams);
      final headers = await _getHeaders();

      print('🔄 Получение списка специальностей: $url');

      final response = await http.get(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Ошибка при загрузке специальностей: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getProfiles({int? specialityId}) async {
    try {
      final queryParams = <String, String>{};
      if (specialityId != null) {
        queryParams['speciality_id'] = specialityId.toString();
      }

      final url = await _buildUrl('/api/admin/profiles', queryParams: queryParams);
      final headers = await _getHeaders();

      print('🔄 Получение списка профилей: $url');

      final response = await http.get(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Ошибка при загрузке профилей: $e');
      return [];
    }
  }

  // ========== АКТИВНЫЙ КОНТАКТ (ИСПРАВЛЕНО: правильные эндпоинты как в веб-версии) ==========

  /// Получить активный контакт пользователя
  /// Эндпоинт: GET /api/user/contact/active/get (как в веб-версии)
  Future<Map<String, dynamic>?> getActiveContact() async {
    try {
      final token = await _authService.getToken();
      print('🔑 getActiveContact: token = ${token != null ? "есть" : "нет"}');
      
      if (token == null) {
        print('❌ getActiveContact: Нет токена');
        return null;
      }
      
      // ИСПРАВЛЕНО: правильный эндпоинт /api/user/contact/active/get
      final url = Uri.parse('$BASE_URL/api/user/contact/active/get');
      final headers = await _getHeaders();
      
      print('🔄 getActiveContact: Запрос к $url');
      
      final response = await http.get(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      
      print('📊 getActiveContact: Статус ответа ${response.statusCode}');
      print('📝 getActiveContact: Тело ответа ${response.body}');
      
      if (response.statusCode == 200 && response.body.isNotEmpty && response.body != 'null') {
        final data = json.decode(response.body);
        print('✅ getActiveContact: Получены данные: $data');
        
        if (data != null && data['contact_type'] != null && data['contact_value'] != null) {
          return {
            'contact_type': data['contact_type'],
            'contact_value': data['contact_value'],
          };
        }
      } else if (response.statusCode == 404) {
        print('⚠️ getActiveContact: Активный контакт не найден (404)');
      } else if (response.statusCode == 403) {
        print('⚠️ getActiveContact: Доступ запрещен (403)');
      }
      
      return null;
    } catch (e) {
      print('❌ getActiveContact: Ошибка $e');
      return null;
    }
  }

  /// Установить активный контакт
  /// Эндпоинт: POST /api/user/contact/active/set (как в веб-версии)
  Future<Map<String, dynamic>> setActiveContact(String contactType, String contactValue) async {
    try {
      final url = Uri.parse('$BASE_URL/api/user/contact/active/set');
      final headers = await _getHeaders();
      
      final body = {
        'contact_type': contactType,
        'contact_value': contactValue,
      };
      
      print('🔄 setActiveContact: Запрос к $url');
      print('📦 Тело запроса: $body');
      
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(body),
      ).timeout(const Duration(seconds: 30));
      
      print('📊 setActiveContact: Статус ответа ${response.statusCode}');
      print('📝 setActiveContact: Тело ответа ${response.body}');
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Ошибка установки активного контакта: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка установки активного контакта: $e');
      throw Exception('Не удалось установить активный контакт: $e');
    }
  }

  /// Удалить активный контакт
  /// Эндпоинт: DELETE /api/user/contact/active/delete (как в веб-версии)
  Future<void> deleteActiveContact() async {
    try {
      final url = Uri.parse('$BASE_URL/api/user/contact/active/delete');
      final headers = await _getHeaders();
      
      print('🔄 deleteActiveContact: Запрос к $url');
      
      final response = await http.delete(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 30));
      
      print('📊 deleteActiveContact: Статус ответа ${response.statusCode}');
      
      if (response.statusCode != 200) {
        throw Exception('Ошибка удаления активного контакта: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка удаления активного контакта: $e');
      throw Exception('Не удалось удалить активный контакт: $e');
    }
  }

  // ========== СТАТИСТИКА ГРУПП ==========

  Future<List<GroupStatistics>> getGroupStatistics() async {
    try {
      final url = await _buildUrl('/api/students/statistics/groups');
      final headers = await _getHeaders();
      
      print('🔄 Получение статистики групп: $url');

      final response = await http.get(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => GroupStatistics.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        await _authService.clearAuthData();
        throw Exception('Сессия истекла. Войдите снова.');
      } else {
        print('⚠️ Ошибка получения статистики групп: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Ошибка при загрузке статистики групп: $e');
      return [];
    }
  }

  // ========== EXCEL ИМПОРТ ==========

  Future<Map<String, dynamic>> importExcel(File file, String strategy, [List<int>? replaceIds]) async {
    try {
      final url = Uri.parse('$BASE_URL/api/excel-import/upload');
      final headers = await _getHeaders();
      
      print('🔄 Импорт Excel файла: ${file.path}');
      print('📊 Стратегия: $strategy');
      if (replaceIds != null && replaceIds.isNotEmpty) {
        print('🆔 ID для замены: $replaceIds');
      }
      
      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(headers);
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      request.fields['duplicate_strategy'] = strategy;
      if (replaceIds != null && replaceIds.isNotEmpty) {
        request.fields['replace_ids'] = json.encode(replaceIds);
      }
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      print('📊 Статус ответа: ${response.statusCode}');
      print('📝 Ответ: $responseBody');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(responseBody);
        return data;
      } else if (response.statusCode == 400) {
        try {
          final error = json.decode(responseBody);
          throw Exception(error['detail'] ?? 'Ошибка валидации данных');
        } catch (e) {
          throw Exception('Ошибка валидации: $responseBody');
        }
      } else if (response.statusCode == 401) {
        await _authService.clearAuthData();
        throw Exception('Сессия истекла. Войдите снова.');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка импорта Excel: $e');
      throw Exception('Не удалось импортировать файл: $e');
    }
  }
}