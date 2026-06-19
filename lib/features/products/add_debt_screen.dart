import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/local_database/database_helper.dart';

class AddDebtScreen extends StatefulWidget {
  const AddDebtScreen({super.key});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _currencies = [];

  int? _selectedContactId;
  int? _selectedCurrencyId;
  DateTime _selectedDate = DateTime.now();
  String _debtType = 'credit'; // 'credit' (له) أو 'debit' (عليه)
  String _currencySymbol = 'د.أ';
  double _currencyRate = 1.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final contacts = await dbHelper.getAllContacts();
      final currencies = await dbHelper.getAllCurrencies();

      setState(() {
        _contacts = contacts;
        _currencies = currencies;

        if (currencies.isNotEmpty) {
          final defaultCurr = currencies.firstWhere(
            (c) => c['is_default'] == 1,
            orElse: () => currencies.first,
          );
          _selectedCurrencyId = defaultCurr['id'];
          _currencySymbol = defaultCurr['symbol'] ?? 'د.أ';
          _currencyRate = defaultCurr['exchange_rate'] as double? ?? 1.0;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في التحميل: $e')),
      );
    }
  }

  Future<void> _saveDebt() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedContactId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر جهة اتصال')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dbHelper = DatabaseHelper.instance;
      final amount = double.parse(_amountController.text.trim());

      // إنشاء فاتورة مباشرة (سريعة) لتسجيل الدين
      final invoiceNumber = 'DEBT-${DateTime.now().millisecondsSinceEpoch}';
      final invoiceType = _debtType == 'credit' ? 'sale' : 'purchase';

      await dbHelper.addInvoice({
        'invoice_number': invoiceNumber,
        'contact_id': _selectedContactId,
        'type': invoiceType,
        'date': _selectedDate.toIso8601String(),
        'total': amount,
        'tax': 0,
        'grand_total': amount,
        'currency_id': _selectedCurrencyId,
        'currency_rate': _currencyRate,
        'status': 'unpaid',
        'note': _noteController.text.trim() + ' (دين مسجل يدوياً)',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تسجيل الدين بنجاح 🎉'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.danger),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل دين جديد'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // اختيار نوع الدين
                    Row(
                      children: [
                        Expanded(
                          child: _buildTypeButton('له (عميل)', Icons.arrow_upward, 'credit'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTypeButton('عليه (مورد)', Icons.arrow_downward, 'debit'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // جهة الاتصال
                    DropdownButtonFormField<int>(
                      value: _selectedContactId,
                      decoration: const InputDecoration(
                        labelText: 'جهة الاتصال',
                        border: OutlineInputBorder(),
                      ),
                      items: _contacts.map((contact) {
                        return DropdownMenuItem<int>(
                          value: contact['id'],
                          child: Text(contact['name']),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedContactId = val),
                      validator: (val) => val == null ? 'اختر جهة' : null,
                    ),
                    const SizedBox(height: 16),

                    // العملة
                    DropdownButtonFormField<int>(
                      value: _selectedCurrencyId,
                      decoration: const InputDecoration(
                        labelText: 'العملة',
                        border: OutlineInputBorder(),
                      ),
                      items: _currencies.map((currency) {
                        return DropdownMenuItem<int>(
                          value: currency['id'],
                          child: Text('${currency['code']} - ${currency['symbol']}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCurrencyId = val;
                          final selected = _currencies.firstWhere((c) => c['id'] == val);
                          _currencySymbol = selected['symbol'] ?? 'د.أ';
                          _currencyRate = selected['exchange_rate'] as double? ?? 1.0;
                        });
                      },
                      validator: (val) => val == null ? 'اختر العملة' : null,
                    ),
                    const SizedBox(height: 16),

                    // المبلغ
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'المبلغ',
                        border: const OutlineInputBorder(),
                        suffixText: _currencySymbol,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'مطلوب';
                        if (double.tryParse(v) == null) return 'أدخل رقماً صحيحاً';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // التاريخ
                    ListTile(
                      title: const Text('التاريخ'),
                      subtitle: Text(DateFormat('dd-MM-yyyy').format(_selectedDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setState(() => _selectedDate = date);
                      },
                    ),
                    const SizedBox(height: 16),

                    // ملاحظات
                    TextFormField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // زر الحفظ
                    ElevatedButton(
                      onPressed: _saveDebt,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('تسجيل الدين'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTypeButton(String label, IconData icon, String type) {
    final isSelected = _debtType == type;
    return GestureDetector(
      onTap: () => setState(() => _debtType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}