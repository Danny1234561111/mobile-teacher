import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Проверка и запрос разрешений
  static Future<bool> checkAndRequestPermissions() async {
    List<Permission> permissions = [
      Permission.phone,
      Permission.sms,
      Permission.contacts,
    ];
    
    // Для Android 10+ нужно специальное разрешение
    if (Platform.isAndroid) {
      permissions.add(Permission.systemAlertWindow);
    }
    
    Map<Permission, PermissionStatus> statuses = await permissions.request();
    
    bool allGranted = statuses.values.every((status) => status.isGranted);
    
    if (!allGranted) {
      // Если какие-то разрешения не даны, запрашиваем снова
      Map<Permission, PermissionStatus> secondTry = await permissions.request();
      allGranted = secondTry.values.every((status) => status.isGranted);
    }
    
    return allGranted;
  }
  
  // Проверка конкретного разрешения
  static Future<bool> hasPhonePermission() async {
    return await Permission.phone.isGranted;
  }
  
  static Future<bool> hasSmsPermission() async {
    return await Permission.sms.isGranted;
  }
  
  static Future<bool> hasOverlayPermission() async {
    if (Platform.isAndroid) {
      return await Permission.systemAlertWindow.isGranted;
    }
    return true;
  }
  
  // Открыть настройки приложения
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
  
  // Показать диалог с объяснением необходимости разрешений
  static void showPermissionDialog(BuildContext context, VoidCallback onRetry) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Необходимы разрешения'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Для полной работы приложения необходимы следующие разрешения:'),
            SizedBox(height: 10),
            Text('• 📞 Телефон - для совершения звонков'),
            Text('• ✉️ SMS - для отправки сообщений'),
            Text('• 📇 Контакты - для доступа к контактам'),
            Text('• 🔝 Поверх других приложений - для работы в фоновом режиме'),
            SizedBox(height: 10),
            Text('Пожалуйста, дайте все разрешения в настройках.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              SystemNavigator.pop();
            },
            child: const Text('Выйти'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
              onRetry();
            },
            child: const Text('Открыть настройки'),
          ),
        ],
      ),
    );
  }
}