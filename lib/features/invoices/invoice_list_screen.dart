import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/local_database/database_helper.dart';
import '../../services/pdf_service.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dbHelper = DatabaseHelper.instance;
      final invoices = await dbHelper.getAllInvoices();

      // جلب أسماء الجهات ورموز العملات لكل فاتورة
      for (var invoice in invoices) {
        final contact = await dbHelper.getContact(invoice['contact_id']);
        invoice['contact_name'] = contact?['name'] ?? 'غير معروف';

        // ✅ جلب رمز العملة للفاتورة
        final currencySymbol = await dbHelper.getCurrencySymbolForInvoice(invoice['id']);
        invoice['currency_symbol'] = currencySymbol;
      }

      setState(() {
        _invoices = invoices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء تحميل الفواتير: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _exportPDF(int invoiceId) async {
    try {
      await PdfService.generateAndPrintInvoice(invoiceId);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل تصدير الفاتورة: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الفواتير'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInvoices,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: AppColors.danger),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.danger),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadInvoices,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : _invoices.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 60, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('لا توجد فواتير بعد'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _invoices.length,
                      itemBuilder: (context, index) {
                        final invoice = _invoices[index];
                        final id = invoice['id'] as int;
                        final number = invoice['invoice_number'] ?? 'N/A';
                        final contactName = invoice['contact_name'] ?? 'غير معروف';
                        final grandTotal = invoice['grand_total'] as double? ?? 0.0;
                        final status = invoice['status'] ?? 'unpaid';
                        final date = invoice['date'] ?? '';
                        // ✅ جلب رمز العملة من البيانات المحملة
                        final currencySymbol = invoice['currency_symbol'] ?? 'د.أ';

                        // تحديد لون الحالة
                        Color statusColor;
                        String statusText;
                        switch (status) {
                          case 'paid':
                            statusColor = AppColors.success;
                            statusText = 'مدفوعة';
                            break;
                          case 'partial':
                            statusColor = Colors.orange;
                            statusText = 'مدفوعة جزئياً';
                            break;
                          default:
                            statusColor = AppColors.danger;
                            statusText = 'غير مدفوعة';
                        }

                        // تنسيق التاريخ
                        String formattedDate = date;
                        try {
                          final dateTime = DateTime.parse(date);
                          formattedDate =
                              '${dateTime.day}/${dateTime.month}/${dateTime.year}';
                        } catch (_) {}

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: statusColor.withOpacity(0.1),
                              child: Icon(
                                status == 'paid'
                                    ? Icons.check_circle
                                    : status == 'partial'
                                        ? Icons.hourglass_empty
                                        : Icons.pending,
                                color: statusColor,
                              ),
                            ),
                            title: Text(
                              'فاتورة رقم $number',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('الجهة: $contactName'),
                                Text(
                                  'التاريخ: $formattedDate',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${grandTotal.toStringAsFixed(2)} $currencySymbol', // ✅ رمز العملة ديناميكي
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        statusText,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.picture_as_pdf,
                                      color: AppColors.danger),
                                  onPressed: () => _exportPDF(id),
                                  tooltip: 'تصدير PDF',
                                ),
                              ],
                            ),
                            onTap: () {
                              // TODO: فتح شاشة تفاصيل الفاتورة
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('سيتم إضافة تفاصيل الفاتورة قريباً'),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}