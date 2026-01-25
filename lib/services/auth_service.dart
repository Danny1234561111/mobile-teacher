import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_response.dart';
import '../models/register_dto.dart';
import '../models/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String BASE_URL = 'https://python-project-mu-five.vercel.app';
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
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

  Future<Map<String, String>> _getHeaders({bool withAuth = false}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (withAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> saveAuthData(AuthResponse authResponse) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Сохраняем токен доступа
    if (authResponse.token.isNotEmpty) {
      await prefs.setString(_tokenKey, authResponse.token);
    }
    
    // Сохраняем refresh token если он есть
    if (authResponse.refreshToken != null && authResponse.refreshToken!.isNotEmpty) {
      await prefs.setString(_refreshTokenKey, authResponse.refreshToken!);
    }
    
    // Сохраняем данные пользователя
    if (authResponse.user != null) {
      await prefs.setString(_userKey, json.encode(authResponse.user.toJson()));
    }
  }

  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
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
      
      final requestBody = json.encode({
        'email': email,
        'password': password,
      });

      print('🔄 Отправка запроса на логин: $url');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      ).timeout(const Duration(seconds: 30));

      print('📊 Статус ответа: ${response.statusCode}');
      print('📝 Тело ответа: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Проверяем структуру ответа
        print('📦 Структура ответа:');
        data.forEach((key, value) => print('  $key: $value'));
        
        // Создаем AuthResponse из данных
        final authResponse = AuthResponse.fromJson(data);
        
        // Сохраняем данные
        await saveAuthData(authResponse);
        // Сохраняем учетные данные для автовхода
        await saveCredentials(email, password);
        
        print('✅ Успешный вход: ${authResponse.user?.email ?? "unknown"}');
        return authResponse;
      } else if (response.statusCode == 401) {
        final error = json.decode(response.body);
        final errorMessage = error['detail'] ?? 'Неверный email или пароль';
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

  Future<AuthResponse> register(RegisterDto registerDto) async {
    try {
      final url = Uri.parse('$BASE_URL/api/auth/register');

      print('🔄 Отправка запроса на регистрацию: $url');

      // Используем toJson() из RegisterDto
      final requestBody = json.encode(registerDto.toJson());

      print('📦 Тело запроса: $requestBody');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      ).timeout(const Duration(seconds: 30));

      print('📊 Статус ответа: ${response.statusCode}');
      print('📝 Тело ответа: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        // Проверяем структуру ответа
        print('📦 Структура ответа:');
        data.forEach((key, value) => print('  $key: $value'));
        
        final authResponse = AuthResponse.fromJson(data);
        
        // Сохраняем данные
        await saveAuthData(authResponse);
        // Сохраняем учетные данные для автовхода
        await saveCredentials(registerDto.email, registerDto.password);
        
        print('✅ Успешная регистрация: ${authResponse.user?.email ?? "unknown"}');
        return authResponse;
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        final errorMessage = error['detail'] ?? error['message'] ?? 'Ошибка регистрации';
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
      print('❌ Ошибка регистрации: $e');
      throw Exception('Произошла ошибка при регистрации: $e');
    }
  }

  // Регистрация преподавателя через заявку
  Future<Map<String, dynamic>> registerTeacherRequest(RegisterDto registerDto) async {
    try {
      final url = Uri.parse('$BASE_URL/api/auth/register/teacher-request');

      print('🔄 Отправка заявки на регистрацию преподавателя: $url');

      final requestBody = json.encode(registerDto.toJson());

      print('📦 Тело запроса: $requestBody');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      ).timeout(const Duration(seconds: 30));

      print('📊 Статус ответа: ${response.statusCode}');
      print('📝 Тело ответа: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        
        print('✅ Заявка успешно отправлена');
        return data;
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        final errorMessage = error['detail'] ?? error['message'] ?? 'Ошибка отправки заявки';
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
      print('❌ Ошибка отправки заявки: $e');
      throw Exception('Произошла ошибка при отправке заявки: $e');
    }
  }

  Future<AuthResponse> autoLogin() async {
    try {
      final credentials = await getSavedCredentials();
      if (credentials == null) {
        throw Exception('Нет сохраненных учетных данных для авто-логина');
      }

      print('🔄 Попытка автовхода для: ${credentials['email']}');
      
      // Пробуем войти с сохраненными учетными данными
      return await login(credentials['email']!, credentials['password']!);
    } catch (e) {
      print('❌ Ошибка автовхода: $e');
      throw Exception('Не удалось выполнить авто-вход: $e');
    }
  }

  Future<User> getProfile() async {
  try {
    final token = await getToken();
    
    if (token == null) {
      throw Exception('Не авторизован');
    }

    final url = Uri.parse('$BASE_URL/api/auth/me');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };

    print('🔄 Запрос профиля: $url');

    final response = await http.get(
      url,
      headers: headers,
    ).timeout(const Duration(seconds: 10));

    print('📊 Статус профиля: ${response.statusCode}');
    print('📝 Тело профиля: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['user'] != null) {
        final user = User.fromJson(data['user']);
        
        // Обновляем данные пользователя в хранилище
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, json.encode(user.toJson()));
        
        return user;
      }
      throw Exception('Данные пользователя не найдены в ответе');
    } else if (response.statusCode == 401) {
      // Токен невалиден
      throw Exception('Токен невалиден. Код: 401');
    } else {
      throw Exception('Ошибка загрузки профиля: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Ошибка загрузки профиля: $e');
    throw Exception('Не удалось загрузить профиль: $e');
  }
}
  Future<bool> _tryRefreshToken() async {
    try {
      // Сначала пробуем обновить токен через refresh token
      final newToken = await refreshToken();
      if (newToken != null) {
        return true;
      }
      
      // Если refresh token не сработал, пробуем авто-логин
      await autoLogin();
      return true;
    } catch (e) {
      print('❌ Не удалось обновить токен: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        final url = Uri.parse('$BASE_URL/api/auth/logout');
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        };
        
        await http.post(
          url,
          headers: headers,
        ).timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      print('⚠️  Ошибка при выходе на сервере: $e');
      // Даже при ошибке продолжаем очистку локальных данных
    }
    
    // Отключаем авто-логин
    await disableAutoLogin();
    
    // Очищаем локальные данные
    await clearAuthData();
    await clearCredentials();
    
    print('✅ Выход выполнен');
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null) {
      print('⚠️  Токен не найден');
      return false;
    }
    
    try {
      // Пробуем получить профиль - это проверит валидность токена
      await getProfile();
      return true;
    } catch (e) {
      print('❌ Токен невалиден: $e');
      
      // Пробуем обновить токен через авто-логин
      try {
        await _tryRefreshToken();
        return true;
      } catch (refreshError) {
        print('❌ Не удалось обновить токен: $refreshError');
        return false;
      }
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

  // Проверка валидности токена
  Future<bool> validateToken() async {
    try {
      await getProfile();
      return true;
    } catch (e) {
      print('❌ Токен невалиден: $e');
      return false;
    }
  }

  // Обновление токена через refresh token
  Future<String?> refreshToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        print('⚠️  Refresh token не найден');
        return null;
      }
      
      final url = Uri.parse('$BASE_URL/api/auth/refresh');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh_token': refreshToken}),
      ).timeout(const Duration(seconds: 10));
      
      print('🔄 Обновление токена: ${response.statusCode}');
      print('📝 Ответ: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newToken = data['token'] as String?;
        final newRefreshToken = data['refresh_token'] as String?;
        
        if (newToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, newToken);
          
          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            await prefs.setString(_refreshTokenKey, newRefreshToken);
          }
          
          print('✅ Токен обновлен через refresh token');
          return newToken;
        }
      }
      return null;
    } catch (e) {
      print('❌ Ошибка обновления токена через refresh token: $e');
      return null;
    }
  }

  // Проверка статуса регистрации
  Future<Map<String, dynamic>> checkRegistrationStatus(String email) async {
    try {
      final url = Uri.parse('$BASE_URL/api/auth/check-status/${Uri.encodeComponent(email)}');
      
      print('🔄 Проверка статуса регистрации для: $email');
      
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      print('📊 Статус ответа: ${response.statusCode}');
      print('📝 Тело ответа: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        final errorMessage = error['detail'] ?? 'Ошибка проверки статуса';
        throw Exception(errorMessage);
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Ошибка проверки статуса: $e');
      throw Exception('Не удалось проверить статус регистрации: $e');
    }
  }

  // Вспомогательные методы для отладки
  Future<void> printDebugInfo() async {
    print('🔍 Информация о AuthService:');
    print('  • Base URL: $BASE_URL');
    print('  • Токен: ${await getToken() ?? "нет"}');
    print('  • Refresh токен: ${await getRefreshToken() ?? "нет"}');
    print('  • Сохраненные данные: ${await getSavedCredentials() != null ? "да" : "нет"}');
    
    final user = await getCurrentUser();
    if (user != null) {
      print('  • Пользователь: ${user.email} (${user.fullName})');
      print('  • Роль: ${user.role}');
    } else {
      print('  • Пользователь: не загружен');
    }
  }
  Future<bool> checkAndRestoreAuth() async {
  try {
    print('🔄 Проверка и восстановление авторизации...');
    
    // 1. Проверяем есть ли токен и он валиден
    final token = await getToken();
    if (token != null) {
      try {
        await getProfile();
        print('✅ Токен валиден');
        return true;
      } catch (e) {
        print('❌ Токен невалиден: $e');
        // Токен невалиден, пробуем авто-логин
      }
    }
    
    // 2. Пробуем авто-логин если есть сохраненные данные
      final credentials = await getSavedCredentials();
      if (credentials == null) {
        print('⚠️  Нет сохраненных данных для авто-логина');
        return false;
      }
      
      print('🔄 Пробуем авто-логин с сохраненными данными...');
      try {
        final response = await autoLogin();
        print('✅ Авто-логин успешен для: ${response.user?.email}');
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
      
      // 1. Проверяем, есть ли сохраненные данные
      final credentials = await getSavedCredentials();
      if (credentials == null) {
        print('❌ Нет сохраненных данных для авто-логина');
        return false;
      }
      
      print('📧 Есть сохраненные данные для: ${credentials['email']}');
      
      // 2. Проверяем соединение
      final hasConnection = await testConnection();
      if (!hasConnection) {
        print('❌ Нет соединения с сервером');
        return false;
      }
      
      // 3. Пробуем сделать авто-логин
      try {
        print('🔄 Пробуем авто-логин...');
        final response = await login(credentials['email']!, credentials['password']!);
        
        if (response.token.isNotEmpty) {
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
}