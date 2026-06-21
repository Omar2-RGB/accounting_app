import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/local_database/database_helper.dart';

class DetailsReport extends StatefulWidget {
  const DetailsReport({super.key});

  @override
  State<DetailsReport> createState() => _DetailsReportState();
}

class _DetailsReportState extends State<DetailsReport> {
  List<Map<String, dynamic>> _transactions = [];
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
      final invoices = await dbHelper.getAllInvoices();

      for (var inv in invoices) {
        final contact = await dbHelper.getContact(inv['contact_id']);
        inv['contact_name'] = contact?['name'] ?? 'غير معروف';
        inv['currency_symbol'] = _currencySymbol;
        inv['amount_in_base'] = (inv['grand_total'] as double) * (inv['currency_rate'] as double);
      }

      invoices.sort((a, b) => b['date'].compareTo(a['date']));

      if (mounted) {
        setState(() {
          _transactions = invoices;
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
        title: const Text('تفاصيل المبالغ'),
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
              : _transactions.isEmpty
                  ? const Center(child: Text('لا توجد معاملات'))
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('الإسم', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('المبلغ', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _transactions.length,
                            itemBuilder: (context, index) {
                              final item = _transactions[index];
                              final date = item['date']?.split('T').first ?? '';
                              final name = item['contact_name'] ?? 'غير معروف';
                              final amount = item['amount_in_base'] as double? ?? 0.0;
                              final symbol = item['currency_symbol'] ?? 'د.أ';
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(date),
                                  subtitle: Text(name),
                                  trailing: Text(
                                    '${amount.toStringAsFixed(2)} $symbol',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: amount >= 0 ? AppColors.success : AppColors.danger,
                                    ),
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