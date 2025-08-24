plugins {
    id("com.android.application")
    id("kotlin-android")
    // يجب أن يأتي بعد Android و Kotlin
    id("dev.flutter.flutter-gradle-plugin")
    // Google Services لتفعيل Firebase على الأندرويد
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.khayata2app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.khayata2app"
        // >>> حل المشكلة: ارفع الحد الأدنى إلى 23
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName


        manifestPlaceholders["MAPS_API_KEY"] =
            (project.findProperty("MAPS_API_KEY") ?: "") as String    }

    buildTypes {
        release {
            // مؤقتًا نوقّع بمفاتيح الـ debug لتجربة الإصدار
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }
}

flutter {
    source = "../.."
}

// لا حاجة لإضافة BoM أو dependencies هنا عند استخدام FlutterFire عبر pubspec
// سيقوم Flutter بإدارة الاعتمادات تلقائيًا بناءً على حِزم Dart (firebase_core, firebase_auth, ...).