import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/local_database/database_helper.dart';
import '../payments/add_payment_screen.dart'; // 👈 أضف هذا الاستيراد

class AccountStatementScreen extends StatefulWidget {
  final int? contactId;
  final String? contactName;

  const AccountStatementScreen({
    super.key,
    this.contactId,
    this.contactName,
  });

  @override
  State<AccountStatementScreen> createState() => _AccountStatementScreenState();
}

class _AccountStatementScreenState extends State<AccountStatementScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  double _runningBalance = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.contactId != null) {
      _loadTransactions();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTransactions() async {
    if (widget.contactId == null) return;

    setState(() => _isLoading = true);

    try {
      final dbHelper = DatabaseHelper.instance;
      final invoices = await dbHelper.getInvoicesByContact(widget.contactId!);
      final payments = await dbHelper.getPaymentsByContact(widget.contactId!);

      List<Map<String, dynamic>> combined = [];

      for (var inv in invoices) {
        combined.add({
          'date': inv['date'],
          'type': inv['type'] == 'sale' ? 'فاتورة بيع' : 'فاتورة شراء',
          'description': 'فاتورة رقم ${inv['invoice_number']}',
          'amount': inv['grand_total'] as double,
          'transaction_type': inv['type'],
          'status': inv['status'],
          'is_invoice': true,
        });
      }

      for (var pay in payments) {
        combined.add({
          'date': pay['date'],
          'type': pay['type'] == 'receive' ? 'سند قبض' : 'سند دفع',
          'description': pay['note'] ?? 'دفعة',
          'amount': pay['amount'] as double,
          'transaction_type': pay['type'],
          'is_invoice': false,
        });
      }

      combined.sort((a, b) => b['date'].compareTo(a['date']));

      List<Map<String, dynamic>> reversed = List.from(combined.reversed);
      double balance = 0.0;

      for (var item in reversed) {
        final amount = item['amount'] as double;
        final isInvoice = item['is_invoice'] as bool;
        final transType = item['transaction_type'] as String;

        if (isInvoice) {
          if (transType == 'sale') {
            balance += amount;
          } else {
            balance -= amount;
          }
        } else {
          if (transType == 'receive') {
            balance -= amount;
          } else {
            balance += amount;
          }
        }
        item['running_balance'] = balance;
      }

      combined = reversed.reversed.toList();

      setState(() {
        _transactions = combined;
        _isLoading = false;
        if (_transactions.isNotEmpty) {
          _runningBalance = _transactions.first['running_balance'] as double;
        } else {
          _runningBalance = 0.0;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // إذا لم يتم تحديد جهة
    if (widget.contactId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('دفتر الحسابات')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('اختر جهة لعرض دفتر حساباتها'),
              SizedBox(height: 20),
              // يمكن إضافة زر للذهاب إلى قائمة الجهات
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('دفتر حسابات ${widget.contactName}'),
        actions: [
          // ✅ زر إضافة سند قبض/دفع
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddPaymentScreen(
                    contactId: widget.contactId,
                  ),
                ),
              ).then((_) => _loadTransactions()); // تحديث بعد العودة
            },
          ),
          // ✅ زر التحديث
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // بطاقة الملخص
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الرصيد الحالي',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          Text(
                            '${_runningBalance.toStringAsFixed(2)} د.أ',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _runningBalance >= 0 ? AppColors.success : AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'عدد الحركات',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          Text(
                            '${_transactions.length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // قائمة الحركات
                Expanded(
                  child: _transactions.isEmpty
                      ? const Center(child: Text('لا توجد حركات لهذه الجهة'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            final item = _transactions[index];
                            final isInvoice = item['is_invoice'] as bool;
                            final transType = item['transaction_type'] as String;
                            final amount = item['amount'] as double;
                            final balance = item['running_balance'] as double;

                            Color amountColor;
                            String amountPrefix = '';

                            if (isInvoice) {
                              if (transType == 'sale') {
                                amountColor = AppColors.success;
                                amountPrefix = '+';
                              } else {
                                amountColor = AppColors.danger;
                                amountPrefix = '-';
                              }
                            } else {
                              if (transType == 'receive') {
                                amountColor = AppColors.danger;
                                amountPrefix = '-';
                              } else {
                                amountColor = AppColors.success;
                                amountPrefix = '+';
                              }
                            }

                            IconData icon;
                            Color iconColor;
                            if (isInvoice) {
                              icon = Icons.receipt_long;
                              iconColor = transType == 'sale' ? AppColors.success : AppColors.danger;
                            } else {
                              icon = Icons.money_rounded;
                              iconColor = transType == 'receive' ? AppColors.danger : AppColors.success;
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: iconColor.withOpacity(0.1),
                                  child: Icon(icon, color: iconColor),
                                ),
                                title: Text(
                                  item['description'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  '${item['type']} - ${_formatDate(item['date'])}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '$amountPrefix${amount.toStringAsFixed(2)} د.أ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: amountColor,
                                      ),
                                    ),
                                    Text(
                                      'الرصيد: ${balance.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return isoDate;
    }
  }
}