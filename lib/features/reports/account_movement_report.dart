import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/local_database/database_helper.dart';

class AccountMovementReport extends StatefulWidget {
  const AccountMovementReport({super.key});

  @override
  State<AccountMovementReport> createState() => _AccountMovementReportState();
}

class _AccountMovementReportState extends State<AccountMovementReport> {
  List<Map<String, dynamic>> _data = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _currencySymbol = 'د.أ';

  @override
  void initState() {
    super.initState();
    _loadCurrencySymbol();
    _loadData();
  }

  Future<void> _loadCurrencySymbol() async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final defaultCurrency = await dbHelper.getDefaultCurrency();
      if (mounted && defaultCurrency != null) {
        setState(() {
          _currencySymbol = defaultCurrency['symbol'] ?? 'د.أ';
        });
      }
    } catch (e) {
      // تجاهل
    }
  }

  Future<void> _loadData() async {
    if (mounted) setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dbHelper = DatabaseHelper.instance;
      final contacts = await dbHelper.getAllContacts();

      for (var contact in contacts) {
        final contactId = contact['id'];
        final invoices = await dbHelper.getInvoicesByContact(contactId);
        final payments = await dbHelper.getPaymentsByContact(contactId);

        double previousBalance = 0.0;
        double periodBalance = 0.0;
        double finalBalance = 0.0;

        for (var inv in invoices) {
          final amountInBase = (inv['grand_total'] as double) * (inv['currency_rate'] as double);
          if (inv['type'] == 'sale') {
            periodBalance += amountInBase;
          } else {
            periodBalance -= amountInBase;
          }
        }

        for (var pay in payments) {
          if (pay['type'] == 'receive') {
            periodBalance -= pay['amount'] as double;
          } else {
            periodBalance += pay['amount'] as double;
          }
        }

        finalBalance = previousBalance + periodBalance;

        contact['previous_balance'] = previousBalance;
        contact['period_balance'] = periodBalance;
        contact['final_balance'] = finalBalance;
        contact['currency_symbol'] = _currencySymbol;
      }

      if (mounted) {
        setState(() {
          _data = contacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'خطأ: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حركة الحسابات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _data.isEmpty
                  ? const Center(child: Text('لا توجد بيانات'))
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('الحساب', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('العملة', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('رصيد سابق', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('رصيد الفترة', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('الرصيد', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _data.length,
                            itemBuilder: (context, index) {
                              final item = _data[index];
                              final name = item['name'] ?? 'غير معروف';
                              final symbol = item['currency_symbol'] ?? 'د.أ';
                              final prev = item['previous_balance'] as double? ?? 0.0;
                              final period = item['period_balance'] as double? ?? 0.0;
                              final finalBal = item['final_balance'] as double? ?? 0.0;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                      Expanded(
                                        child: Text(symbol, textAlign: TextAlign.center),
                                      ),
                                      Expanded(
                                        child: Text(
                                          prev.toStringAsFixed(2),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          period.toStringAsFixed(2),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: period >= 0 ? AppColors.success : AppColors.danger,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          finalBal.toStringAsFixed(2),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: finalBal >= 0 ? AppColors.success : AppColors.danger,
                                          ),
                                        ),
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
}