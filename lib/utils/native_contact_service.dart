import 'package:flutter/services.dart';

class NativeContactService {
  static const MethodChannel _channel = 
      MethodChannel('com.example.student_registration/contact');

  /// Добавляет контакт автоматически через нативный код
  static Future<bool> addContact(String name, String phone) async {
    try {
      final result = await _channel.invokeMethod('addContact', {
        'name': name,
        'phone': phone,
      });
      return result == true;
    } on PlatformException catch (e) {
      print('Ошибка при добавлении контакта: ${e.message}');
      return false;
    }
  }
}