// lib/services/auth_service.dart
import 'dart:async'; // ✅ لازم لـ Completer/Timer
import 'package:firebase_auth/firebase_auth.dart';

/// استثناء مبسّط برسالة عربية مفهومة
class SimpleAuthException implements Exception {
  final String code;
  final String message;
  const SimpleAuthException(this.code, this.message);

  @override
  String toString() => '[$code] $message';

  /// تحويل أخطاء FirebaseAuth إلى رسائل عربية
  factory SimpleAuthException.fromFirebase(FirebaseAuthException e) {
    final code = e.code;
    String msg;
    switch (code) {
      case 'invalid-email':
        msg = 'صيغة البريد الإلكتروني غير صحيحة.';
        break;
      case 'user-disabled':
        msg = 'تم إيقاف هذا الحساب.';
        break;
      case 'user-not-found':
        msg = 'لا يوجد مستخدم بهذا البريد.';
        break;
      case 'wrong-password':
        msg = 'كلمة المرور غير صحيحة.';
        break;
      case 'email-already-in-use':
        msg = 'هذا البريد مستخدم بالفعل.';
        break;
      case 'weak-password':
        msg = 'كلمة المرور ضعيفة، اختر كلمة أقوى.';
        break;
      case 'too-many-requests':
        msg = 'محاولات كثيرة. يرجى المحاولة لاحقًا.';
        break;
      case 'operation-not-allowed':
        msg = 'طريقة تسجيل الدخول هذه غير مفعلة في الإعدادات.';
        break;
      case 'missing-email':
        msg = 'يرجى إدخال البريد الإلكتروني.';
        break;
      case 'invalid-continue-uri':
        msg = 'رابط المتابعة غير صالح.';
        break;
      case 'missing-android-pkg-name':
        msg = 'اسم حزمة أندرويد مفقود في إعدادات الرابط.';
        break;

    // أخطاء شائعة في مصادقة الجوال
      case 'invalid-phone-number':
        msg = 'رقم الجوال غير صالح. أدخل الرقم بصيغة دولية مثل +9665xxxxxxx.';
        break;
      case 'invalid-verification-code':
        msg = 'رمز التحقق غير صحيح.';
        break;
      case 'session-expired':
        msg = 'انتهت صلاحية رمز التحقق. أعد إرسال الرمز.';
        break;
      case 'quota-exceeded':
        msg = 'تم تجاوز حد الرسائل مؤقتًا. حاول لاحقًا.';
        break;
      case 'captcha-check-failed':
        msg = 'فشل التحقق الأمني. أعد المحاولة.';
        break;

    // حالات شائعة أخرى
      case 'network-request-failed':
        msg = 'لا يوجد اتصال بالإنترنت.';
        break;
      case 'requires-recent-login':
        msg = 'نحتاج لإعادة تسجيل الدخول قبل تنفيذ هذا الإجراء.';
        break;
      default:
        msg = e.message ?? 'حدث خطأ غير متوقع.';
    }
    return SimpleAuthException(code, msg);
  }
}

/// جلسة مصادقة الجوال بعد إرسال الرمز (تفيد في تأكيد الـ OTP)
class PhoneAuthSession {
  final String verificationId;
  final int? resendToken;
  const PhoneAuthSession(this.verificationId, this.resendToken);
}

/// خدمة المصادقة (Singleton)
class AuthService {
  AuthService._() {
    // اجعل رسائل Firebase (مثل رسائل التحقق) بالعربية
    _auth.setLanguageCode('ar');
  }
  static final AuthService instance = AuthService._();
  factory AuthService() => instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ===================== Helpers للكشف/التهيئة =====================

  static final RegExp _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _digitsRe = RegExp(r'^\d{8,15}$');
  static final RegExp _intlPhoneRe = RegExp(r'^\+\d{6,15}$');

  /// هل النص بريد؟
  bool isEmail(String v) => _emailRe.hasMatch(v.trim());

  /// هل النص يبدو رقم جوال؟ (صيغة دولية +أرقام أو أرقام فقط بطول مناسب)
  bool isLikelyPhone(String v) {
    final s = v.trim().replaceAll(' ', '');
    return _intlPhoneRe.hasMatch(s) || _digitsRe.hasMatch(s);
  }

  /// تطبيع رقم الجوال لصيغة E.164 مبسّطة.
  /// مثال للسعودية: 05xxxxxxxx → +9665xxxxxxxx
  String normalizePhone(String raw, {String defaultCountryDialCode = '+966'}) {
    String s = raw.trim().replaceAll(RegExp(r'\s+'), '');
    if (s.startsWith('+')) return s;              // مسبقًا دولي
    if (s.startsWith('00')) return '+${s.substring(2)}';
    if (s.startsWith('05')) return '$defaultCountryDialCode${s.substring(1)}';
    if (s.startsWith('5'))  return '$defaultCountryDialCode$s';
    return '$defaultCountryDialCode$s';
  }

  // ===================== مراقبة الحالة =====================

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // ===================== البريد/كلمة المرور =====================

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw SimpleAuthException.fromFirebase(e);
    }
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    bool sendEmailVerification = true,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (sendEmailVerification) {
        await cred.user?.sendEmailVerification();
      }
      return cred;
    } on FirebaseAuthException catch (e) {
      throw SimpleAuthException.fromFirebase(e);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw SimpleAuthException.fromFirebase(e);
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw const SimpleAuthException('no-user', 'لا يوجد مستخدم مسجّل حاليًا.');
      }
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw SimpleAuthException.fromFirebase(e);
    }
  }

  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } on FirebaseAuthException catch (e) {
      throw SimpleAuthException.fromFirebase(e);
    }
  }

  // ===================== الجوال / OTP =====================

  /// يرسل SMS ويُرجع بيانات الجلسة (verificationId + token لإعادة الإرسال).
  Future<PhoneAuthSession> requestSmsCode(
      String rawPhone, {
        int? forceResendingToken,
        Duration timeout = const Duration(seconds: 60),
      }) async {
    final phone = normalizePhone(rawPhone);
    try {
      String? vId;
      int? resend;
      final completer = Completer<PhoneAuthSession>();

      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: timeout,
        forceResendingToken: forceResendingToken,
        verificationCompleted: (PhoneAuthCredential cred) async {
          // قد يتم التحقق التلقائي — نحاول تسجيل الدخول مباشرة
          try {
            await _auth.signInWithCredential(cred);
            // نكمل الجلسة حتى لو تم الدخول تلقائياً
            if (!completer.isCompleted) {
              completer.complete(PhoneAuthSession('auto', resend));
            }
          } catch (e) {
            if (!completer.isCompleted) {
              completer.completeError(SimpleAuthException('auto-verify-failed', e.toString()));
            }
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!completer.isCompleted) {
            completer.completeError(SimpleAuthException.fromFirebase(e));
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          vId = verificationId;
          resend = resendToken;
          if (!completer.isCompleted) {
            completer.complete(PhoneAuthSession(vId!, resend));
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          vId ??= verificationId;
          if (!completer.isCompleted) {
            completer.complete(PhoneAuthSession(vId!, resend));
          }
        },
      );

      return await completer.future;
    } on FirebaseAuthException catch (e) {
      throw SimpleAuthException.fromFirebase(e);
    }
  }

  /// تأكيد رمز الـ SMS وتسجيل الدخول
  Future<UserCredential> confirmSmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      return await _auth.signInWithCredential(cred);
    } on FirebaseAuthException catch (e) {
      throw SimpleAuthException.fromFirebase(e);
    }
  }

  /// (اختياري) تحديث اسم العرض بعد نجاح الدخول بالجوال
  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await user.updateDisplayName(name.trim());
  }

  // ===================== عمليات عامة =====================

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> reauthenticate({
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const SimpleAuthException('no-user', 'لا يوجد مستخدم مسجّل حاليًا.');
    }
    try {
      final cred = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );
      await user.reauthenticateWithCredential(cred);
    } on FirebaseAuthException catch (e) {
      throw SimpleAuthException.fromFirebase(e);
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw const SimpleAuthException('no-user', 'لا يوجد مستخدم مسجّل حاليًا.');
      }
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw SimpleAuthException.fromFirebase(e);
    }
  }

  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw const SimpleAuthException('no-user', 'لا يوجد مستخدم مسجّل حاليًا.');
      }
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw SimpleAuthException.fromFirebase(e);
    }
  }
}