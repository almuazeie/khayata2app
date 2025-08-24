import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'customer_list_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _auth = AuthService();

  static const _backgroundColor = Color(0xFFF5F5F5);
  static const _primaryColor   = Color(0xFF1A237E);
  static const _accentColor    = Color(0xFF64B5F6);

  // Controllers
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPassword = TextEditingController();
  final _regConfirm = TextEditingController();

  // Form keys
  final _loginFormKey = GlobalKey<FormState>();
  final _regFormKey = GlobalKey<FormState>();

  // Loading states
  bool _isLoginLoading = false;
  bool _isRegLoading = false;

  // Obscure toggles
  bool _loginObscure = true;
  bool _regObscure = true;
  bool _regConfirmObscure = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmail.dispose();
    _loginPassword.dispose();
    _regEmail.dispose();
    _regPassword.dispose();
    _regConfirm.dispose();
    super.dispose();
  }

  // ================= إجراءات المصادقة =================

  Future<void> _handleLogin() async {
    if (_isLoginLoading) return;
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _isLoginLoading = true);
    try {
      await _auth.signInWithEmail(
        email: _loginEmail.text.trim(),
        password: _loginPassword.text.trim(),
      );

      if (!mounted) return;
      // نمرر successMessage لشاشة العملاء
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const CustomerListScreen(
            successMessage: 'تم تسجيل الدخول بنجاح',
          ),
        ),
      );
    } catch (e) {
      _showError(_asNiceMessage(e, fallback: 'تعذّر تسجيل الدخول.'));
    } finally {
      if (mounted) setState(() => _isLoginLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (_isRegLoading) return;
    if (!_regFormKey.currentState!.validate()) return;

    if (_regPassword.text.trim() != _regConfirm.text.trim()) {
      _showError('كلمتا المرور غير متطابقتين');
      return;
    }

    setState(() => _isRegLoading = true);
    try {
      await _auth.signUpWithEmail(
        email: _regEmail.text.trim(),
        password: _regPassword.text.trim(),
      );

      if (!mounted) return;

      // رسالة تنبيه بسيطة عن إرسال التحقق (لو مفعل)
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إنشاء الحساب. إذا لزم، تم إرسال رسالة تفعيل إلى بريدك.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // الانتقال مع successMessage
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const CustomerListScreen(
            successMessage: 'تم إنشاء الحساب بنجاح',
          ),
        ),
      );
    } catch (e) {
      _showError(_asNiceMessage(e, fallback: 'تعذّر إنشاء الحساب.'));
    } finally {
      if (mounted) setState(() => _isRegLoading = false);
    }
  }

  /// إرسال رابط "نسيت كلمة المرور"
  Future<void> _handleForgotPassword() async {
    final email = _loginEmail.text.trim();
    if (email.isEmpty) {
      _showError('الرجاء إدخال البريد الإلكتروني أولاً');
      return;
    }
    try {
      await _auth.resetPassword(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال رابط إعادة التعيين إلى بريدك الإلكتروني'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      _showError(_asNiceMessage(e, fallback: 'تعذّر إرسال الرابط.'));
    }
  }

  // ================= أدوات مساعدة =================

  String _asNiceMessage(Object e, {required String fallback}) {
    // إن كان SimpleAuthException نعرض الرسالة العربية فقط
    if (e is SimpleAuthException) return e.message;
    final txt = e.toString();
    // إزالة البادئات الطويلة المحتملة
    final neat = txt.replaceFirst('Exception: ', '').replaceFirst('FirebaseAuthException:', '').trim();
    return neat.isEmpty ? fallback : neat;
    // ملاحظة: SimpleAuthException مُعرّف داخل auth_service.dart
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // ================= الواجهة =================

  @override
  Widget build(BuildContext context) {
    return Directionality( // ضمان الاتجاه العربي
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          backgroundColor: _primaryColor,
          elevation: 0,
          title: const Text(
            'مرحبًا بك',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 20, color: Colors.white),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: _accentColor,
            tabs: const [
              Tab(child: Text('تسجيل الدخول', style: TextStyle(fontFamily: 'Cairo'))),
              Tab(child: Text('إنشاء حساب',  style: TextStyle(fontFamily: 'Cairo'))),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildLoginTab(),
            _buildRegisterTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _loginFormKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              _buildTextField(
                controller: _loginEmail,
                label: 'البريد الإلكتروني',
                keyboardType: TextInputType.emailAddress,
                validator: _emailValidator,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _loginPassword,
                label: 'كلمة المرور',
                obscureText: _loginObscure,
                suffixIcon: IconButton(
                  icon: Icon(_loginObscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _loginObscure = !_loginObscure),
                ),
                validator: _passwordValidator,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _isLoginLoading ? null : _handleForgotPassword,
                  child: const Text(
                    'نسيت كلمة المرور؟',
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _isLoginLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _handleLogin,
                  child: const Text('تسجيل الدخول', style: TextStyle(fontFamily: 'Cairo')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _regFormKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              _buildTextField(
                controller: _regEmail,
                label: 'البريد الإلكتروني',
                keyboardType: TextInputType.emailAddress,
                validator: _emailValidator,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _regPassword,
                label: 'كلمة المرور',
                obscureText: _regObscure,
                suffixIcon: IconButton(
                  icon: Icon(_regObscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _regObscure = !_regObscure),
                ),
                validator: _passwordValidator,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _regConfirm,
                label: 'تأكيد كلمة المرور',
                obscureText: _regConfirmObscure,
                suffixIcon: IconButton(
                  icon: Icon(_regConfirmObscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _regConfirmObscure = !_regConfirmObscure),
                ),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'أدخل تأكيد كلمة المرور' : null,
              ),
              const SizedBox(height: 24),
              _isRegLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _handleRegister,
                  child: const Text('إنشاء حساب', style: TextStyle(fontFamily: 'Cairo')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====== Validators & TextField ======

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'أدخل البريد الإلكتروني';
    final email = v.trim();
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    return ok ? null : 'صيغة البريد غير صحيحة';
  }

  String? _passwordValidator(String? v) {
    if (v == null || v.trim().length < 6) return 'الحد الأدنى 6 أحرف';
    return null;
  }

  Widget _buildTextField({
    required String label,
    TextEditingController? controller,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Cairo'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: suffixIcon,
      ),
    );
  }
}