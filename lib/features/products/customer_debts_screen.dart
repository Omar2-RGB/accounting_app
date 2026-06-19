import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/local_database/database_helper.dart';
import '../payments/add_amount_screen.dart'; // تأكد من صحة المسار

class CustomerDebtsScreen extends StatefulWidget {
  const CustomerDebtsScreen({super.key});

  @override
  State<CustomerDebtsScreen> createState() => _CustomerDebtsScreenState();
}

class _CustomerDebtsScreenState extends State<CustomerDebtsScreen> {
  List<Map<String, dynamic>> _debts = [];
  List<Map<String, dynamic>> _filteredDebts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  double _totalDebts = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    setState(() => _isLoading = true);
    try {
      final dbHelper = DatabaseHelper.instance;
      final debts = await dbHelper.getCustomerDebts();
      _totalDebts = debts.fold(0, (sum, d) => sum + (d['debt_amount'] as double? ?? 0.0));
      setState(() {
        _debts = debts;
        _filteredDebts = debts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    }
  }

  void _filterDebts(String query) {
    setState(() {
      _searchQuery = query;
      _filteredDebts = query.isEmpty
          ? _debts
          : _debts.where((d) {
              final name = (d['name'] ?? '').toLowerCase();
              final phone = (d['phone'] ?? '').toLowerCase();
              final q = query.toLowerCase();
              return name.contains(q) || phone.contains(q);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ديون العملاء'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDebts,
          ),
        ],
      ),
      body: Column(
        children: [
          // إجمالي الديون
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.danger, AppColors.danger.withOpacity(0.6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'إجمالي الديون المستحقة',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  '${_totalDebts.toStringAsFixed(2)} د.أ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // بحث
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'بحث عن عميل...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                          _filterDebts('');
                        },
                      )
                    : null,
              ),
              onChanged: _filterDebts,
            ),
          ),
          const SizedBox(height: 8),
          // القائمة
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredDebts.isEmpty
                    ? const Center(child: Text('لا توجد ديون مسجلة'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredDebts.length,
                        itemBuilder: (context, index) {
                          final debt = _filteredDebts[index];
                          final name = debt['name'] ?? 'غير معروف';
                          final phone = debt['phone'] ?? '';
                          final amount = debt['debt_amount'] as double? ?? 0.0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8), // ✅ تم التصحيح هنا
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(0.1),
                                child: Icon(Icons.person, color: AppColors.primary),
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: phone.isNotEmpty ? Text(phone) : null,
                              trailing: Text(
                                '${amount.toStringAsFixed(2)} د.أ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: amount > 0 ? AppColors.danger : AppColors.success,
                                  fontSize: 16,
                                ),
                              ),
                              onTap: () {
                                // TODO: فتح تفاصيل العميل ودفتر حسابه
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      // ✅ زر عائم لإضافة دين جديد
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddAmountScreen(),
            ),
          ).then((_) => _loadDebts());
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}