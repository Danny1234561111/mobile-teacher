import 'package:url_launcher/url_launcher.dart';
import '../models/student.dart';

class ContactService {
  static Future<void> addContactToPhone(Student student) async {
    try {
      String intentUri = '''
        intent:
        #Intent;
        action=android.intent.action.INSERT;
        type=vnd.android.cursor.dir/contact;
        S.name=${Uri.encodeComponent(student.fullName)};
        S.phone=${Uri.encodeComponent(student.phone)};
        end
      ''';
      
      intentUri = intentUri.replaceAll('\n', '').replaceAll('  ', ' ').trim();
      
      final url = Uri.parse(intentUri);
      
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        final contactsUrl = Uri.parse('content://com.android.contacts/contacts');
        if (await canLaunchUrl(contactsUrl)) {
          await launchUrl(
            contactsUrl,
            mode: LaunchMode.externalApplication,
          );
        } else {
          throw Exception('Не удалось открыть приложение контактов');
        }
      }
    } catch (e) {
      print('Ошибка открытия формы контактов: $e');
      rethrow;
    }
  }

  static Future<void> callStudent(String phone) async {
    try {
      final url = Uri.parse('tel:$phone');
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Не удалось совершить звонок');
      }
    } catch (e) {
      print('Ошибка звонка: $e');
      rethrow;
    }
  }

  static Future<void> messageStudent(String phone, {String? body}) async {
    try {
      String smsUrl = 'sms:$phone';
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
        throw Exception('Не удалось открыть сообщения');
      }
    } catch (e) {
      print('Ошибка сообщения: $e');
      rethrow;
    }
  }
}