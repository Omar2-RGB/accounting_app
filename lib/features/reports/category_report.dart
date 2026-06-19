import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/local_database/database_helper.dart';

class CategoryReport extends StatefulWidget {
  const CategoryReport({super.key});

  @override
  State<CategoryReport> createState() => _CategoryReportState();
}

class _CategoryReportState extends State<CategoryReport> {
  List<Map<String, dynamic>> _categories = [];
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
      final defaultCurrency = await dbHelper.getDefaultCurrency();
      final symbol = defaultCurrency?['symbol'] ?? 'د.أ';

      // عملاء
      final customers = await dbHelper.getContactsByType('client');
      double customerTotal = 0.0;
      for (var c in customers) {
        final invoices = await dbHelper.getInvoicesByContact(c['id']);
        for (var inv in invoices) {
          customerTotal += (inv['grand_total'] as double) * (inv['currency_rate'] as double);
        }
      }

      // موردين
      final suppliers = await dbHelper.getContactsByType('supplier');
      double supplierTotal = 0.0;
      for (var s in suppliers) {
        final invoices = await dbHelper.getInvoicesByContact(s['id']);
        for (var inv in invoices) {
          supplierTotal += (inv['grand_total'] as double) * (inv['currency_rate'] as double);
        }
      }

      setState(() {
        _categories = [
          {'name': 'العملاء', 'total': customerTotal, 'symbol': symbol},
          {'name': 'الموردين', 'total': supplierTotal, 'symbol': symbol},
        ];
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
        title: const Text('إجمالي التصنيفات'),
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
              : _categories.isEmpty
                  ? const Center(child: Text('لا توجد بيانات'))
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('التصنيف', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('المبلغ', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(),
                          ..._categories.map((item) {
                            final name = item['name'] ?? '';
                            final total = item['total'] as double? ?? 0.0;
                            final symbol = item['symbol'] ?? 'د.أ';
                            return ListTile(
                              title: Text(name),
                              trailing: Text(
                                '${total.toStringAsFixed(2)} $symbol',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: total >= 0 ? AppColors.success : AppColors.danger,
                                ),
                              ),
                            );
                          }),
                          const Divider(),
                        ],
                      ),
                    ),
    );
  }
}