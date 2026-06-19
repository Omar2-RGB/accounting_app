import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/local_database/database_helper.dart';

class ProfitLossScreen extends StatefulWidget {
  const ProfitLossScreen({super.key});

  @override
  State<ProfitLossScreen> createState() => _ProfitLossScreenState();
}

class _ProfitLossScreenState extends State<ProfitLossScreen> {
  Map<String, double> _data = {};
  bool _isLoading = true;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final dbHelper = DatabaseHelper.instance;
      final data = await dbHelper.getProfitLoss(_startDate, _endDate);
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sales = _data['sales'] ?? 0.0;
    final purchases = _data['purchases'] ?? 0.0;
    final expenses = _data['expenses'] ?? 0.0;
    final profit = _data['profit'] ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الأرباح والخسائر'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          // فلتر التاريخ
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _startDate = date);
                        _loadData();
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'من تاريخ',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _endDate = date);
                        _loadData();
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'إلى تاريخ',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(DateFormat('dd/MM/yyyy').format(_endDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _loadData,
                ),
              ],
            ),
          ),
          // بطاقات الأرباح والخسائر
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildStatCard('إجمالي المبيعات', sales, AppColors.success),
                        const SizedBox(height: 12),
                        _buildStatCard('إجمالي المشتريات', purchases, AppColors.danger),
                        const SizedBox(height: 12),
                        _buildStatCard('إجمالي المصاريف', expenses, Colors.orange),
                        const SizedBox(height: 12),
                        const Divider(),
                        _buildStatCard(
                          'صافي الربح / الخسارة',
                          profit,
                          profit >= 0 ? AppColors.success : AppColors.danger,
                          isProfit: true,
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, double value, Color color, {bool isProfit = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: isProfit ? 18 : 16,
              fontWeight: isProfit ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${value.toStringAsFixed(2)} د.أ',
            style: TextStyle(
              fontSize: isProfit ? 24 : 18,
              fontWeight: isProfit ? FontWeight.bold : FontWeight.normal,
              color: isProfit ? (value >= 0 ? color : AppColors.danger) : color,
            ),
          ),
        ],
      ),
    );
  }
}