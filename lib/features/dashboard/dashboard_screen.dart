import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../contacts/add_contact_screen.dart';
import '../contacts/contacts_list_screen.dart';
import '../invoices/invoice_screen.dart';
import '../reports/account_statement_screen.dart';
import '../payments/add_payment_screen.dart';
import '../../data/local_database/database_helper.dart';
import '../invoices/invoice_list_screen.dart';
import '../currencies/currency_list_screen.dart';
import '../settings/settings_screen.dart';
import '../reports/reports_screen.dart';
import '../products/customer_debts_screen.dart';
import '../products/profit_loss_screen.dart';
import '../products/products_screen.dart';
import '../products/expenses_screen.dart';
import '../products/inventory_screen.dart';
import '../auth/login_screen.dart';
import '../products/add_debt_screen.dart';
class DashboardScreen extends StatefulWidget {
  final String userName;
  const DashboardScreen({super.key, required this.userName});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<Map<String, dynamic>> _loadDashboardData() async {
    final db = DatabaseHelper.instance;
    final balance = await db.getTotalBalance();
    final receivables = await db.getTotalReceivables();
    final payables = await db.getTotalPayables();
    final defaultCurrency = await db.getDefaultCurrency();
    final currencySymbol = defaultCurrency?['symbol'] ?? 'د.أ';
    return {
      'balance': balance,
      'receivables': receivables,
      'payables': payables,
      'symbol': currencySymbol,
    };
  }

  // دالة للخروج
  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مرحباً، ${widget.userName}'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
        ],
      ),
      // ✅ القائمة الجانبية (Drawer)
      drawer: Drawer(
        child: Container(
          color: AppColors.cardColor,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Header
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withOpacity(0.7)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 40, color: AppColors.primary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'تطبيق المحاسبة',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
_buildDrawerItem(
  icon: Icons.money_off,
  title: 'تسجيل دين',
  onTap: () => _navigateTo(context, const AddDebtScreen()),
),
              // === قسم المحاسبة ===
              _buildDrawerGroup(
                title: 'المحاسبة',
                icon: Icons.account_balance,
                children: [
                  _buildDrawerItem(
                    icon: Icons.people,
                    title: 'جهات الاتصال',
                    onTap: () => _navigateTo(context, const ContactsListScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.person_add,
                    title: 'إضافة جهة',
                    onTap: () => _navigateTo(context, const AddContactScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.receipt,
                    title: 'الفواتير',
                    onTap: () => _navigateTo(context, const InvoiceListScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.receipt_long,
                    title: 'فاتورة جديدة',
                    onTap: () => _navigateTo(context, const InvoiceScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.money_rounded,
                    title: 'سند قبض/دفع',
                    onTap: () => _navigateTo(context, const AddPaymentScreen()),
                  ),
                ],
              ),

              // === قسم التقارير ===
              _buildDrawerGroup(
                title: 'التقارير',
                icon: Icons.analytics,
                children: [
                  _buildDrawerItem(
                    icon: Icons.analytics_outlined,
                    title: 'التقارير الرئيسية',
                    onTap: () => _navigateTo(context, const ReportsScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.people_outline,
                    title: 'ديون العملاء',
                    onTap: () => _navigateTo(context, const CustomerDebtsScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.pie_chart,
                    title: 'أرباح وخسائر',
                    onTap: () => _navigateTo(context, const ProfitLossScreen()),
                  ),
                ],
              ),

              // === قسم الإدارة ===
              _buildDrawerGroup(
                title: 'الإدارة',
                icon: Icons.settings_applications,
                children: [
                  _buildDrawerItem(
                    icon: Icons.inventory_2,
                    title: 'المنتجات',
                    onTap: () => _navigateTo(context, const ProductsScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.money_off,
                    title: 'المصاريف',
                    onTap: () => _navigateTo(context, const ExpensesScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.warehouse,
                    title: 'المخزون',
                    onTap: () => _navigateTo(context, const InventoryScreen()),
                  ),
                  _buildDrawerItem(
                    icon: Icons.attach_money,
                    title: 'العملات',
                    onTap: () => _navigateTo(context, const CurrencyListScreen()),
                  ),
                ],
              ),

              // === الإعدادات والخروج ===
              const Divider(),
              _buildDrawerItem(
                icon: Icons.settings,
                title: 'الإعدادات',
                onTap: () => _navigateTo(context, const SettingsScreen()),
              ),
              _buildDrawerItem(
                icon: Icons.logout,
                title: 'خروج',
                color: AppColors.danger,
                onTap: _logout,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // بطاقة الرصيد (نفسها)
              FutureBuilder<Map<String, dynamic>>(
                future: _loadDashboardData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.6),
                                AppColors.primary.withOpacity(0.2),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.6),
                                AppColors.primary.withOpacity(0.2),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.white, size: 40),
                              const SizedBox(height: 8),
                              Text(
                                'حدث خطأ في تحميل البيانات',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final data = snapshot.data!;
                  final balance = data['balance'] as double;
                  final receivables = data['receivables'] as double;
                  final payables = data['payables'] as double;
                  final currencySymbol = data['symbol'] as String;

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withOpacity(0.6),
                              AppColors.primary.withOpacity(0.2),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'إجمالي الرصيد الحالي',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                                ),
                                const Icon(Icons.account_balance_wallet, color: AppColors.accent),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${balance.toStringAsFixed(2)} $currencySymbol',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: balance >= 0 ? AppColors.success : AppColors.danger,
                                  ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSummaryItem('لك (مدين)', receivables.toStringAsFixed(2), AppColors.success),
                                _buildSummaryItem('عليك (دائن)', payables.toStringAsFixed(2), AppColors.danger),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // تم إزالة جميع الأزرار السريعة ووضعها في القائمة الجانبية
              // يمكنك إضافة بعض الاختصارات هنا إذا أردت (مثل زر عائم)
            ],
          ),
        ),
      ),
    );
  }

  // دوال مساعدة لبناء القائمة الجانبية
  Widget _buildDrawerGroup({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        ...children,
        const Divider(height: 8),
      ],
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.primary),
      title: Text(title, style: TextStyle(color: color)),
      onTap: () {
        // إغلاق القائمة قبل الانتقال
        Navigator.pop(context);
        onTap();
      },
      trailing: const Icon(Icons.chevron_left, size: 16, color: Colors.grey),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  Widget _buildSummaryItem(String title, String amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }
}