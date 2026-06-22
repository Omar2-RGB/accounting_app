import 'dart:io' as dart_io; // ✅ اكتفينا بالاسم المستعار فقط ومنعنا التعارض من الجذور
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class GoogleDriveService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  static Future<drive.DriveApi?> _getDriveApi() async {
    try {
      // 1. التحقق من المستخدم
      GoogleSignInAccount? account = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
      account ??= await _googleSignIn.signIn();
      if (account == null) return null;

      // 2. الطريقة الصحيحة في إصدار 7.x للوصول للـ Authentication
      final auth = await account.authentication;
      final token = auth.accessToken;
      
      if (token == null) return null;

      // 3. إنشاء العميل يدوياً
      final client = _AuthenticatedClient({'Authorization': 'Bearer $token'});
      return drive.DriveApi(client);
    } catch (e) {
      debugPrint('❌ خطأ في الاتصال: $e');
      return null;
    }
  }

  static Future<String?> uploadBackup(String filePath, {String fileName = 'accounting_backup.json'}) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return null;

      // ✅ استخدام dart_io.File الصريح
      final dart_io.File file = dart_io.File(filePath);
      if (!await file.exists()) {
        debugPrint('❌ الملف غير موجود: $filePath');
        return null;
      }

      final existingFiles = await driveApi.files.list(
        q: "name = '$fileName' and trashed = false",
        spaces: 'drive',
      );
      if (existingFiles.files != null) {
        for (var f in existingFiles.files!) {
          if (f.id != null) await driveApi.files.delete(f.id!);
        }
      }

      final media = drive.Media(file.openRead(), file.lengthSync());
      final driveFile = drive.File()
        ..name = fileName
        ..mimeType = 'application/json';

      final result = await driveApi.files.create(driveFile, uploadMedia: media);
      debugPrint('✅ تم رفع الملف بنجاح: ${result.id}');
      return result.id;
    } catch (e) {
      debugPrint('❌ خطأ في رفع الملف: $e');
      return null;
    }
  }

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
      debugPrint('❌ خطأ في جلب القائمة: $e');
      return [];
    }
  }

  // ✅ النسخة المصححة والمحصنة من downloadBackup
  static Future<String?> downloadBackup(String fileId) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return null;

      final drive.File fileInfo = await driveApi.files.get(fileId) as drive.File;
      final String fileName = fileInfo.name ?? 'backup_restored.json';

      // ✅ استخدام dart_io.Directory الصريح
      final dart_io.Directory directory = await getApplicationDocumentsDirectory();
      final String savePath = '${directory.path}/$fileName';

      final response = await driveApi.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      );

      final List<int> bytes;
      if (response is List<int>) {
        bytes = response;
      } else if (response is drive.Media) {
        bytes = await response.stream.expand((e) => e).toList();
      } else {
        throw Exception('نوع الاستجابة غير معروف: ${response.runtimeType}');
      }

      // ✅ استخدام dart_io.File الصريح
      final dart_io.File file = dart_io.File(savePath);
      await file.writeAsBytes(bytes);

      debugPrint('✅ تم تحميل الملف إلى: $savePath');
      return savePath;
    } catch (e) {
      debugPrint('❌ خطأ في تحميل الملف: $e');
      return null;
    }
  }

  static Future<bool> deleteBackup(String fileId) async {
    try {
      final driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      await driveApi.files.delete(fileId);
      debugPrint('✅ تم حذف الملف بنجاح');
      return true;
    } catch (e) {
      debugPrint('❌ خطأ في حذف الملف: $e');
      return false;
    }
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    debugPrint('✅ تم تسجيل الخروج من Google');
  }
}

// عميل HTTP موثق
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