import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/local_database/database_helper.dart';

class AddCurrencyScreen extends StatefulWidget {
  const AddCurrencyScreen({super.key});

  @override
  State<AddCurrencyScreen> createState() => _AddCurrencyScreenState();
}

class _AddCurrencyScreenState extends State<AddCurrencyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _symbolController = TextEditingController();
  final _rateController = TextEditingController();
  bool _isDefault = false;
  bool _isLoading = false;

  Future<void> _saveCurrency() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dbHelper = DatabaseHelper.instance;

      if (_isDefault) {
        final all = await dbHelper.getAllCurrencies();
        for (var c in all) {
          if (c['is_default'] == 1) {
            final updated = Map<String, dynamic>.from(c);
            updated['is_default'] = 0;
            await dbHelper.updateCurrency(updated);
          }
        }
      }

      final data = {
        'code': _codeController.text.trim().toUpperCase(),
        'name': _nameController.text.trim(),
        'symbol': _symbolController.text.trim(),
        'exchange_rate': double.parse(_rateController.text.trim()),
        'is_default': _isDefault ? 1 : 0,
        'created_at': DateTime.now().toIso8601String(),
      };

      await dbHelper.addCurrency(data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إضافة العملة بنجاح 🎉')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _symbolController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة عملة جديدة'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'رمز العملة (مثل USD)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'مطلوب';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم العملة (مثل دولار أمريكي)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'مطلوب';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _symbolController,
                decoration: const InputDecoration(
                  labelText: 'رمز العرض (مثل ل.س )',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'مطلوب';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rateController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'سعر الصرف مقابل العملة الأساسية',
                  hintText: 'مثال: 0.71',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'مطلوب';
                  if (double.tryParse(v) == null) return 'أدخل رقماً صحيحاً';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Checkbox(
                    value: _isDefault,
                    onChanged: (val) => setState(() => _isDefault = val ?? false),
                  ),
                  const Text('تعيين كعملة أساسية'),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveCurrency,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('حفظ العملة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}