// services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_response.dart';
import '../models/login_dto.dart';
import '../models/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String BASE_URL = 'http://158.160.67.3:8000';
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _emailKey = 'saved_email';
  static const String _passwordKey = 'saved_password';
  static const String _isAutoLoginEnabledKey = 'auto_login_enabled';

  // Сохраняем логин и пароль
  Future<void> saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
    await prefs.setString(_passwordKey, password);
    await prefs.setBool(_isAutoLoginEnabledKey, true);
  }

  // Получаем сохраненные данные
  Future<Map<String, String>?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final isAutoLoginEnabled = prefs.getBool(_isAutoLoginEnabledKey) ?? true;
    
    if (!isAutoLoginEnabled) {
      return null;
    }
    
    final email = prefs.getString(_emailKey);
    final password = prefs.getString(_passwordKey);
    
    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }

  // Отключаем авто-логин (при выходе)
  Future<void> disableAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isAutoLoginEnabledKey, false);
  }

  // Включаем авто-логин (при успешном входе)
  Future<void> enableAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isAutoLoginEnabledKey, true);
  }

  // Очищаем сохраненные данные
  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
    await prefs.remove(_passwordKey);
    await prefs.remove(_isAutoLoginEnabledKey);
  }

  // Получение заголовков с Bearer токеном (для /api/students/*)
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      print('🔑 Добавлен Bearer токен: ${token.substring(0, min(20, token.length))}...');
    } else {
      print('⚠️ Токен отсутствует');
    }
    
    return headers;
  }

  // Получение URL с токеном в query параметре (для /api/auth/me)
  Future<Uri> getUrlWithToken(String path) async {
    final token = await getToken();
    final uri = Uri.parse('$BASE_URL$path');
    
    if (token != null && token.isNotEmpty) {
      return uri.replace(queryParameters: {'token': token});
    }
    return uri;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveAuthData(AuthResponse authResponse) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (authResponse.accessToken.isNotEmpty) {
      await prefs.setString(_tokenKey, authResponse.accessToken);
      print('✅ Токен сохранен: ${authResponse.accessToken.substring(0, min(20, authResponse.accessToken.length))}...');
    }
    
    await prefs.setString(_userKey, json.encode(authResponse.user.toJson()));
  }

  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    print('🗑️ Данные авторизации очищены');
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        final userData = json.decode(userJson);
        return User.fromJson(userData);
      } catch (e) {
        print('❌ Ошибка декодирования пользователя: $e');
        return null;
      }
    }
    return null;
  }

  Future<AuthResponse> login(String email, String password) async {
    try {
      final url = Uri.parse('$BASE_URL/api/auth/login');
      
      final loginDto = LoginDto(email: email, password: password);
      final requestBody = json.encode(loginDto.toJson());

      print('🔄 Отправка запроса на логин: $url');
      print('📦 Тело запроса: $requestBody');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      ).timeout(const Duration(seconds: 30));

      print('📊 Статус ответа: ${response.statusCode}');
      print('📝 Тело ответа: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        final authResponse = AuthResponse.fromJson(data);
        
        await saveAuthData(authResponse);
        await saveCredentials(email, password);
        
        print('✅ Успешный вход: ${authResponse.user.email}');
        print('🔑 Получен токен: ${authResponse.accessToken.substring(0, min(20, authResponse.accessToken.length))}...');
        
        return authResponse;
      } else if (response.statusCode == 401) {
        final error = json.decode(response.body);
        final errorMessage = error['detail'] ?? 'Неверный email или пароль';
        throw Exception(errorMessage);
      } else if (response.statusCode == 422) {
        final error = json.decode(response.body);
        final errorMessage = error['detail']?.isNotEmpty == true 
            ? error['detail'][0]['msg'] ?? 'Ошибка валидации'
            : 'Ошибка валидации данных';
        throw Exception(errorMessage);
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      print('❌ Ошибка сети: $e');
      throw Exception('Не удалось подключиться к серверу. Проверьте интернет-соединение.');
    } on FormatException catch (e) {
      print('❌ Ошибка формата ответа: $e');
      throw Exception('Сервер вернул неверный формат данных.');
    } catch (e) {
      print('❌ Ошибка входа: $e');
      throw Exception('Произошла ошибка при входе: $e');
    }
  }

  Future<AuthResponse> autoLogin() async {
    try {
      final credentials = await getSavedCredentials();
      if (credentials == null) {
        throw Exception('Нет сохраненных учетных данных для авто-логина');
      }

      print('🔄 Попытка автовхода для: ${credentials['email']}');
      
      return await login(credentials['email']!, credentials['password']!);
    } catch (e) {
      print('❌ Ошибка автовхода: $e');
      throw Exception('Не удалось выполнить авто-вход: $e');
    }
  }

  // ИСПРАВЛЕНО: токен в query параметре для /api/auth/me
  Future<User> getProfile() async {
    try {
      final token = await getToken();
      
      if (token == null) {
        throw Exception('Не авторизован');
      }

      // ВАЖНО: токен в query параметре, не в заголовке!
      final url = Uri.parse('$BASE_URL/api/auth/me').replace(
        queryParameters: {'token': token}
      );

      print('🔄 Запрос профиля: $url');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'}, // Без Authorization
      ).timeout(const Duration(seconds: 10));

      print('📊 Статус профиля: ${response.statusCode}');
      print('📝 Тело профиля: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = User.fromJson(data);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, json.encode(user.toJson()));
        
        return user;
      } else if (response.statusCode == 401) {
        await clearAuthData();
        throw Exception('Токен невалиден');
      } else if (response.statusCode == 422) {
        // Сервер ожидает токен в query параметре
        throw Exception('Ошибка формата запроса. Токен должен быть в query параметре');
      } else {
        throw Exception('Ошибка загрузки профиля: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка загрузки профиля: $e');
      throw Exception('Не удалось загрузить профиль: $e');
    }
  }

  // ИСПРАВЛЕНО: для /api/auth/logout тоже используем query параметр
  Future<void> logout() async {
    try {
      final token = await getToken();
      
      if (token != null) {
        final url = Uri.parse('$BASE_URL/api/auth/logout').replace(
          queryParameters: {'token': token}
        );
        
        print('🔄 Выход из системы: $url');
        
        await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      print('⚠️ Ошибка при выходе на сервере: $e');
    }
    
    await disableAutoLogin();
    await clearAuthData();
    await clearCredentials();
    
    print('✅ Выход выполнен');
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null) {
      print('⚠️ Токен не найден');
      return false;
    }
    
    try {
      await getProfile();
      return true;
    } catch (e) {
      print('❌ Токен невалиден: $e');
      return false;
    }
  }

  Future<bool> testConnection() async {
    try {
      final url = Uri.parse('$BASE_URL/health');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      print('🔗 Проверка соединения: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Ошибка проверки соединения: $e');
      return false;
    }
  }

  Future<bool> validateToken() async {
    try {
      await getProfile();
      return true;
    } catch (e) {
      print('❌ Токен невалиден: $e');
      return false;
    }
  }

  Future<bool> checkAndRestoreAuth() async {
    try {
      print('🔄 Проверка и восстановление авторизации...');
      
      final token = await getToken();
      if (token != null) {
        print('🔑 Найден токен, проверяем валидность...');
        try {
          await getProfile();
          print('✅ Токен валиден');
          return true;
        } catch (e) {
          print('❌ Токен невалиден: $e');
        }
      }
      
      final credentials = await getSavedCredentials();
      if (credentials == null) {
        print('⚠️ Нет сохраненных данных для авто-логина');
        return false;
      }
      
      print('🔄 Пробуем авто-логин с сохраненными данными...');
      try {
        await autoLogin();
        print('✅ Авто-логин успешен');
        return true;
      } catch (e) {
        print('❌ Авто-логин не удался: $e');
        return false;
      }
    } catch (e) {
      print('❌ Ошибка в checkAndRestoreAuth: $e');
      return false;
    }
  }

  Future<bool> tryAutoLoginIfPossible() async {
    try {
      print('🔄 Проверяем возможность авто-логина...');
      
      final credentials = await getSavedCredentials();
      if (credentials == null) {
        print('❌ Нет сохраненных данных для авто-логина');
        return false;
      }
      
      print('📧 Есть сохраненные данные для: ${credentials['email']}');
      
      final hasConnection = await testConnection();
      if (!hasConnection) {
        print('❌ Нет соединения с сервером');
        return false;
      }
      
      try {
        print('🔄 Пробуем авто-логин...');
        final response = await login(credentials['email']!, credentials['password']!);
        
        if (response.accessToken.isNotEmpty) {
          print('✅ Авто-логин успешен!');
          return true;
        }
      } catch (e) {
        print('❌ Авто-логин не удался: $e');
        return false;
      }
      
      return false;
    } catch (e) {
      print('❌ Ошибка в tryAutoLoginIfPossible: $e');
      return false;
    }
  }

  Future<void> printDebugInfo() async {
    print('🔍 Информация о AuthService:');
    print('  • Base URL: $BASE_URL');
    
    final token = await getToken();
    if (token != null) {
      print('  • Токен: ${token.substring(0, min(20, token.length))}... (длина: ${token.length})');
    } else {
      print('  • Токен: нет');
    }
    
    final user = await getCurrentUser();
    if (user != null) {
      print('  • Пользователь: ${user.email} (${user.fullName})');
      print('  • Роль: ${user.role}');
      print('  • ID: ${user.id}');
    } else {
      print('  • Пользователь: не загружен');
    }
  }
}

// Вспомогательная функция для безопасного обрезания строк
int min(int a, int b) => a < b ? a : b;