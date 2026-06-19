import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/local_database/database_helper.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  // متغيرات أساسية
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _contacts = [];
  int? _selectedContactId;
  String _invoiceType = 'sale'; // 'sale' أو 'purchase'
  final List<Map<String, dynamic>> _items = [];
  double _taxRate = 16.0; // نسبة الضريبة المئوية

  // ===== متغيرات العملات =====
  List<Map<String, dynamic>> _currencies = [];
  int? _selectedCurrencyId;
  double _currencyRate = 1.0;
  String _currencySymbol = 'د.أ';

  // متحكمات الحقول
  final TextEditingController _itemDescController = TextEditingController();
  final TextEditingController _itemQtyController = TextEditingController();
  final TextEditingController _itemPriceController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _loadCurrencies();
  }

  // تحميل قائمة الجهات من قاعدة البيانات
  Future<void> _loadContacts() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final contacts = await dbHelper.getAllContacts();
      setState(() => _contacts = contacts);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل الجهات: $e')),
      );
    }
  }

  // ===== تحميل العملات من قاعدة البيانات =====
  Future<void> _loadCurrencies() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final currencies = await dbHelper.getAllCurrencies();
      setState(() {
        _currencies = currencies;
        // اختيار العملة الافتراضية
        if (currencies.isNotEmpty) {
          final defaultCurr = currencies.firstWhere(
            (c) => c['is_default'] == 1,
            orElse: () => currencies.first,
          );
          _selectedCurrencyId = defaultCurr['id'];
          _currencyRate = defaultCurr['exchange_rate'] as double? ?? 1.0;
          _currencySymbol = defaultCurr['symbol'] ?? 'د.أ';
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل العملات: $e')),
      );
    }
  }

  // إضافة بند جديد إلى الفاتورة
  void _addItem() {
    final desc = _itemDescController.text.trim();
    final qty = double.tryParse(_itemQtyController.text.trim());
    final price = double.tryParse(_itemPriceController.text.trim());

    if (desc.isEmpty || qty == null || price == null || qty <= 0 || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال بيانات البند بشكل صحيح')),
      );
      return;
    }

    setState(() {
      _items.add({
        'description': desc,
        'quantity': qty,
        'unit_price': price,
        'total': qty * price,
      });
      // مسح الحقول
      _itemDescController.clear();
      _itemQtyController.clear();
      _itemPriceController.clear();
    });
  }

  // حذف بند من الفاتورة
  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  // حساب الإجمالي قبل الضريبة
  double _getSubtotal() {
    return _items.fold(0, (sum, item) => sum + (item['total'] as double));
  }

  // حساب قيمة الضريبة
  double _getTax() {
    return _getSubtotal() * (_taxRate / 100);
  }

  // حساب الإجمالي النهائي
  double _getGrandTotal() {
    return _getSubtotal() + _getTax();
  }

  // حفظ الفاتورة في قاعدة البيانات
  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedContactId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار جهة اتصال')),
      );
      return;
    }
    if (_selectedCurrencyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار العملة')),
      );
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف على الأقل بنداً واحداً')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dbHelper = DatabaseHelper.instance;

      // إنشاء رقم فاتورة فريد
      final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';

      // بيانات الفاتورة مع العملة
      final Map<String, dynamic> invoiceData = {
        'invoice_number': invoiceNumber,
        'contact_id': _selectedContactId,
        'type': _invoiceType,
        'date': DateTime.now().toIso8601String(),
        'total': _getSubtotal(),
        'tax': _getTax(),
        'grand_total': _getGrandTotal(),
        'currency_id': _selectedCurrencyId,      // ✅ العملة المختارة
        'currency_rate': _currencyRate,          // ✅ سعر الصرف
        'status': 'unpaid',
        'note': _noteController.text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      };

      // إدراج الفاتورة والحصول على ID
      final invoiceId = await dbHelper.addInvoice(invoiceData);

      // إدراج بنود الفاتورة
      for (var item in _items) {
        await dbHelper.addInvoiceItem({
          'invoice_id': invoiceId,
          'description': item['description'],
          'quantity': item['quantity'],
          'unit_price': item['unit_price'],
          'total': item['total'],
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ الفاتورة رقم $invoiceNumber بنجاح 🎉'),
          backgroundColor: AppColors.success,
        ),
      );

      // العودة إلى الصفحة السابقة
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء الحفظ: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _itemDescController.dispose();
    _itemQtyController.dispose();
    _itemPriceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('فاتورة جديدة'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // نوع الفاتورة (بيع/شراء)
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _invoiceType,
                            decoration: const InputDecoration(labelText: 'نوع الفاتورة'),
                            items: const [
                              DropdownMenuItem(value: 'sale', child: Text('بيع (عميل)')),
                              DropdownMenuItem(value: 'purchase', child: Text('شراء (مورد)')),
                            ],
                            onChanged: (val) => setState(() => _invoiceType = val!),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedContactId,
                            decoration: const InputDecoration(labelText: 'جهة الاتصال'),
                            items: _contacts.map((contact) {
                              return DropdownMenuItem<int>(
                                value: contact['id'],
                                child: Text(contact['name']),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedContactId = val),
                            validator: (val) => val == null ? 'اختر جهة' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ===== اختيار العملة =====
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
                          _currencyRate = selected['exchange_rate'] as double? ?? 1.0;
                          _currencySymbol = selected['symbol'] ?? 'د.أ';
                        });
                      },
                      validator: (val) => val == null ? 'اختر العملة' : null,
                    ),
                    const SizedBox(height: 20),

                    // قسم إضافة البنود
                    const Text(
                      'البنود',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _itemDescController,
                            decoration: const InputDecoration(labelText: 'الوصف'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _itemQtyController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'الكمية'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _itemPriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'السعر'),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: AppColors.primary),
                          onPressed: _addItem,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // قائمة البنود المضافة
                    _items.isEmpty
                        ? const Text('لا توجد بنود مضافة بعد')
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return Card(
                                child: ListTile(
                                  title: Text(item['description']),
                                  subtitle: Text(
                                    'الكمية: ${item['quantity']} × ${item['unit_price']} = ${item['total']}',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: AppColors.danger),
                                    onPressed: () => _removeItem(index),
                                  ),
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 20),

                    // نسبة الضريبة
                    Row(
                      children: [
                        const Text('نسبة الضريبة:'),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            initialValue: _taxRate.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(suffixText: '%'),
                            onChanged: (val) {
                              final rate = double.tryParse(val);
                              if (rate != null) setState(() => _taxRate = rate);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ملخص الفاتورة (مع رمز العملة)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderWhite),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow('المجموع الفرعي', _getSubtotal()),
                          _buildSummaryRow('الضريبة (${_taxRate.toStringAsFixed(0)}%)', _getTax()),
                          const Divider(),
                          _buildSummaryRow(
                            'الإجمالي النهائي',
                            _getGrandTotal(),
                            isBold: true,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ملاحظات
                    TextFormField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'ملاحظات'),
                    ),
                    const SizedBox(height: 24),

                    // زر الحفظ
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveInvoice,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('حفظ الفاتورة'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ===== دالة عرض ملخص مع رمز العملة =====
  Widget _buildSummaryRow(String label, double value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            '${value.toStringAsFixed(2)} $_currencySymbol', // ✅ استخدام رمز العملة المختارة
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}