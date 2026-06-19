import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../data/local_database/database_helper.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<Map<String, dynamic>> _expenses = [];
  bool _isLoading = true;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    try {
      final dbHelper = DatabaseHelper.instance;
      final expenses = await dbHelper.getExpensesByDate(_startDate, _endDate);
      setState(() {
        _expenses = expenses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e')),
      );
    }
  }

  Future<void> _addExpense() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddExpenseDialog(),
    );
    if (result != null) {
      try {
        final dbHelper = DatabaseHelper.instance;
        await dbHelper.addExpense(result);
        _loadExpenses();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة المصروف'), backgroundColor: AppColors.success),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _deleteExpense(int id) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.deleteExpense(id);
      _loadExpenses();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف المصروف'), backgroundColor: AppColors.success),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  double _getTotal() {
    return _expenses.fold(0, (sum, e) => sum + (e['amount'] as double? ?? 0.0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المصاريف'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadExpenses,
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
                        _loadExpenses();
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
                        _loadExpenses();
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
                  onPressed: _loadExpenses,
                ),
              ],
            ),
          ),
          // الإجمالي
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('إجمالي المصاريف:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${_getTotal().toStringAsFixed(2)} د.أ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.danger,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // القائمة
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _expenses.isEmpty
                    ? const Center(child: Text('لا توجد مصاريف'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _expenses.length,
                        itemBuilder: (context, index) {
                          final expense = _expenses[index];
                          final id = expense['id'] as int;
                          final title = expense['title'] ?? '';
                          final amount = expense['amount'] as double? ?? 0.0;
                          final category = expense['category'] ?? '';
                          final date = expense['date']?.split('T').first ?? '';
                          final note = expense['note'] ?? '';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.danger.withOpacity(0.1),
                                child: Icon(Icons.money_off, color: AppColors.danger),
                              ),
                              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('التصنيف: $category'),
                                  Text('التاريخ: $date'),
                                  if (note.isNotEmpty) Text('ملاحظة: $note', style: const TextStyle(fontSize: 10)),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${amount.toStringAsFixed(2)} د.أ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.danger,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: AppColors.danger, size: 20),
                                    onPressed: () => _deleteExpense(id),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _addExpense,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// حوار إضافة مصروف
class _AddExpenseDialog extends StatefulWidget {
  const _AddExpenseDialog();

  @override
  State<_AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<_AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة مصروف'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'العنوان'),
                validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'المبلغ'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'مطلوب';
                  if (double.tryParse(v) == null) return 'أدخل رقماً صحيحاً';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'التصنيف'),
                validator: (v) => v == null || v.trim().isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('التاريخ'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(_date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _date = date);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'ملاحظة'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'title': _titleController.text.trim(),
                'amount': double.parse(_amountController.text.trim()),
                'category': _categoryController.text.trim(),
                'date': _date.toIso8601String(),
                'note': _noteController.text.trim(),
                'created_at': DateTime.now().toIso8601String(),
              });
            }
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}