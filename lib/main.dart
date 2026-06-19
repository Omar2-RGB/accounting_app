import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite/sqflite.dart' show databaseFactory;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show databaseFactoryFfi;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart' show databaseFactoryFfiWeb;
import 'dart:io' show Platform; // لتمييز منصات سطح المكتب
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';

void main() {
  // ✅ تهيئة databaseFactory حسب المنصة
  if (kIsWeb) {
    // للويب (Chrome, Edge, Safari)
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    // لسطح المكتب (Windows, macOS, Linux)
    databaseFactory = databaseFactoryFfi;
  }
  // ✅ للهواتف (Android, iOS) لا نقوم بتعيين databaseFactory،
  //    يبقى بالقيمة الافتراضية ويعمل تلقائياً.

  runApp(const AccountingApp());
}

class AccountingApp extends StatelessWidget {
  const AccountingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق المحاسبة',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,

      // إعدادات اللغة
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar')],
      locale: const Locale('ar'),

      home: const LoginScreen(),
    );
  }
}