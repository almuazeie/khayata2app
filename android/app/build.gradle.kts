// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    // في مشاريع KTS الحديثة نستخدم:
    id("org.jetbrains.kotlin.android")
    // يجب أن يأتي بعد Android و Kotlin
    id("dev.flutter.flutter-gradle-plugin")
    // Google Services لتفعيل تكوين Firebase (google-services.json)
    id("com.google.gms.google-services")
    // Crashlytics (تجميع تقارير الأعطال)
    id("com.google.firebase.crashlytics")
}

android {
    namespace = "com.example.khayata2app"

    // هذه القيم يزودها Flutter من pubspec/gradle
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.khayata2app"

        // حد أدنى موصى به لـ Firebase SDKs الحديثة
        minSdk = 23

        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // (اختياري) إن كان لديك مفتاح خرائط
        manifestPlaceholders["MAPS_API_KEY"] =
            (project.findProperty("MAPS_API_KEY") ?: "") as String
    }

    buildTypes {
        release {
            // توقيع debug مؤقتًا للتجربة (بدّلها عندما تُنشئ keystore للإصدار)
            signingConfig = signingConfigs.getByName("debug")

            // (اختياري) تفعيل تقليص الحجم إن رغبت لاحقًا
            // isMinifyEnabled = true
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
    }

    // مع AGP 8+ يفضَّل Java 17
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
}

flutter {
    source = "../.."
}

// ملاحظات:
// - لا نضيف أي repositories هنا؛ تُدار مركزيًا في settings.gradle.kts
// - الاعتمادات (firebase_core, firebase_auth, cloud_firestore, firebase_crashlytics, …)
//   يحمّلها Flutter من pubspec.yaml تلقائيًا.