plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.accounting_app"
    compileSdk = 36 // الإصدار الذي اخترته

    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.accounting_app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36 // يجب أن يطابق compileSdk لتجنب مشاكل التوافق
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            // إضافة خاصية لضمان عدم حدوث مشاكل في المسارات كما اكتشفنا سابقاً
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}