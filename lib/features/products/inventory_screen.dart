import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/local_database/database_helper.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String _currencySymbol = 'د.أ';

  @override
  void initState() {
    super.initState();
    _loadInventory();
    _loadCurrencySymbol();
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
      // تجاهل الخطأ، استخدم القيمة الافتراضية
    }
  }

  Future<void> _loadInventory() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final dbHelper = DatabaseHelper.instance;
      final products = await dbHelper.getAllProducts();

      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  Future<void> _addStock(int productId, double quantity) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.addInventoryTransaction({
        'product_id': productId,
        'quantity': quantity,
        'type': 'in',
        'note': 'إضافة مخزون',
        'date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });

      await _loadInventory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة المخزون'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المخزون'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInventory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(child: Text('لا توجد منتجات'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    final id = product['id'] as int;
                    final name = product['name'] ?? '';
                    final quantity = product['quantity'] as double? ?? 0.0;
                    final price = product['price'] as double? ?? 0.0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  quantity > 0 ? AppColors.success : AppColors.danger,
                              child: Text(
                                quantity > 0 ? (quantity > 10 ? '✓' : '!') : '✗',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('السعر: $price $_currencySymbol'),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  '${quantity.toStringAsFixed(1)}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: quantity > 0 ? AppColors.success : AppColors.danger,
                                  ),
                                ),
                                const Text('وحدة', style: TextStyle(fontSize: 10)),
                              ],
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.add_box, color: Colors.blue),
                              onPressed: () {
                                _showAddStockDialog(context, id);
                              },
                              tooltip: 'إضافة مخزون',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showAddStockDialog(BuildContext context, int productId) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة مخزون'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'الكمية المضافة'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.dispose();
              Navigator.pop(context);
            },
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final qty = double.tryParse(controller.text.trim());
              controller.dispose();
              if (qty != null && qty > 0) {
                Navigator.pop(context);
                _addStock(productId, qty);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('أدخل كمية صحيحة')),
                );
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }
}