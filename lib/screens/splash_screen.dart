import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart' as crash; // اختياري لوج
import 'auth_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _navigated = false; // يمنع تكرار الانتقال

  @override
  void initState() {
    super.initState();

    // لوج اختياري في Crashlytics يفيد بالتتبّع
    try {
      crash.FirebaseCrashlytics.instance.setCustomKey('screen', 'Splash');
      crash.FirebaseCrashlytics.instance.log('SplashScreen opened');
    } catch (_) {
      // تجاهل لو Crashlytics غير مفعّل
    }

    // ⏳ الانتقال بعد 3 ثوانٍ إلى شاشة تسجيل الدخول
    _timer = Timer(const Duration(seconds: 3), _goNext);
  }

  void _goNext() {
    if (!mounted || _navigated) return;
    _navigated = true;

    // أبقينا نفس السلوك القديم (تقدر تستخدم الراوت المسمّى إن حبيت)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      // أو:
      // Navigator.of(context).pushReplacementNamed('/auth');
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // منع الرجوع من شاشة السلاش
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9), // رمادي فاتح جدًا
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.design_services, size: 90, color: Colors.blue),
              SizedBox(height: 20),
              Text(
                'تطبيق الخياطة',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 10),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}