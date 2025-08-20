import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/customer_list_screen.dart';

/// مفاتيح عامة للتنقل وإظهار الرسائل من أي مكان
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ تهيئة Firebase قبل تشغيل التطبيق
  await Firebase.initializeApp();

  runApp(const MyApp());
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

      // ✅ (اختياري) بوابة المصادقة بدل SplashScreen
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