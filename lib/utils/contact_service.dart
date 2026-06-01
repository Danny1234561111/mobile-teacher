// utils/contact_service.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/auth_service.dart';
import '../models/student.dart';
import 'dart:io';

class ContactService {
  static final AuthService _authService = AuthService();
  
  static final MethodChannel _callChannel = MethodChannel('calls');
  
  static Map<String, String>? _cachedActiveContact;
  
  static Future<Map<String, String>?> loadActiveContact() async {
    try {
      print('🔄 ContactService: Загрузка активного контакта...');
      final contact = await _authService.getActiveContact();
      print('📦 ContactService: Получен контакт: $contact');
      _cachedActiveContact = contact;
      return _cachedActiveContact;
    } catch (e) {
      print('❌ ContactService: Ошибка загрузки активного контакта: $e');
      return null;
    }
  }
  
  static Future<Map<String, String>?> getActiveContact() async {
    print('🔍 ContactService: getActiveContact вызван');
    print('   Кэш: $_cachedActiveContact');
    
    if (_cachedActiveContact != null) {
      print('✅ ContactService: Возвращаем из кэша: $_cachedActiveContact');
      return _cachedActiveContact;
    }
    
    print('🔄 ContactService: Кэш пуст, загружаем с сервера...');
    return await loadActiveContact();
  }
  
  static void updateActiveContact(Map<String, String>? contact) {
    _cachedActiveContact = contact;
  }
  
  static void clearCache() {
    _cachedActiveContact = null;
  }
  
  static Future<bool> makeCall(String phoneNumber) async {
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      if (cleanNumber.isEmpty) {
        print('❌ Номер телефона пуст');
        return false;
      }
      
      print('📞 Инициируем немедленный звонок на номер: $cleanNumber');
      
      if (Platform.isAndroid) {
        return await _makeInstantCallAndroid(cleanNumber);
      } else if (Platform.isIOS) {
        return await _makeInstantCallIOS(cleanNumber);
      }
      
      return false;
    } catch (e) {
      print('❌ Ошибка при звонке: $e');
      return false;
    }
  }
  
  static Future<bool> _makeInstantCallAndroid(String phoneNumber) async {
    try {
      final status = await Permission.phone.request();
      if (!status.isGranted) {
        print('❌ Нет разрешения на звонки');
        return false;
      }
      
      final bool result = await _callChannel.invokeMethod('makeCall', {
        'phoneNumber': phoneNumber,
      });
      
      if (result == true) {
        print('✅ Немедленный звонок инициирован на Android');
        return true;
      } else {
        print('❌ Не удалось инициировать звонок через MethodChannel');
        return await _openDialerFallback(phoneNumber);
      }
    } catch (e) {
      print('❌ Ошибка при вызове MethodChannel: $e');
      return await _openDialerFallback(phoneNumber);
    }
  }
  
  static Future<bool> _makeInstantCallIOS(String phoneNumber) async {
    try {
      final Uri url = Uri(scheme: 'tel', path: phoneNumber);
      
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
        print('✅ Немедленный звонок инициирован на iOS');
        return true;
      } else {
        print('❌ Не удалось инициировать звонок на iOS');
        return false;
      }
    } catch (e) {
      print('❌ Ошибка при звонке на iOS: $e');
      return false;
    }
  }
  
  static Future<bool> _openDialerFallback(String phoneNumber) async {
    try {
      final Uri url = Uri(scheme: 'tel', path: phoneNumber);
      
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
        print('📞 Открыт dialer (fallback) с номером: $phoneNumber');
        return true;
      } else {
        print('❌ Не удалось открыть dialer');
        return false;
      }
    } catch (e) {
      print('❌ Ошибка при открытии dialer: $e');
      return false;
    }
  }
  
  static Future<bool> sendSms(String phoneNumber, [String? message]) async {
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      Uri url;
      if (message != null && message.isNotEmpty) {
        url = Uri(scheme: 'sms', path: cleanNumber, query: 
        'body=${Uri.encodeComponent(message)}');
      } else {
        url = Uri(scheme: 'sms', path: cleanNumber);
      }
      print('✉️ Локальная SMS на номер: $cleanNumber');
      
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
        return true;
      } else {
        print('❌ Не удалось открыть SMS');
        return false;
      }
    } catch (e) {
      print('❌ Ошибка при отправке SMS: $e');
      return false;
    }
  }
  
  static Future<bool> openTelegram(String contact, String studentName) async {
    try {
      String username = contact.trim().replaceFirst('@', '');
      username = username.replaceFirst(RegExp(r'^https?://(t\.me/|telegram\.me/)'), '');
      username = username.replaceFirst(RegExp(r'^t\.me/'), '');
      
      print('📱 Локальное открытие Telegram: $username');
      
      String cleanNumber = username.replaceAll(RegExp(r'[^\d]'), '');
      List<Uri> urlsToTry = [];
      
      if (cleanNumber.isNotEmpty && cleanNumber.length >= 10) {
        urlsToTry = [
          Uri.parse('tg://resolve?phone=$cleanNumber'),
          Uri.parse('https://t.me/+$cleanNumber'),
        ];
      } else {
        urlsToTry = [
          Uri.parse('tg://resolve?domain=$username'),
          Uri.parse('https://t.me/$username'),
        ];
      }
      
      for (final url in urlsToTry) {
        try {
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
            print('✅ Успешно открыто: $url');
            return true;
          }
        } catch (e) {
          print('❌ Ошибка при открытии $url: $e');
        }
      }
      
      print('❌ Telegram не установлен');
      return false;
    } catch (e) {
      print('❌ Ошибка при открытии Telegram: $e');
      return false;
    }
  }
  
  // ИСПРАВЛЕННЫЙ метод открытия URL
  static Future<bool> openUrl(String url, {String? studentName}) async {
    try {
      print('🌐 Локальное открытие URL: $url');
      
      if (url.isEmpty) {
        print('❌ URL пуст');
        return false;
      }
      
      String finalUrl = url.trim();
      
      // Проверяем, является ли это уже специальной схемой
      bool isSpecialScheme = finalUrl.startsWith('tg://') || 
                            finalUrl.startsWith('whatsapp://') ||
                            finalUrl.startsWith('vk://') || 
                            finalUrl.startsWith('viber://') ||
                            finalUrl.startsWith('telegram://') ||
                            finalUrl.startsWith('vkontakte://');
      
      // Если это не специальная схема и не начинается с http, добавляем https
      if (!isSpecialScheme && 
          !finalUrl.startsWith('http://') && 
          !finalUrl.startsWith('https://')) {
        finalUrl = 'https://$finalUrl';
      }
      
      print('🌐 Обработанный URL для открытия: $finalUrl');
      
      final Uri uri = Uri.parse(finalUrl);
      
      // Проверяем, можно ли открыть URL
      if (await canLaunchUrl(uri)) {
        // Пытаемся открыть во внешнем приложении
        final result = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
          webViewConfiguration: const WebViewConfiguration(enableJavaScript: true),
        );
        
        if (result) {
          print('✅ URL успешно открыт: $finalUrl');
          return true;
        } else {
          print('❌ launchUrl вернул false для: $finalUrl');
          
          // Пробуем альтернативный способ для web URL
          if (!isSpecialScheme && (finalUrl.startsWith('http://') || finalUrl.startsWith('https://'))) {
            print('🔄 Пробуем открыть в браузере через webView...');
            final webResult = await launchUrl(
              uri,
              mode: LaunchMode.inAppWebView,
            );
            if (webResult) {
              print('✅ URL открыт в WebView');
              return true;
            }
          }
          return false;
        }
      } else {
        print('❌ Не удалось открыть URL (canLaunchUrl false): $finalUrl');
        
        // Для обычных web ссылок пробуем открыть через браузер по умолчанию
        if (!isSpecialScheme && (finalUrl.startsWith('http://') || finalUrl.startsWith('https://'))) {
          print('🔄 Пробуем принудительно открыть в браузере...');
          try {
            final result = await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
              webOnlyWindowName: '_blank',
            );
            if (result) {
              print('✅ URL открыт в браузере');
              return true;
            }
          } catch (e) {
            print('❌ Ошибка при принудительном открытии: $e');
          }
        }
        
        return false;
      }
    } catch (e) {
      print('❌ Ошибка при открытии URL: $e');
      return false;
    }
  }
  
  static Future<bool> openVK(String contact, String studentName) async {
    try {
      print('📱 Локальное открытие VK: $contact');
      
      String vkId = contact;
      if (contact.contains('vk.com/')) {
        vkId = contact.split('vk.com/').last;
        vkId = vkId.split('?').first;
        vkId = vkId.split('#').first;
      }
      vkId = vkId.replaceAll('/', '');
      
      final schemesToTry = [
        'vk://vk.com/$vkId',
        'vk://im?sel=$vkId',
        'vkontakte://$vkId',
      ];
      
      for (final scheme in schemesToTry) {
        final vkAppUrl = Uri.parse(scheme);
        try {
          if (await canLaunchUrl(vkAppUrl)) {
            await launchUrl(vkAppUrl, mode: LaunchMode.externalApplication);
            print('✅ Открыто приложение VK');
            return true;
          }
        } catch (e) {
          print('❌ Не удалось открыть $scheme: $e');
        }
      }
      
      final webUrl = Uri.parse('https://vk.com/$vkId');
      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        print('✅ Открыта web версия VK');
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Ошибка при открытии VK: $e');
      return false;
    }
  }
  
  static void callStudent(String phoneNumber) {
    makeCall(phoneNumber);
  }
  
  static void messageStudent(String phoneNumber) {
    sendSms(phoneNumber);
  }
  
  static void addContactToPhone(Student student) {
    print('📇 Добавление в контакты: ${student.fullName} - ${student.phone}');
  }
}