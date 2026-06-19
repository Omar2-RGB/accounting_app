import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class GoogleDriveService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  // عميل HTTP موثق بإضافة رأس Authorization من Google
  static Future<drive.DriveApi?> _getDriveApi() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return null;
      final headers = await account.authHeaders;
      final client = _AuthenticatedClient(headers);
      return drive.DriveApi(client);
    } catch (e) {
      debugPrint('خطأ في تسجيل الدخول إلى Google: $e');
      return null;
    }
  }

  // رفع ملف نسخ احتياطي إلى Google Drive
  static Future<String?> uploadBackup(String filePath, {String fileName = 'accounting_backup.json'}) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return null;

      final File file = File(filePath);
      if (!await file.exists()) {
        throw Exception('الملف غير موجود');
      }

      // البحث عن ملف قديم بنفس الاسم وحذفه (تجنب التكرار)
      final existingFiles = await driveApi.files.list(
        q: "name = '$fileName' and trashed = false",
        spaces: 'drive',
      );
      if (existingFiles.files != null && existingFiles.files!.isNotEmpty) {
        for (var f in existingFiles.files!) {
          await driveApi.files.delete(f.id!);
        }
      }

      // رفع الملف الجديد
      final media = drive.Media(file.openRead(), file.lengthSync());
      final driveFile = drive.File()
        ..name = fileName
        ..mimeType = 'application/json';

      final result = await driveApi.files.create(
        driveFile,
        uploadMedia: media,
      );

      debugPrint('تم رفع الملف بنجاح: ${result.id}');
      return result.id;
    } catch (e) {
      debugPrint('خطأ في رفع الملف: $e');
      return null;
    }
  }

  // جلب قائمة النسخ الاحتياطية من Google Drive
  static Future<List<drive.File>> listBackups() async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return [];

      final result = await driveApi.files.list(
        q: "mimeType = 'application/json' and trashed = false",
        spaces: 'drive',
        orderBy: 'createdTime desc',
      );
      return result.files ?? [];
    } catch (e) {
      debugPrint('خطأ في جلب القائمة: $e');
      return [];
    }
  }

  // تحميل ملف من Google Drive
  static Future<String?> downloadBackup(String fileId) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return null;

      // ✅ تحويل صريح إلى drive.File لحل تعارض الأنواع
      final fileInfo = await driveApi.files.get(fileId) as drive.File;
      final String fileName = fileInfo.name ?? 'backup_restored.json';

      // تحديد مسار الحفظ المؤقت
      final Directory directory = await getApplicationDocumentsDirectory();
      final String savePath = '${directory.path}/restored_$fileName';

      // تحميل الملف كـ bytes
      final response = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );

      // response هو List<int> مباشرةً
      final File file = File(savePath);
      await file.writeAsBytes(response as List<int>);

      debugPrint('تم تحميل الملف إلى: $savePath');
      return savePath;
    } catch (e) {
      debugPrint('خطأ في تحميل الملف: $e');
      return null;
    }
  }

  // حذف ملف من Google Drive
  static Future<bool> deleteBackup(String fileId) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      await driveApi.files.delete(fileId);
      return true;
    } catch (e) {
      debugPrint('خطأ في حذف الملف: $e');
      return false;
    }
  }

  // تسجيل الخروج
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}

// عميل HTTP مخصص يضيف رأس Authorization من Google
class _AuthenticatedClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  _AuthenticatedClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}