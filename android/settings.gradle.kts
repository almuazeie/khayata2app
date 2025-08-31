// android/settings.gradle.kts

pluginManagement {
    // يقرأ مسار Flutter SDK من local.properties
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdk = properties.getProperty("flutter.sdk")
        require(flutterSdk != null) { "flutter.sdk not set in local.properties" }
        flutterSdk
    }

    // ضروري لمشاريع Flutter
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        // ✅ مستودع Flutter binaries (مهم للـ flutter_gradle_plugin)
        maven(url = uri("https://storage.googleapis.com/download.flutter.io"))
    }
}

// نُدرج الإضافات (plugins) لمستوى الجذر - التفعيل يكون داخل :app
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.3" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    id("com.google.gms.google-services") version "4.4.3" apply false
    id("com.google.firebase.crashlytics") version "3.0.2" apply false
}

// نُدير المستودعات مركزيًا هنا
dependencyResolutionManagement {
    // ✅ فضّل مستودعات settings ولا تفشل إن وُجدت repos بالمشروع
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
        // نفس مستودع Flutter هنا أيضًا لفضّ التعارضات
        maven(url = uri("https://storage.googleapis.com/download.flutter.io"))
    }
}

rootProject.name = "khayata2app"
include(":app")