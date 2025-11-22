// ✅ CRITICAL: Required imports for signing configuration
import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "sutodero.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "sutodero.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23 // Requerido por firebase_auth
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // ✅ CRITICAL: Enable multidex support for Firebase
        // Firebase requires more than 65,536 methods
        multiDexEnabled = true
    }

    // ✅ CRITICAL: Configure signing with release keystore
    signingConfigs {
        create("release") {
            // Codemagic CI environment variables
            storeFile = System.getenv("CM_KEYSTORE_PATH")?.let { file(it) }
                ?: file("../../sutodero-release.jks")
            storePassword = System.getenv("CM_KEYSTORE_PASSWORD") ?: "Perro2011"
            keyAlias = System.getenv("CM_KEY_ALIAS") ?: "sutodero"
            keyPassword = System.getenv("CM_KEYSTORE_PASSWORD") ?: "Perro2011"
        }
    }

    buildTypes {
        release {
            // ✅ Sign with release keystore instead of debug keys
            signingConfig = signingConfigs.getByName("release")
            
            // ⚠️ MINIFICACIÓN DESHABILITADA para evitar problemas con Firebase
            // La minificación agresiva puede remover código de Firebase que se necesita en runtime
            isMinifyEnabled = false
            // Recursos se mantienen para evitar problemas de carga
            isShrinkResources = false
        }
    }
}

dependencies {
    // ✅ CRITICAL: Multidex support for Firebase
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}
