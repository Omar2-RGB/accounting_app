import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/theme/app_colors.dart';
import '../../data/local_database/database_helper.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _type = 'client'; // client أو supplier

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;

    // تجهيز بيانات الجهة
    final Map<String, dynamic> contactData = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'type': _type,
      'createdAt': DateTime.now().toIso8601String(),
    };

    try {
      // استخدام دالة addContact من DatabaseHelper
      final dbHelper = DatabaseHelper.instance;
      final id = await dbHelper.addContact(contactData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حفظ الجهة بنجاح (الرقم: $id)'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء الحفظ: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة جهة تعامل')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الجهة',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: const InputDecoration(
                  labelText: 'النوع',
                  prefixIcon: Icon(Icons.category),
                ),
                items: const [
                  DropdownMenuItem(value: 'client', child: Text('عميل')),
                  DropdownMenuItem(value: 'supplier', child: Text('مورد')),
                ],
                onChanged: (val) => setState(() => _type = val!),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveContact,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('حفظ الجهة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}