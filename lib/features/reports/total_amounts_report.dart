import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/local_database/database_helper.dart';

class TotalAmountsReport extends StatefulWidget {
  const TotalAmountsReport({super.key});

  @override
  State<TotalAmountsReport> createState() => _TotalAmountsReportState();
}

class _TotalAmountsReportState extends State<TotalAmountsReport> {
  List<Map<String, dynamic>> _data = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dbHelper = DatabaseHelper.instance;
      final contacts = await dbHelper.getAllContacts();
      final defaultCurrency = await dbHelper.getDefaultCurrency();
      final symbol = defaultCurrency?['symbol'] ?? 'د.أ';

      for (var contact in contacts) {
        final contactId = contact['id'];
        final invoices = await dbHelper.getInvoicesByContact(contactId);
        double totalAmount = 0.0;
        for (var inv in invoices) {
          totalAmount += (inv['grand_total'] as double) * (inv['currency_rate'] as double);
        }
        contact['total_amount'] = totalAmount;
        contact['currency_symbol'] = symbol;
      }

      contacts.sort((a, b) => (b['total_amount'] as double).compareTo(a['total_amount'] as double));

      setState(() {
        _data = contacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إجمالي المبالغ'),
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
                            children: [
                              const Text(
                                'الإسم',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'المبلغ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
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
                              final amount = item['total_amount'] as double? ?? 0.0;
                              final symbol = item['currency_symbol'] ?? 'د.أ';
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  title: Text(name),
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