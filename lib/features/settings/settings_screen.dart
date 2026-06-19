import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import '../../core/theme/app_colors.dart';
import '../../services/backup_service.dart';
import '../../services/google_drive_service.dart';
import '../auth/login_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  bool _isSyncing = false;
  List<File> _backupFiles = [];

  @override
  void initState() {
    super.initState();
    _loadBackupFiles();
  }

  Future<void> _loadBackupFiles() async {
    try {
      final files = await BackupService.getBackupFiles();
      if (mounted) {
        setState(() => _backupFiles = files);
      }
    } catch (e) {
      // تجاهل ا��أخطاء
    }
  }

  Future<void> _createBackup() async {
    setState(() => _isLoading = true);
    try {
      final filePath = await BackupService.exportDatabase();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ النسخة الاحتياطية في: $filePath'),
            backgroundColor: AppColors.success,
          ),
        );
        await _loadBackupFiles();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null) return;

      final filePath = result.files.single.path!;
      setState(() => _isLoading = true);

      final message = await BackupService.importDatabase(filePath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: AppColors.success),
        );
        await _loadBackupFiles();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الاستعادة: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBackup(File file) async {
    try {
      await file.delete();
      await _loadBackupFiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف النسخة الاحتياطية'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  // ===== دوال المزامنة مع Google Drive =====
  Future<void> _uploadToDrive() async {
    setState(() => _isSyncing = true);
    try {
      final backupPath = await BackupService.exportDatabase();
      final fileId = await GoogleDriveService.uploadBackup(backupPath);

      if (mounted) {
        if (fileId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ تم رفع النسخة الاحتياطية إلى جوجل درايف بنجاح'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ فشل رفع الملف، تأكد من تسجيل الدخول'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _restoreFromDrive() async {
    setState(() => _isSyncing = true);
    try {
      final files = await GoogleDriveService.listBackups();

      if (files.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا توجد نسخ احتياطية على جوجل درايف')),
          );
        }
        setState(() => _isSyncing = false);
        return;
      }

      final selectedFile = await showDialog<drive.File>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('اختر نسخة احتياطية'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                final file = files[index];
                final name = file.name ?? 'بدون اسم';
                final modified = file.modifiedTime?.toLocal().toString() ?? 'تاريخ غير معروف';
                return ListTile(
                  title: Text(name),
                  subtitle: Text(modified),
                  onTap: () => Navigator.pop(context, file),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('إلغاء'),
            ),
          ],
        ),
      );

      if (selectedFile == null || selectedFile.id == null) {
        setState(() => _isSyncing = false);
        return;
      }

      final downloadedPath = await GoogleDriveService.downloadBackup(selectedFile.id!);
      if (downloadedPath != null && mounted) {
        await BackupService.importDatabase(downloadedPath);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم استعادة البيانات من جوجل درايف بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
        await _loadBackupFiles();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ فشل تحميل الملف'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: (_isLoading || _isSyncing)
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // ===== قسم النسخ الاحتياطي المحلي =====
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderWhite),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'النسخ الاحتياطي المحلي',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildMenuItem(
                        icon: Icons.save_alt,
                        title: 'حفظ نسخة احتياطية',
                        subtitle: 'تصدير جميع البيانات إلى ملف JSON',
                        color: AppColors.primary,
                        onTap: _createBackup,
                      ),
                      const Divider(),
                      _buildMenuItem(
                        icon: Icons.restore,
                        title: 'استرجاع قاعدة البيانات',
                        subtitle: 'استعادة البيانات من ملف JSON',
                        color: Colors.orange,
                        onTap: _restoreBackup,
                      ),
                      if (_backupFiles.isNotEmpty) ...[
                        const Divider(),
                        const Text(
                          'النسخ الاحتياطية السابقة',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ..._backupFiles.map((file) {
                          final fileName = file.path.split('/').last;
                          return ListTile(
                            leading: const Icon(Icons.file_copy, color: Colors.blue),
                            title: Text(fileName),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.danger),
                              onPressed: () => _deleteBackup(file),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),

                // ===== قسم المزامنة مع Google Drive (جديد) =====
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderWhite),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'المزامنة السحابية (Google Drive)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildMenuItem(
                        icon: Icons.cloud_upload,
                        title: 'رفع إلى جوجل درايف',
                        subtitle: 'حفظ نسخة احتياطية في السحاب',
                        color: Colors.green,
                        onTap: _uploadToDrive,
                      ),
                      const Divider(),
                      _buildMenuItem(
                        icon: Icons.cloud_download,
                        title: 'استعادة من جوجل درايف',
                        subtitle: 'استرجاع البيانات من السحاب',
                        color: Colors.blue,
                        onTap: _restoreFromDrive,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ===== قسم التواصل والمعلومات =====
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderWhite),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'معلومات',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildMenuItem(
                        icon: Icons.support_agent,
                        title: 'للتواصل والدعم',
                        subtitle: 'للإستفسارات والدعم الفني',
                        color: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AboutScreen()),
                          );
                        },
                      ),
                      const Divider(),
                      _buildMenuItem(
                        icon: Icons.info_outline,
                        title: 'حول البرنامج',
                        subtitle: 'تطبيق محاسبة إصدار 1.0.0',
                        color: Colors.grey,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AboutScreen()),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ===== زر الخروج =====
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(
                      'خروج',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildMenuItem({
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
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
