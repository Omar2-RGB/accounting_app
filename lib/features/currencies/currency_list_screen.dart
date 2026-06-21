import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/local_database/database_helper.dart';
import 'add_currency_screen.dart';

class CurrencyListScreen extends StatefulWidget {
  const CurrencyListScreen({super.key});

  @override
  State<CurrencyListScreen> createState() => _CurrencyListScreenState();
}

class _CurrencyListScreenState extends State<CurrencyListScreen> {
  List<Map<String, dynamic>> _currencies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final currencies = await dbHelper.getAllCurrencies();

      // ✅ التحقق من mounted قبل setState
      if (mounted) {
        setState(() {
          _currencies = currencies;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  Future<void> _setDefaultCurrency(int id) async {
    try {
      final dbHelper = DatabaseHelper.instance;

      // 1. جلب جميع العملات
      final all = await dbHelper.getAllCurrencies();

      // 2. إزالة الافتراضي من جميع العملات
      for (var c in all) {
        if (c['is_default'] == 1) {
          // ✅ تمرير جميع الحقول مع تغيير is_default فقط
          final updated = Map<String, dynamic>.from(c);
          updated['is_default'] = 0;
          await dbHelper.updateCurrency(updated);
        }
      }

      // 3. تعيين العملة الجديدة كافتراضية
      final currency = await dbHelper.getCurrencyById(id);
      if (currency != null) {
        final updated = Map<String, dynamic>.from(currency);
        updated['is_default'] = 1;
        await dbHelper.updateCurrency(updated);
      }

      // 4. إعادة تحميل القائمة
      await _loadCurrencies();

      // ✅ التحقق من mounted قبل عرض الـ SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تعيين العملة الأساسية')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة العملات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCurrencies,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currencies.isEmpty
              ? const Center(child: Text('لا توجد عملات'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _currencies.length,
                  itemBuilder: (context, index) {
                    final currency = _currencies[index];
                    final id = currency['id'] as int;
                    final code = currency['code'] ?? '';
                    final name = currency['name'] ?? '';
                    final symbol = currency['symbol'] ?? '';
                    final rate = currency['exchange_rate'] as double? ?? 0.0;
                    final isDefault = currency['is_default'] == 1;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isDefault
                              ? AppColors.primary
                              : Colors.grey.shade300,
                          child: Text(
                            symbol,
                            style: TextStyle(
                              color: isDefault ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        title: Text(
                          '$code - $name',
                          style: TextStyle(
                            fontWeight: isDefault ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text('السعر: $rate مقابل العملة الأساسية'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isDefault)
                              const Chip(
                                label: Text('أساسي'),
                                backgroundColor: AppColors.primary,
                                labelStyle: TextStyle(color: Colors.white),
                              ),
                            if (!isDefault)
                              IconButton(
                                icon: const Icon(Icons.star_border),
                                onPressed: () => _setDefaultCurrency(id),
                                tooltip: 'تعيين كعملة أساسية',
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                // TODO: فتح شاشة تعديل العملة
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('سيتم إضافة تعديل العملات قريباً')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCurrencyScreen()),
          ).then((_) {
            _loadCurrencies();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}