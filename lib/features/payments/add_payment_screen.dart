import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/local_database/database_helper.dart';

class AddPaymentScreen extends StatefulWidget {
  final int? contactId; // اختياري: إذا تم تمرير جهة معينة (مثلاً من دفتر الحسابات)

  const AddPaymentScreen({super.key, this.contactId});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _invoices = [];
  
  int? _selectedContactId;
  int? _selectedInvoiceId;
  double _amount = 0.0;
  double _maxAmount = 0.0;
  String _paymentType = 'receive'; // 'receive' أو 'pay'
  String _note = '';
  DateTime _selectedDate = DateTime.now();
  
  bool _isLoading = false;
  bool _isLoadingInvoices = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    if (widget.contactId != null) {
      _selectedContactId = widget.contactId;
      _loadInvoices(widget.contactId!);
    }
  }

  // تحميل قائمة الجهات
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

  // تحميل الفواتير غير المدفوعة لجهة معينة
  Future<void> _loadInvoices(int contactId) async {
    setState(() => _isLoadingInvoices = true);
    try {
      final dbHelper = DatabaseHelper.instance;
      final invoices = await dbHelper.getUnpaidInvoicesByContact(contactId);
      
      // تحديد نوع الدفع تلقائياً بناءً على نوع الفاتورة الأولى (إذا وجدت)
      if (invoices.isNotEmpty) {
        final firstInvoice = invoices.first;
        final invoiceType = firstInvoice['type'];
        setState(() {
          _paymentType = invoiceType == 'sale' ? 'receive' : 'pay';
        });
      }
      
      setState(() {
        _invoices = invoices;
        _selectedInvoiceId = null;
        _amount = 0.0;
        _maxAmount = 0.0;
        _isLoadingInvoices = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل الفواتير: $e')),
      );
      setState(() => _isLoadingInvoices = false);
    }
  }

  // تحديث المبلغ الأقصى عند اختيار فاتورة
  void _onInvoiceSelected(int? invoiceId) {
    if (invoiceId == null) {
      setState(() {
        _selectedInvoiceId = null;
        _amount = 0.0;
        _maxAmount = 0.0;
      });
      return;
    }

    final invoice = _invoices.firstWhere((inv) => inv['id'] == invoiceId);
    final grandTotal = invoice['grand_total'] as double;
    
    // حساب المبلغ المدفوع سابقاً (في حال كانت مدفوعة جزئياً)
    // نأخذه من قاعدة البيانات مباشرة إذا أردنا الدقة، ولكننا نعتمد على القيمة الموجودة
    // سنحسب الرصيد المتبقي
    _updateMaxAmount(invoiceId);
  }

  Future<void> _updateMaxAmount(int invoiceId) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final paidAmount = await dbHelper.getPaidAmountForInvoice(invoiceId);
      
      final invoice = _invoices.firstWhere((inv) => inv['id'] == invoiceId);
      final grandTotal = invoice['grand_total'] as double;
      final remaining = grandTotal - paidAmount;
      
      setState(() {
        _selectedInvoiceId = invoiceId;
        _maxAmount = remaining;
        _amount = remaining; // نضع المبلغ الافتراضي = الرصيد المتبقي
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في حساب الرصيد: $e')),
      );
    }
  }

  // حفظ الدفعة
  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedContactId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار جهة اتصال')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dbHelper = DatabaseHelper.instance;
      
      final Map<String, dynamic> paymentData = {
        'contact_id': _selectedContactId,
        'invoice_id': _selectedInvoiceId, // يمكن أن تكون null (سند عام)
        'amount': _amount,
        'date': _selectedDate.toIso8601String(),
        'type': _paymentType,
        'note': _note.trim(),
      };

      final paymentId = await dbHelper.addPaymentWithStatusUpdate(paymentData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تسجيل ${_paymentType == 'receive' ? 'سند قبض' : 'سند دفع'} بنجاح 🎉'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context, true); // إرجاع true لتحديث الصفحة السابقة
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء الحفظ: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_paymentType == 'receive' ? 'سند قبض جديد' : 'سند دفع جديد'),
        actions: [
          // زر تبديل نوع الدفع (يدوياً)
          DropdownButton<String>(
            value: _paymentType,
            items: const [
              DropdownMenuItem(value: 'receive', child: Text('قبض')),
              DropdownMenuItem(value: 'pay', child: Text('دفع')),
            ],
            onChanged: (val) => setState(() => _paymentType = val!),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // اختيار الجهة
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
                      onChanged: (val) {
                        setState(() {
                          _selectedContactId = val;
                          _selectedInvoiceId = null;
                          _amount = 0.0;
                          _maxAmount = 0.0;
                          _invoices = [];
                        });
                        if (val != null) {
                          _loadInvoices(val);
                        }
                      },
                      validator: (val) => val == null ? 'اختر جهة' : null,
                    ),
                    const SizedBox(height: 16),

                    // اختيار الفاتورة (اختياري)
                    _isLoadingInvoices
                        ? const Center(child: CircularProgressIndicator())
                        : DropdownButtonFormField<int>(
                            value: _selectedInvoiceId,
                            decoration: const InputDecoration(
                              labelText: 'الفاتورة (اختياري)',
                              border: OutlineInputBorder(),
                            ),
                            hint: const Text('بدون فاتورة (سند عام)'),
                            items: [
                              const DropdownMenuItem<int>(
                                value: null,
                                child: Text('بدون فاتورة'),
                              ),
                              ..._invoices.map((invoice) {
                                final invoiceType = invoice['type'] == 'sale' ? 'بيع' : 'شراء';
                                return DropdownMenuItem<int>(
                                  value: invoice['id'],
                                  child: Text(
                                    'فاتورة ${invoice['invoice_number']} ($invoiceType) - ${invoice['grand_total']} د.أ',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }),
                            ],
                            onChanged: (val) => _onInvoiceSelected(val),
                          ),
                    const SizedBox(height: 16),

                    // المبلغ
                    TextFormField(
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'المبلغ',
                        border: const OutlineInputBorder(),
                        suffixText: 'د.أ',
                        helperText: _maxAmount > 0 ? 'الرصيد المتبقي: ${_maxAmount.toStringAsFixed(2)} د.أ' : null,
                      ),
                      onChanged: (val) {
                        final amount = double.tryParse(val) ?? 0.0;
                        setState(() => _amount = amount);
                      },
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'الرجاء إدخال المبلغ';
                        }
                        final amount = double.tryParse(val);
                        if (amount == null || amount <= 0) {
                          return 'المبلغ يجب أن يكون أكبر من 0';
                        }
                        if (_selectedInvoiceId != null && amount > _maxAmount) {
                          return 'المبلغ لا يمكن أن يتجاوز الرصيد المتبقي (${_maxAmount.toStringAsFixed(2)})';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // تاريخ الدفع
                    ListTile(
                      title: const Text('التاريخ'),
                      subtitle: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _selectedDate = date);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // ملاحظات
                    TextFormField(
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات (اختياري)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => _note = val,
                    ),
                    const SizedBox(height: 24),

                    // زر الحفظ
                    ElevatedButton(
                      onPressed: _isLoading ? null : _savePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: Text(
                        _paymentType == 'receive' ? 'تسجيل سند قبض' : 'تسجيل سند دفع',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}