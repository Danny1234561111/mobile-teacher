import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/student.dart';
import '../models/communication.dart';
import 'auth_service.dart';

class StudentService {
  // Базовый URL вашего Vercel проекта
  static const String BASE_URL = 'https://python-project-mu-five.vercel.app';
  
  final AuthService _authService = AuthService();
  
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getToken();
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  Future<List<Student>> getMyStudents({
    int skip = 0,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    try {
      final queryParams = {
        'skip': skip.toString(),
        'limit': limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
      };

      // Получаем студентов текущего преподавателя
      final url = Uri.parse('$BASE_URL/api/students/my-students')
          .replace(queryParameters: queryParams);

       print('🔄 Запрос студентов: $url');
    
      final headers = await _getHeaders();
      print('🔑 Заголовки: $headers');

      final response = await http.get(
        url,
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      print('📊 Статус: ${response.statusCode}');
      print('📝 Ответ: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.map((json) => Student.fromJson(json)).toList();
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

  Future<Student> getStudentById(String studentId) async {
    try {
      final url = Uri.parse('$BASE_URL/api/students/$studentId');
      
      print('🔄 Получение студента по ID: $url');

      final response = await http.get(
        url,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Student.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Студент не найден');
      } else if (response.statusCode == 401) {
        await _authService.clearAuthData();
        throw Exception('Неавторизованный доступ. Войдите в систему.');
      } else {
        throw Exception('Ошибка загрузки студента: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка при загрузке студента: $e');
      throw Exception('Не удалось загрузить данные студента: $e');
    }
  }

  Future<Student> createStudent(Map<String, dynamic> studentData) async {
    try {
      final url = Uri.parse('$BASE_URL/api/students');
      
      print('🔄 Создание студента: $url');

      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: json.encode(studentData),
      ).timeout(const Duration(seconds: 30));

      print('📊 Статус: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return Student.fromJson(data);
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        final errorMessage = error['detail'] ?? 'Ошибка создания студента';
        throw Exception(errorMessage);
      } else if (response.statusCode == 401) {
        await _authService.clearAuthData();
        throw Exception('Неавторизованный доступ. Войдите в систему.');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка при создании студента: $e');
      throw Exception('Не удалось создать студента: $e');
    }
  }

  Future<Student> updateStudent(String id, Map<String, dynamic> updates) async {
    try {
      final url = Uri.parse('$BASE_URL/api/students/$id');
      
      print('🔄 Обновление студента: $url');

      final response = await http.put(
        url,
        headers: await _getHeaders(),
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
        throw Exception('Неавторизованный доступ. Войдите в систему.');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка при обновлении студента: $e');
      throw Exception('Не удалось обновить студента: $e');
    }
  }

  Future<void> deleteStudent(String id) async {
    try {
      final url = Uri.parse('$BASE_URL/api/students/$id');
      
      print('🔄 Удаление студента: $url');

      final response = await http.delete(
        url,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 404) {
        throw Exception('Студент не найден');
      } else if (response.statusCode == 401) {
        await _authService.clearAuthData();
        throw Exception('Неавторизованный доступ. Войдите в систему.');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка при удалении студента: $e');
      throw Exception('Не удалось удалить студента: $e');
    }
  }

  // История коммуникаций
  Future<List<Communication>> getStudentCommunications(String studentId,
      {int skip = 0, int limit = 50}) async {
    try {
      final queryParams = {
        'skip': skip.toString(),
        'limit': limit.toString(),
      };

      final url = Uri.parse('$BASE_URL/api/students/$studentId/communications')
          .replace(queryParameters: queryParams);

      print('🔄 Получение коммуникаций студента: $url');

      final response = await http.get(
        url,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.map((json) => Communication.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        await _authService.clearAuthData();
        throw Exception('Неавторизованный доступ. Войдите в систему.');
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Ошибка при загрузке коммуникаций: $e');
      return [];
    }
  }

  Future<Communication> createCommunication(
      String studentId, Map<String, dynamic> data) async {
    try {
      final url = Uri.parse('$BASE_URL/api/students/$studentId/communications');
      
      print('🔄 Создание коммуникации: $url');

      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: json.encode(data),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return Communication.fromJson(responseData);
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        final errorMessage = error['detail'] ?? 'Ошибка создания коммуникации';
        throw Exception(errorMessage);
      } else if (response.statusCode == 401) {
        await _authService.clearAuthData();
        throw Exception('Неавторизованный доступ. Войдите в систему.');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка при создании коммуникации: $e');
      throw Exception('Не удалось создать запись о коммуникации: $e');
    }
  }

  Future<List<Communication>> getMyCommunications(
      {int skip = 0, int limit = 50, bool importantOnly = false}) async {
    try {
      final queryParams = {
        'skip': skip.toString(),
        'limit': limit.toString(),
        'important_only': importantOnly.toString(),
      };

      final url = Uri.parse('$BASE_URL/api/students/communications/my')
          .replace(queryParameters: queryParams);

      print('🔄 Получение моих коммуникаций: $url');

      final response = await http.get(
        url,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data.map((json) => Communication.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        await _authService.clearAuthData();
        throw Exception('Неавторизованный доступ. Войдите в систему.');
      } else {
        return [];
      }
    } catch (e) {
      print('❌ Ошибка при загрузке коммуникаций: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getCommunicationStats(
      {int daysBack = 30}) async {
    try {
      final queryParams = {
        'days_back': daysBack.toString(),
      };

      final url = Uri.parse('$BASE_URL/api/students/communications/stats')
          .replace(queryParameters: queryParams);

      print('🔄 Получение статистики коммуникаций: $url');

      final response = await http.get(
        url,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await _authService.clearAuthData();
        throw Exception('Неавторизованный доступ. Войдите в систему.');
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
}