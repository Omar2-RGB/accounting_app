import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../data/local_database/database_helper.dart';

class PdfService {
  static Future<void> generateAndPrintInvoice(int invoiceId) async {
    // جلب بيانات الفاتورة مع التفاصيل
    final dbHelper = DatabaseHelper.instance;
    final invoiceData = await dbHelper.getInvoiceWithDetails(invoiceId);
    if (invoiceData == null) return;

    // إنشاء ملف PDF
    final pdf = pw.Document();

    // تنسيق التاريخ
    final dateFormat = DateFormat('yyyy-MM-dd');
    final date = DateTime.parse(invoiceData['date']);
    final formattedDate = dateFormat.format(date);

    // استخراج البيانات
    final invoiceNumber = invoiceData['invoice_number'] ?? 'N/A';
    final contactName = invoiceData['contact_name'] ?? 'غير معروف';
    final contactPhone = invoiceData['contact_phone'] ?? '';
    final total = invoiceData['total'] as double? ?? 0.0;
    final tax = invoiceData['tax'] as double? ?? 0.0;
    final grandTotal = invoiceData['grand_total'] as double? ?? 0.0;
    final status = invoiceData['status'] ?? 'unpaid';
    final note = invoiceData['note'] ?? '';
    final items = invoiceData['items'] as List<dynamic>? ?? [];

    // ترجمة الحالة وتحديد الألوان
    String statusText;
    PdfColor statusColor;
    int statusColorValue; // القيمة السداسية للون مع الشفافية 0.2

    switch (status) {
      case 'paid':
        statusText = 'مدفوعة';
        statusColor = PdfColors.green;
        statusColorValue = 0x3300FF00; // أخضر مع شفافية 20%
        break;
      case 'partial':
        statusText = 'مدفوعة جزئياً';
        statusColor = PdfColors.orange;
        statusColorValue = 0x33FFA500; // برتقالي مع شفافية 20%
        break;
      default:
        statusText = 'غير مدفوعة';
        statusColor = PdfColors.red;
        statusColorValue = 0x33FF0000; // أحمر مع شفافية 20%
    }

    // إنشاء لون خفيف (شفاف) للخلفية
    final PdfColor statusColorLight = PdfColor.fromInt(statusColorValue);

    // بناء الـ PDF
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // العنوان
              pw.Center(
                child: pw.Text(
                  'فاتورة رقم $invoiceNumber',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // معلومات الفاتورة
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('التاريخ: $formattedDate'),
                      pw.Text('الجهة: $contactName'),
                      if (contactPhone.isNotEmpty)
                        pw.Text('الهاتف: $contactPhone'),
                    ],
                  ),
                  pw.Container(
                    padding: pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: pw.BoxDecoration(
                      color: statusColorLight,
                      border: pw.Border.all(color: statusColor),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      statusText,
                      style: pw.TextStyle(
                        color: statusColor,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // جدول البنود
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: pw.FlexColumnWidth(4),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(2),
                  3: pw.FlexColumnWidth(2),
                },
                children: [
                  // رأس الجدول
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'الوصف',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'الكمية',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'السعر',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'المجموع',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  // صفوف البنود
                  ...items.map((item) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(item['description'] ?? ''),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            (item['quantity'] as double? ?? 0).toString(),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            (item['unit_price'] as double? ?? 0)
                                .toStringAsFixed(2),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            (item['total'] as double? ?? 0).toStringAsFixed(2),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 20),

              // الملخص
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('المجموع الفرعي: ${total.toStringAsFixed(2)} د.أ'),
                      pw.Text('الضريبة: ${tax.toStringAsFixed(2)} د.أ'),
                      pw.Divider(),
                      pw.Text(
                        'الإجمالي: ${grandTotal.toStringAsFixed(2)} د.أ',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // الملاحظات
              if (note.isNotEmpty)
                pw.Text('ملاحظات: $note', style: pw.TextStyle(fontSize: 12)),

              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  'شكراً لثقتكم بنا',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
              ),
            ],
          );
        },
      ),
    );

    // طباعة أو مشاركة الـ PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'فاتورة_$invoiceNumber.pdf',
    );
  }
}