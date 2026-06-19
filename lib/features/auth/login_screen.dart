import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/local_database/database_helper.dart';
import '../dashboard/dashboard_screen.dart';
import 'register_screen.dart'; // سنضيفها لاحقاً

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
// دالة تسجيل الدخول
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool isWeb = identical(0, 0.0); // للتحقق من بيئة المتصفح

      if (isWeb) {
        // --- 🌐 محاكاة تسجيل الدخول على المتصفح ---
        await Future.delayed(const Duration(seconds: 1)); // محاكاة وقت التحميل
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('مرحباً بعودتك يا عمر! (وضع المتصفح)'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DashboardScreen(userName: 'عمر'), // تمرير الاسم للداشبورد
          ),
        );
      } else {
        // --- 📱 تسجيل الدخول الحقيقي من قاعدة البيانات (للهاتف) ---
        final dbHelper = DatabaseHelper.instance;
        final user = await dbHelper.loginUser(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        if (!mounted) return;

        if (user != null) {
          // ✅ تسجيل الدخول ناجح
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('مرحباً بعودتك!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(userName: user['name']),
            ),
          );
        } else {
          // ❌ بيانات غير صحيحة
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('البريد الإلكتروني أو كلمة المرور غير صحيحة'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                Text(
                  'مرحباً بعودتك',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'سجل الدخول لإدارة حساباتك',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // نموذج تسجيل الدخول
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // حقل البريد الإلكتروني
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          labelText: 'البريد الإلكتروني',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'الرجاء إدخال البريد الإلكتروني';
                          }
                          // تحقق بسيط من صيغة الإيميل
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value.trim())) {
                            return 'الرجاء إدخال بريد إلكتروني صحيح';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // حقل كلمة المرور
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'الرجاء إدخال كلمة المرور';
                          }
                          if (value.trim().length < 6) {
                            return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // رابط نسيت كلمة المرور
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          onPressed: () {
                            // TODO: إضافة وظيفة إعادة تعيين كلمة المرور
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('سيتم إضافة استعادة كلمة المرور قريباً'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                          child: const Text('نسيت كلمة المرور؟'),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // زر تسجيل الدخول
                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'تسجيل الدخول',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // زر التوجه إلى التسجيل
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'ليس لديك حساب؟',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text('إنشاء حساب جديد'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}