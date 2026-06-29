plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.smart_health_hospital"
    
    compileSdk = 36
    buildToolsVersion = "36.0.0"
    
    // 💡 اجعله هكذا تماماً ليطابق ما تبحث عنه الحزمة محلياً
    ndkVersion = "28.2.13676358"
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    @Suppress("DEPRECATION")
    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.smart_health_hospital"
        
        minSdk = 24
        targetSdk = 36 
        
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}