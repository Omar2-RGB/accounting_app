import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // رقم الهاتف مع مفتاح الدولة (الأردن: 962)
  static const String _phoneNumber = '963995339401';
  static const String _whatsappUrl = 'https://wa.me/$_phoneNumber';

  Future<void> _launchWhatsApp() async {
    final Uri url = Uri.parse(_whatsappUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'لا يمكن فتح واتساب';
      }
    } catch (e) {
      // إذا لم يكن واتساب مثبتاً، نفتح المتصفح
      final Uri fallbackUrl = Uri.parse('https://wa.me/$_phoneNumber');
      if (await canLaunchUrl(fallbackUrl)) {
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عن البرنامج'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // شعار أو أيقونة التطبيق
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),

            // اسم التطبيق
            const Text(
              'تطبيق المحاسبة الشامل',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'الإصدار 1.0.0',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const Divider(height: 40),

            // اسم المطور
            const Text(
              'المهندس عمر شعلان عبد العزيز',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'مطور ومصمم التطبيق',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // شرح عن التطبيق
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderWhite),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 حول التطبيق',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'هذا التطبيق هو نظام محاسبة متكامل مصمم خصيصاً لتلبية احتياجات الشركات والأفراد في إدارة حساباتهم المالية بكل سهولة واحترافية.',
                    style: TextStyle(height: 1.6),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '✨ الميزات الرئيسية:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• إدارة العملاء والموردين\n'
                    '• إنشاء الفواتير (بيع / شراء)\n'
                    '• تسجيل المدفوعات وسندات القبض\n'
                    '• متابعة المخزون والمنتجات\n'
                    '• تقارير مالية شاملة\n'
                    '• دعم العملات المتعددة\n'
                    '• نسخ احتياطي واستعادة البيانات',
                    style: TextStyle(height: 1.8),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // معلومات الاتصال
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderWhite),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📞 للتواصل والدعم',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.phone, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        '0995339401',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.email, color: AppColors.primary),
                      const SizedBox(width: 12),
                      const Text(
                        'omar2rgb@gmail.com',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ✅ زر واتساب (تم إصلاح الأيقونة ورفع const)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _launchWhatsApp,
                      icon: Icon(Icons.message, color: Colors.white), // ✅ استخدم أيقونة message بدلاً من whatsapp
                      label: const Text(
                        'تواصل عبر واتساب',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // حقوق النشر
            Text(
              '© 2025 جميع الحقوق محفوظة',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              'المهندس عمر شعلان عبد العزيز',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}