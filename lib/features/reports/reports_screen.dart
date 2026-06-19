import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'total_amounts_report.dart';
import 'details_report.dart';
import 'category_report.dart';
import 'account_movement_report.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildReportCard(
            context,
            icon: Icons.attach_money,
            title: 'إجمالي المبالغ',
            subtitle: 'عرض إجمالي المبالغ لكل جهة',
            color: AppColors.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TotalAmountsReport()),
              );
            },
          ),
          _buildReportCard(
            context,
            icon: Icons.list_alt,
            title: 'تفاصيل المبالغ',
            subtitle: 'عرض جميع المعاملات بالتفصيل',
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DetailsReport()),
              );
            },
          ),
          _buildReportCard(
            context,
            icon: Icons.category,
            title: 'إجمالي التصنيفات',
            subtitle: 'عرض إجمالي المبالغ حسب التصنيف (عملاء/موردين)',
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CategoryReport()),
              );
            },
          ),
          _buildReportCard(
            context,
            icon: Icons.account_balance,
            title: 'حركة الحسابات',
            subtitle: 'عرض الرصيد السابق ورصيد الفترة والرصيد النهائي',
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AccountMovementReport()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}