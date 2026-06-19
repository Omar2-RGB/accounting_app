import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../services/backup_service.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
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
      // تجاهل الأخطاء
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // قسم النسخ الاحتياطي
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
                        'النسخ الاحتياطي',
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

                // قسم جوجل درايف
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
                        'المزامنة',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildMenuItem(
                        icon: Icons.cloud_upload,
                        title: 'جوجل درايف',
                        subtitle: 'مزامنة النسخ الاحتياطية مع جوجل درايف',
                        color: Colors.green,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('سيتم إضافة مزامنة جوجل درايف قريباً')),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // قسم التواصل
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
                          // TODO: فتح رابط التواصل
                        },
                      ),
                      const Divider(),
                      _buildMenuItem(
                        icon: Icons.info_outline,
                        title: 'حول البرنامج',
                        subtitle: 'تطبيق محاسبة إصدار 1.0.0',
                        color: Colors.grey,
                        onTap: () {
                          showAboutDialog(
                            context: context,
                            applicationName: 'تطبيق المحاسبة',
                            applicationVersion: '1.0.0',
                            applicationLegalese: '© 2024 جميع الحقوق محفوظة',
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // زر الخروج
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