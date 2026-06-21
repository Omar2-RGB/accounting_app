import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/local_database/database_helper.dart';
import '../reports/account_statement_screen.dart'; // ✅ مسار صحيح

class ContactsListScreen extends StatefulWidget {
  const ContactsListScreen({super.key});

  @override
  State<ContactsListScreen> createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends State<ContactsListScreen> {
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    // ✅ التحقق من mounted قبل setState
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final dbHelper = DatabaseHelper.instance;
      final data = await dbHelper.getAllContacts();

      // ✅ التحقق من mounted بعد await
      if (mounted) {
        setState(() {
          _contacts = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'حدث خطأ أثناء تحميل البيانات: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteContact(int id) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.deleteContact(id);

      // ✅ التحقق من mounted قبل setState
      if (mounted) {
        setState(() {
          _contacts.removeWhere((contact) => contact['id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف الجهة بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الحذف: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جهات التعامل'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadContacts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: AppColors.danger),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.danger),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadContacts,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : _contacts.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 60, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('لا توجد جهات مضافة بعد'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _contacts.length,
                      itemBuilder: (context, index) {
                        final contact = _contacts[index];
                        final id = contact['id'] as int?;
                        final name = contact['name'] ?? 'بدون اسم';
                        final type = contact['type'] ?? 'client';
                        final phone = contact['phone'] ?? 'لا يوجد رقم';

                        return Card(
                          color: AppColors.cardColor,
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: Icon(
                              type == 'client' ? Icons.person : Icons.factory,
                              color: type == 'client' ? AppColors.primary : AppColors.accent,
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(phone),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) {
                                if (value == 'delete' && id != null) {
                                  _deleteContact(id);
                                } else if (value == 'edit') {
                                  // TODO: فتح شاشة تعديل الجهة
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('سيتم إضافة تعديل قريباً')),
                                  );
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit),
                                      SizedBox(width: 8),
                                      Text('تعديل'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: AppColors.danger),
                                      SizedBox(width: 8),
                                      Text('حذف', style: TextStyle(color: AppColors.danger)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            onTap: () {
                              // ✅ الانتقال إلى كشف الحساب مع تمرير البيانات
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AccountStatementScreen(
                                    contactId: contact['id'],
                                    contactName: contact['name'],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}