// utils/contact_service.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../models/student.dart';

class ContactService {
  static final AuthService _authService = AuthService();
  
  // Текущий активный контакт пользователя (кэшированный)
  static Map<String, String>? _cachedActiveContact;
  
  // Загрузка активного контакта с сервера
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
  
  // Получение активного контакта (из кэша или с сервера)
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
  
  // Обновить кэш активного контакта
  static void updateActiveContact(Map<String, String>? contact) {
    _cachedActiveContact = contact;
  }
  
  // Очистить кэш
  static void clearCache() {
    _cachedActiveContact = null;
  }
  
  // НОВЫЙ МЕТОД ДЛЯ ОТКРЫТИЯ URL (поддерживает приложения)
  static Future<bool> openUrl(String url, {String? studentName}) async {
    try {
      print('🌐 Открываем URL: $url');
      
      String finalUrl = url.trim();
      
      // Добавляем https:// если нет схемы
      if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://') &&
          !finalUrl.startsWith('tg://') && !finalUrl.startsWith('whatsapp://') &&
          !finalUrl.startsWith('vk://') && !finalUrl.startsWith('viber://') &&
          !finalUrl.startsWith('telegram://')) {
        finalUrl = 'https://$finalUrl';
      }
      
      final Uri uri = Uri.parse(finalUrl);
      
      // Пробуем открыть в приложении (если можно)
      final canOpenInApp = await canLaunchUrl(uri);
      print('📱 Проверка возможности открыть URL: $canOpenInApp');
      
      if (canOpenInApp) {
        // Открываем в приложении, если оно установлено
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        print('✅ Открыто в приложении: $finalUrl');
        return true;
      } else {
        // Если приложение не установлено, открываем в браузере
        print('⚠️ Приложение не установлено, открываем в браузере');
        final webUri = Uri.parse(finalUrl);
        if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
          print('✅ Открыто в браузере: $finalUrl');
          return true;
        }
      }
      
      print('❌ Не удалось открыть URL');
      return false;
    } catch (e) {
      print('❌ Ошибка при открытии URL: $e');
      return false;
    }
  }
  
  // Определение типа ссылки и открытие в соответствующем приложении
  static Future<bool> openSmartUrl(String url, {String? studentName}) async {
    print('🧠 openSmartUrl: $url');
    
    final lowerUrl = url.toLowerCase();
    
    // Telegram
    if (lowerUrl.contains('t.me') || lowerUrl.contains('telegram')) {
      String username = url;
      if (username.contains('t.me/')) {
        username = username.split('t.me/').last;
      } else if (username.contains('telegram.me/')) {
        username = username.split('telegram.me/').last;
      }
      return await openTelegram(username, studentName ?? '');
    }
    
    // WhatsApp
    if (lowerUrl.contains('wa.me') || lowerUrl.contains('whatsapp')) {
      String phone = url;
      if (phone.contains('wa.me/')) {
        phone = phone.split('wa.me/').last;
      }
      return await openWhatsApp(phone, studentName ?? '');
    }
    
    // VK
    if (lowerUrl.contains('vk.com') || lowerUrl.contains('vkontakte')) {
      return await openVK(url, studentName ?? '');
    }
    
    // YouTube
    if (lowerUrl.contains('youtube.com') || lowerUrl.contains('youtu.be')) {
      try {
        final youtubeUrl = Uri.parse(url);
        if (await canLaunchUrl(youtubeUrl)) {
          await launchUrl(youtubeUrl, mode: LaunchMode.externalApplication);
          print('✅ Открыт YouTube');
          return true;
        }
      } catch (e) {
        print('❌ Ошибка при открытии YouTube: $e');
      }
    }
    
    // Обычная ссылка
    return await openUrl(url, studentName: studentName);
  }
  
  // Открыть Telegram
  static Future<bool> openTelegram(String contact, String studentName) async {
    try {
      String username = contact.trim().replaceFirst('@', '');
      username = username.replaceFirst(RegExp(r'^https?://(t\.me/|telegram\.me/)'), '');
      username = username.replaceFirst(RegExp(r'^t\.me/'), '');
      
      print('📱 Открываем Telegram, контакт: $username');
      
      String cleanNumber = username.replaceAll(RegExp(r'[^\d]'), '');
      List<Uri> urlsToTry = [];
      
      if (cleanNumber.isNotEmpty && cleanNumber.length >= 10) {
        print('📱 Распознано как номер телефона: $cleanNumber');
        urlsToTry = [
          Uri.parse('tg://resolve?phone=$cleanNumber'),
          Uri.parse('https://t.me/+$cleanNumber'),
        ];
      } else {
        print('📱 Распознано как username: $username');
        urlsToTry = [
          Uri.parse('tg://resolve?domain=$username'),
          Uri.parse('https://t.me/$username'),
        ];
      }
      
      for (final url in urlsToTry) {
        print('🔗 Пробуем открыть: $url');
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
      
      print('❌ Telegram не установлен или не удалось открыть');
      return false;
    } catch (e) {
      print('❌ Ошибка при открытии Telegram: $e');
      return false;
    }
  }
  
  // Открыть WhatsApp
  static Future<bool> openWhatsApp(String phoneNumber, String studentName) async {
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final numberForWhatsApp = cleanNumber.replaceFirst('+', '');
      print('📱 Открываем WhatsApp, номер: $numberForWhatsApp');
      
      final whatsappUrl = Uri.parse('whatsapp://send?phone=$numberForWhatsApp');
      final canOpenWhatsApp = await canLaunchUrl(whatsappUrl);
      print('📱 Проверка WhatsApp приложения: $canOpenWhatsApp');
      
      if (canOpenWhatsApp) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
        print('✅ Открыто приложение WhatsApp');
        return true;
      } else {
        print('⚠️ WhatsApp приложение не установлено, открываем web версию');
        final webUrl = Uri.parse('https://wa.me/$numberForWhatsApp');
        if (await canLaunchUrl(webUrl)) {
          await launchUrl(webUrl, mode: LaunchMode.externalApplication);
          print('✅ Открыта web версия WhatsApp');
          return true;
        }
      }
      
      print('❌ WhatsApp не установлен или не удалось открыть');
      return false;
    } catch (e) {
      print('❌ Ошибка при открытии WhatsApp: $e');
      return false;
    }
  }
  
  // Открыть VK
  static Future<bool> openVK(String contact, String studentName) async {
    try {
      print('📱 Открываем VK: $contact');
      
      String vkId = contact;
      if (contact.contains('vk.com/')) {
        vkId = contact.split('vk.com/').last;
        vkId = vkId.split('?').first;
        vkId = vkId.split('#').first;
      }
      vkId = vkId.replaceAll('/', '');
      
      print('📱 VK ID: $vkId');
      
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
            print('✅ Открыто приложение VK через $scheme');
            return true;
          }
        } catch (e) {
          print('❌ Не удалось открыть $scheme: $e');
        }
      }
      
      print('⚠️ VK приложение не установлено, открываем web версию');
      final webUrl = Uri.parse('https://vk.com/$vkId');
      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        print('✅ Открыта web версия VK');
        return true;
      }
      
      print('❌ VK не установлен или не удалось открыть');
      return false;
    } catch (e) {
      print('❌ Ошибка при открытии VK: $e');
      return false;
    }
  }
  
  // Позвонить
  static Future<bool> makeCall(String phoneNumber) async {
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final Uri url = Uri(scheme: 'tel', path: cleanNumber);
      print('📞 Звонок на номер: $cleanNumber');
      print('🔗 URL: $url');
      
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
        return true;
      } else {
        print('❌ Не удалось открыть звонок');
        return false;
      }
    } catch (e) {
      print('❌ Ошибка при звонке: $e');
      return false;
    }
  }
  
  // Отправить SMS
  static Future<bool> sendSms(String phoneNumber, [String? message]) async {
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      Uri url;
      if (message != null && message.isNotEmpty) {
        url = Uri(scheme: 'sms', path: cleanNumber, query: 'body=${Uri.encodeComponent(message)}');
      } else {
        url = Uri(scheme: 'sms', path: cleanNumber);
      }
      print('✉️ SMS на номер: $cleanNumber');
      print('🔗 URL: $url');
      
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
  
  // МЕТОДЫ ДЛЯ СОВМЕСТИМОСТИ СО СТАРЫМ КОДОМ (callStudent, messageStudent)
  static void callStudent(String phoneNumber) {
    makeCall(phoneNumber);
  }
  
  static void messageStudent(String phoneNumber) {
    sendSms(phoneNumber);
  }
  
  // Добавить в контакты
  static void addContactToPhone(Student student) {
    print('📇 Добавление в контакты: ${student.fullName} - ${student.phone}');
    // TODO: Реализовать добавление в контакты через Intent
  }
  
  // Связь со студентом через активный контакт
  static Future<void> contactStudentByActiveContact(
    BuildContext context,
    String studentPhone,
    String studentName, {
    Map<String, String>? activeContact,
  }) async {
    print('📞 contactStudentByActiveContact вызван');
    print('   studentPhone: $studentPhone');
    print('   studentName: $studentName');
    print('   activeContact передан: $activeContact');
    
    final contact = activeContact ?? await getActiveContact();
    
    print('   Итоговый контакт: $contact');
    
    if (contact == null) {
      print('⚠️ Активный контакт не найден, показываем диалог выбора');
      _showContactMethodDialog(context, studentPhone, studentName);
      return;
    }
    
    final contactType = contact['type']?.toLowerCase() ?? '';
    final contactValue = contact['value'] ?? '';
    
    print('📱 contactType: $contactType, contactValue: $contactValue');
    
    // Пробуем открыть соответствующий мессенджер
    bool success = false;
    
    switch (contactType) {
      case 'telegram':
        print('📱 Открываем Telegram: $contactValue');
        success = await openTelegram(contactValue, studentName);
        break;
      case 'whatsapp':
        print('📱 Открываем WhatsApp: $contactValue');
        success = await openWhatsApp(contactValue, studentName);
        break;
      case 'vk':
        print('📱 Открываем VK: $contactValue');
        success = await openVK(contactValue, studentName);
        break;
      case 'url':
        print('🌐 Открываем URL: $contactValue');
        success = await openSmartUrl(contactValue, studentName: studentName);
        break;
      case 'sms':
        print('📱 Открываем SMS: $contactValue');
        success = await sendSms(contactValue, studentName);
        break;
      case 'call':
      case 'phone':
        print('📱 Звоним: $contactValue');
        success = await makeCall(contactValue);
        break;
      default:
        print('⚠️ Неизвестный тип контакта: $contactType');
        _showContactMethodDialog(context, studentPhone, studentName);
        return;
    }
    
    if (!success) {
      print('❌ Не удалось открыть приложение, показываем диалог с альтернативами');
      _showContactMethodDialog(context, studentPhone, studentName);
    }
  }
  
  static void _showContactMethodDialog(
    BuildContext context,
    String studentPhone,
    String studentName,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Связаться со студентом',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            studentName,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const Divider(height: 24),
          
          _buildContactOption(
            context,
            icon: Icons.phone,
            title: 'Звонок',
            subtitle: 'Позвонить по номеру $studentPhone',
            color: Colors.green,
            onTap: () {
              Navigator.pop(context);
              makeCall(studentPhone);
            },
          ),
          
          _buildContactOption(
            context,
            icon: Icons.sms,
            title: 'SMS',
            subtitle: 'Отправить сообщение',
            color: Colors.blue,
            onTap: () {
              Navigator.pop(context);
              sendSms(studentPhone);
            },
          ),
          
          _buildContactOption(
            context,
            icon: Icons.telegram,
            title: 'Telegram',
            subtitle: 'Открыть Telegram',
            color: Colors.lightBlue,
            onTap: () {
              Navigator.pop(context);
              openTelegram(studentPhone, studentName);
            },
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  static Widget _buildContactOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}