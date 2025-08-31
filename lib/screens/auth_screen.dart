import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'customer_list_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  // تبويبان فقط: تسجيل الدخول / إنشاء حساب
  late final TabController _tabController;
  final _auth = AuthService();

  // ألوان محسّنة
  static const _bg = Color(0xFFF3F6FB);
  static const _primary = Color(0xFF1A237E); // أزرق داكن
  static const _accent = Color(0xFF2962FF);  // أزرق واضح للأزرار
  static const _fieldBg = Colors.white;

  // ========= الحقول المشتركة =========
  final _idLogin = TextEditingController(); // بريد أو جوال
  final _passLogin = TextEditingController();
  final _otpLogin = TextEditingController();

  final _idReg = TextEditingController();   // بريد أو جوال
  final _passReg = TextEditingController();
  final _confirmReg = TextEditingController();
  final _otpReg = TextEditingController();

  // حالات عرض/تحميل
  bool _loginLoading = false;
  bool _regLoading = false;

  bool _loginObscure = true;
  bool _regObscure = true;
  bool _regConfirmObscure = true;

  // OTP حالات
  bool _loginCodeSent = false;
  bool _regCodeSent = false;
  PhoneAuthSession? _loginSession;
  PhoneAuthSession? _regSession;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();

    _idLogin.dispose();
    _passLogin.dispose();
    _otpLogin.dispose();

    _idReg.dispose();
    _passReg.dispose();
    _confirmReg.dispose();
    _otpReg.dispose();
    super.dispose();
  }

  // ================= أدوات مساعدة صغيرة =================
  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ));
  }

  String _nice(Object e, String fallback) {
    if (e is SimpleAuthException) return e.message;
    if (e is FirebaseAuthException && (e.message ?? '').trim().isNotEmpty) {
      return e.message!;
    }
    final t = e.toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('FirebaseAuthException:', '')
        .trim();
    return t.isEmpty ? fallback : t;
  }

  bool _looksLikeEmail(String v) => _auth.isEmail(v);
  bool _looksLikePhone(String v) => _auth.isLikelyPhone(v);

  // =========================== تسجيل الدخول ===========================

  Future<void> _onLoginPressed() async {
    final id = _idLogin.text.trim();

    if (_looksLikeEmail(id)) {
      // بريد + كلمة مرور
      if (_passLogin.text.trim().length < 6) {
        _toast('أدخل كلمة المرور (6 أحرف على الأقل)');
        return;
      }
      setState(() => _loginLoading = true);
      try {
        await _auth.signInWithEmail(email: id, password: _passLogin.text.trim());
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => const CustomerListScreen(successMessage: 'تم تسجيل الدخول'),
        ));
      } catch (e) {
        _toast(_nice(e, 'تعذر تسجيل الدخول.'));
      } finally {
        if (mounted) setState(() => _loginLoading = false);
      }
      return;
    }

    if (_looksLikePhone(id)) {
      // جوال + OTP (زر واحد: إرسال ثم تأكيد)
      if (!_loginCodeSent) {
        setState(() => _loginLoading = true);
        try {
          _loginSession = await _auth.requestSmsCode(id);
          _loginCodeSent = true;
          _toast('تم إرسال كود التحقق عبر SMS');
        } catch (e) {
          _toast(_nice(e, 'تعذر إرسال الكود.'));
        } finally {
          if (mounted) setState(() => _loginLoading = false);
        }
      } else {
        // تأكيد
        final code = _otpLogin.text.trim();
        if (code.length < 4) {
          _toast('أدخل كود التحقق الصحيح');
          return;
        }
        setState(() => _loginLoading = true);
        try {
          await _auth.confirmSmsCode(
            verificationId: _loginSession!.verificationId,
            smsCode: code,
          );
          if (!mounted) return;
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => const CustomerListScreen(successMessage: 'تم تسجيل الدخول برقم الجوال'),
          ));
        } catch (e) {
          _toast(_nice(e, 'كود التحقق غير صحيح.'));
        } finally {
          if (mounted) setState(() => _loginLoading = false);
        }
      }
      return;
    }

    _toast('أدخل بريدًا إلكترونيًا صحيحًا أو رقم جوال بصيغة دولية (مثل +9665xxxxxxx).');
  }

  // “نسيت كلمة المرور” — بريد ➜ رابط، جوال ➜ OTP (نفس زر الدخول)
  Future<void> _onForgotPressed() async {
    final id = _idLogin.text.trim();
    if (_looksLikeEmail(id)) {
      try {
        await _auth.resetPassword(id);
        _toast('تم إرسال رابط إعادة التعيين إلى بريدك الإلكتروني');
      } catch (e) {
        _toast(_nice(e, 'تعذر إرسال الرابط.'));
      }
    } else if (_looksLikePhone(id)) {
      // نتعامل معها كـ دخول سريع بالـ OTP
      _loginCodeSent = false; // نعيد الحالة لبداية الإرسال
      await _onLoginPressed();
    } else {
      _toast('أدخل بريدك أو رقم جوالك أولاً.');
    }
  }

  // =========================== إنشاء حساب ===========================

  Future<void> _onRegisterPressed() async {
    final id = _idReg.text.trim();

    if (_looksLikeEmail(id)) {
      if (_passReg.text.trim().length < 6) {
        _toast('كلمة المرور ضعيفة (الحد الأدنى 6).');
        return;
      }
      if (_passReg.text.trim() != _confirmReg.text.trim()) {
        _toast('كلمتا المرور غير متطابقتين');
        return;
      }
      setState(() => _regLoading = true);
      try {
        await _auth.signUpWithEmail(
          email: id,
          password: _passReg.text.trim(),
        );
        _toast('تم إنشاء الحساب. قد تصلك رسالة تفعيل على بريدك.');
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => const CustomerListScreen(successMessage: 'تم إنشاء الحساب بنجاح'),
        ));
      } catch (e) {
        _toast(_nice(e, 'تعذر إنشاء الحساب.'));
      } finally {
        if (mounted) setState(() => _regLoading = false);
      }
      return;
    }

    if (_looksLikePhone(id)) {
      // عند الجوال، “إنشاء حساب” عمليًا هو أول تسجيل دخول بالـ OTP
      if (!_regCodeSent) {
        setState(() => _regLoading = true);
        try {
          _regSession = await _auth.requestSmsCode(id);
          _regCodeSent = true;
          _toast('تم إرسال كود التحقق عبر SMS');
        } catch (e) {
          _toast(_nice(e, 'تعذر إرسال الكود.'));
        } finally {
          if (mounted) setState(() => _regLoading = false);
        }
      } else {
        final code = _otpReg.text.trim();
        if (code.length < 4) {
          _toast('أدخل كود التحقق الصحيح');
          return;
        }
        setState(() => _regLoading = true);
        try {
          await _auth.confirmSmsCode(
            verificationId: _regSession!.verificationId,
            smsCode: code,
          );
          if (!mounted) return;
          _toast('تم إنشاء الحساب/الدخول برقم الجوال');
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => const CustomerListScreen(successMessage: 'مرحبًا بك'),
          ));
        } catch (e) {
          _toast(_nice(e, 'كود التحقق غير صحيح.'));
        } finally {
          if (mounted) setState(() => _regLoading = false);
        }
      }
      return;
    }

    _toast('أدخل بريدًا صحيحًا أو رقم جوال دولي (مثل +9665xxxxxxx).');
  }

  // ============================ واجهة المستخدم ============================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _primary,
          elevation: 0,
          title: const Text(
            'مرحبًا بك',
            style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(child: Text('تسجيل الدخول', style: TextStyle(fontFamily: 'Cairo'))),
              Tab(child: Text('إنشاء حساب', style: TextStyle(fontFamily: 'Cairo'))),
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
    final id = _idLogin.text.trim();
    final isEmail = _looksLikeEmail(id);
    final isPhone = _looksLikePhone(id);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _field(
              controller: _idLogin,
              label: 'أدخل بريدك الإلكتروني أو رقم جوالك',
              prefix: const Icon(Icons.person),
              onChanged: (_) => setState(() {}), // لتحديث إظهار كلمة المرور/OTP
            ),
            const SizedBox(height: 12),
            if (isEmail)
              _field(
                controller: _passLogin,
                label: 'كلمة المرور',
                obscure: _loginObscure,
                prefix: const Icon(Icons.lock),
                suffix: IconButton(
                  icon: Icon(_loginObscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _loginObscure = !_loginObscure),
                ),
              ),
            if (isPhone && _loginCodeSent) ...[
              const SizedBox(height: 12),
              _field(
                controller: _otpLogin,
                label: 'كود التحقق (SMS)',
                keyboard: TextInputType.number,
                prefix: const Icon(Icons.sms),
              ),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _loginLoading ? null : _onForgotPressed,
                child: const Text('نسيت كلمة المرور؟', style: TextStyle(fontFamily: 'Cairo')),
              ),
            ),
            const SizedBox(height: 12),
            _loginLoading
                ? const CircularProgressIndicator()
                : SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _onLoginPressed,
                child: Text(
                  isPhone
                      ? (_loginCodeSent ? 'تأكيد الكود' : 'إرسال كود الدخول')
                      : 'تسجيل الدخول',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterTab() {
    final id = _idReg.text.trim();
    final isEmail = _looksLikeEmail(id);
    final isPhone = _looksLikePhone(id);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _field(
              controller: _idReg,
              label: 'بريد إلكتروني أو رقم جوال',
              prefix: const Icon(Icons.person_add),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            if (isEmail) ...[
              _field(
                controller: _passReg,
                label: 'كلمة المرور',
                obscure: _regObscure,
                prefix: const Icon(Icons.lock_outline),
                suffix: IconButton(
                  icon: Icon(_regObscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _regObscure = !_regObscure),
                ),
              ),
              const SizedBox(height: 12),
              _field(
                controller: _confirmReg,
                label: 'تأكيد كلمة المرور',
                obscure: _regConfirmObscure,
                prefix: const Icon(Icons.verified_user),
                suffix: IconButton(
                  icon: Icon(_regConfirmObscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _regConfirmObscure = !_regConfirmObscure),
                ),
              ),
            ],
            if (isPhone && _regCodeSent) ...[
              const SizedBox(height: 12),
              _field(
                controller: _otpReg,
                label: 'كود التحقق (SMS)',
                keyboard: TextInputType.number,
                prefix: const Icon(Icons.sms),
              ),
            ],
            const SizedBox(height: 12),
            _regLoading
                ? const CircularProgressIndicator()
                : SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _onRegisterPressed,
                child: Text(
                  isPhone
                      ? (_regCodeSent ? 'تأكيد الكود' : 'إرسال كود الإنشاء')
                      : 'إنشاء حساب',
                  style: const TextStyle(fontFamily: 'Cairo', fontSize: 16, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'عند اختيار رقم الجوال، سيتم إنشاء الحساب بعد التحقق بالـ OTP.',
              style: TextStyle(fontFamily: 'Cairo', color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ============================ Widgets مشتركة ============================

  Widget _field({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboard,
    bool obscure = false,
    Widget? prefix,
    Widget? suffix,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Cairo'),
        filled: true,
        fillColor: _fieldBg,
        prefixIcon: prefix,
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD9E1F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 1.4),
        ),
      ),
    );
  }
}