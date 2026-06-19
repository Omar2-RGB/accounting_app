import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../data/local_database/database_helper.dart';

class BackupService {
  static Future<String> exportDatabase() async {
    final db = await DatabaseHelper.instance.database;
    
    // جلب جميع البيانات من الجداول
    final users = await db.query('users');
    final contacts = await db.query('contacts');
    final currencies = await db.query('currencies');
    final invoices = await db.query('invoices');
    final invoiceItems = await db.query('invoice_items');
    final payments = await db.query('payments');

    final backupData = {
      'version': 1,
      'exportDate': DateTime.now().toIso8601String(),
      'users': users,
      'contacts': contacts,
      'currencies': currencies,
      'invoices': invoices,
      'invoiceItems': invoiceItems,
      'payments': payments,
    };

    final jsonString = jsonEncode(backupData);
    
    // حفظ الملف
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/backup_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File(filePath);
    await file.writeAsString(jsonString);
    
    return filePath;
  }

  static Future<String> importDatabase(String filePath) async {
    final file = File(filePath);
    final jsonString = await file.readAsString();
    final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

    final db = await DatabaseHelper.instance.database;

    // بدء المعاملة
    await db.transaction((txn) async {
      // حذف البيانات القديمة
      await txn.delete('payments');
      await txn.delete('invoice_items');
      await txn.delete('invoices');
      await txn.delete('currencies');
      await txn.delete('contacts');
      await txn.delete('users');

      // إدراج البيانات الجديدة
      for (var user in backupData['users'] as List) {
        await txn.insert('users', user);
      }
      for (var contact in backupData['contacts'] as List) {
        await txn.insert('contacts', contact);
      }
      for (var currency in backupData['currencies'] as List) {
        await txn.insert('currencies', currency);
      }
      for (var invoice in backupData['invoices'] as List) {
        await txn.insert('invoices', invoice);
      }
      for (var item in backupData['invoiceItems'] as List) {
        await txn.insert('invoice_items', item);
      }
      for (var payment in backupData['payments'] as List) {
        await txn.insert('payments', payment);
      }
    });

    return 'تم استعادة البيانات بنجاح ✅';
  }

  static Future<List<File>> getBackupFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync();
    final backupFiles = <File>[];
    for (var file in files) {
      if (file is File && file.path.endsWith('.json')) {
        backupFiles.add(file);
      }
    }
    return backupFiles;
  }
}