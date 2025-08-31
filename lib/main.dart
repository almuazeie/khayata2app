import 'dart:async';
import 'dart:ui'; // لـ PlatformDispatcher.instance.onError

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // ✅ App Check

// Screens
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/customer_list_screen.dart';

// ✅ استورد ملف FlutterFire المولّد
import 'firebase_options.dart';

/// مفاتيح عامة للتنقل وإظهار الرسائل من أي مكان
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ تهيئة Firebase (كما هي)
  if (kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    await Firebase.initializeApp();
  }

  // ✅ تفعيل/تأكيد الـ Offline Persistence لـ Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  // ✅ App Check — Play Integrity لأندرويد / DeviceCheck للـ iOS
  // (مغلفة بـ try لئلا تعيق التشغيل على المنصّات غير المدعومة)
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.deviceCheck,
      // على الويب يمكنك لاحقًا استخدام ReCaptchaV3/Enterprise بمفتاح من الكونسول.
      // webProvider: ReCaptchaV3Provider('YOUR_RECAPTCHA_KEY'),
    );
  } catch (_) {
    // نتجاهل أي خطأ تهيئة هنا حتى لا يمنع التشغيل أثناء التطوير
  }

  // =================== Crashlytics ===================
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

  // التقاط أخطاء Flutter غير الممسوكة
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

  // التقاط الأخطاء العامة/غير المتزامنة
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // تشغيل التطبيق داخل runZonedGuarded لالتقاط أي استثناءات إضافية
  runZonedGuarded(
        () => runApp(const MyApp()),
        (error, stack) =>
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تطبيق الخياطة',
      debugShowCheckedModeBanner: false,

      // ✅ مفاتيح عامة تضمن ظهور SnackBars/Dialogs دائماً
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appScaffoldMessengerKey,

      theme: ThemeData(
        fontFamily: 'Cairo',
        primarySwatch: Colors.blue,
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),

      // ✅ دعم العربية
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ar', ''), // Arabic
        Locale('en', ''), // English
      ],
      locale: const Locale('ar'),

      // ✅ شاشة البداية
      home: const SplashScreen(),

      // ✅ Routes
      routes: {
        '/auth': (_) => const AuthScreen(),
        '/home': (_) => const CustomerListScreen(),
      },

      // ✅ (اختياري) بوابة المصادقة
      // home: StreamBuilder<User?>(
      //   stream: FirebaseAuth.instance.authStateChanges(),
      //   builder: (context, snap) {
      //     if (snap.connectionState == ConnectionState.waiting) {
      //       return const SplashScreen();
      //     }
      //     return snap.hasData ? const CustomerListScreen() : const AuthScreen();
      //   },
      // ),
    );
  }
}