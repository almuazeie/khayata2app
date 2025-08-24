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

/// خدمة المصادقة (Singleton)
class AuthService {
  AuthService._() {
    // اجعل رسائل Firebase (مثل رسائل التحقق) بالعربية
    _auth.setLanguageCode('ar');
  }
  static final AuthService instance = AuthService._();
  factory AuthService() => instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// مراقبة تغيّر حالة المصادقة
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// المستخدم الحالي (إن وجد)
  User? get currentUser => _auth.currentUser;

  /// هل البريد مُفعّل؟
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// تسجيل الدخول بالبريد وكلمة المرور
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return cred;
    } on FirebaseAuthException catch (e) {
      throw SimpleAuthException.fromFirebase(e);
    }
  }

  /// إنشاء حساب جديد بالبريد وكلمة المرور
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

  /// إرسال رابط "نسيت كلمة المرور"
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw SimpleAuthException.fromFirebase(e);
    }
  }

  /// للتوافق القديم
  Future<void> sendPasswordResetEmail(String email) => resetPassword(email);

  /// إرسال رسالة تفعيل البريد للمستخدم الحالي
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

  /// إعادة تحميل بيانات المستخدم (لتحديث حالة التفعيل مثلاً)
  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } on FirebaseAuthException catch (e) {
      throw SimpleAuthException.fromFirebase(e);
    }
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// إعادة المصادقة (ضرورية قبل بعض العمليات الحساسة)
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

  /// تحديث كلمة المرور (قد يتطلب إعادة مصادقة)
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

  /// حذف الحساب (قد يتطلب إعادة مصادقة)
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