import 'package:url_launcher/url_launcher.dart';

class UrlLauncherService {
  /// Совершает телефонный звонок
  static Future<void> launchPhoneCall(String phoneNumber) async {
    try {
      final url = Uri.parse('tel:$phoneNumber');
      
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Не удалось совершить звонок. Убедитесь, что устройство поддерживает телефонные вызовы.');
      }
    } catch (e) {
      throw Exception('Ошибка при попытке звонка: $e');
    }
  }

  /// Открывает приложение для отправки SMS
  static Future<void> launchSMS(String phoneNumber, {String? body}) async {
    try {
      String smsUrl = 'sms:$phoneNumber';
      if (body != null && body.isNotEmpty) {
        smsUrl += '?body=${Uri.encodeComponent(body)}';
      }
      
      final url = Uri.parse(smsUrl);
      
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Не удалось открыть сообщения. Убедитесь, что на устройстве установлено приложение для отправки SMS.');
      }
    } catch (e) {
      throw Exception('Ошибка при попытке отправки SMS: $e');
    }
  }

  /// Открывает почтовый клиент
  static Future<void> launchEmail(String email, {
    String? subject,
    String? body,
  }) async {
    try {
      String mailtoUrl = 'mailto:$email';
      
      final params = <String>[];
      if (subject != null && subject.isNotEmpty) {
        params.add('subject=${Uri.encodeComponent(subject)}');
      }
      if (body != null && body.isNotEmpty) {
        params.add('body=${Uri.encodeComponent(body)}');
      }
      
      if (params.isNotEmpty) {
        mailtoUrl += '?${params.join('&')}';
      }
      
      final url = Uri.parse(mailtoUrl);
      
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Не удалось открыть почтовый клиент. Убедитесь, что на устройстве установлено почтовое приложение.');
      }
    } catch (e) {
      throw Exception('Ошибка при попытке отправки email: $e');
    }
  }

  /// Открывает URL в браузере
  static Future<void> launchURL(String urlString) async {
    try {
      Uri url;
      
      // Проверяем, начинается ли URL с протокола
      if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
        url = Uri.parse('https://$urlString');
      } else {
        url = Uri.parse(urlString);
      }
      
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
          // Можно использовать другие режимы:
          // mode: LaunchMode.inAppWebView, // открыть в WebView внутри приложения
          // webViewConfiguration: const WebViewConfiguration(enableJavaScript: true),
        );
      } else {
        throw Exception('Не удалось открыть URL: $urlString');
      }
    } catch (e) {
      throw Exception('Ошибка при открытии URL: $e');
    }
  }

  /// Открывает карты с указанным адресом
  static Future<void> launchMaps(String address) async {
    try {
      final encodedAddress = Uri.encodeComponent(address);
      final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');
      
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Не удалось открыть карты');
      }
    } catch (e) {
      throw Exception('Ошибка при открытии карт: $e');
    }
  }

  /// Открывает WhatsApp с указанным номером
  static Future<void> launchWhatsApp(String phoneNumber, {String? message}) async {
    try {
      // Убираем все нецифровые символы из номера
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
      
      String whatsappUrl = 'https://wa.me/$cleanNumber';
      if (message != null && message.isNotEmpty) {
        whatsappUrl += '?text=${Uri.encodeComponent(message)}';
      }
      
      final url = Uri.parse(whatsappUrl);
      
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Если WhatsApp не установлен, открываем в браузере
        final webUrl = Uri.parse('https://web.whatsapp.com/send?phone=$cleanNumber${message != null ? '&text=${Uri.encodeComponent(message)}' : ''}');
        if (await canLaunchUrl(webUrl)) {
          await launchUrl(
            webUrl,
            mode: LaunchMode.externalApplication,
          );
        } else {
          throw Exception('Не удалось открыть WhatsApp. Убедитесь, что приложение установлено.');
        }
      }
    } catch (e) {
      throw Exception('Ошибка при открытии WhatsApp: $e');
    }
  }
}g