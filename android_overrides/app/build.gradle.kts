import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.itschool.mathbuddies"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.itschool.mathbuddies"
        minSdk = 22
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // --- Release signing from key.properties (rule C) ---
    // All vals live INSIDE android {} (rule J7). Build fails loudly if missing.
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (!keystorePropertiesFile.exists()) {
        throw GradleException(
            "key.properties NOT FOUND at android/key.properties. " +
                "CI creates it from GitHub Secrets; locally copy it from your signing kit."
        )
    }
    val keystoreProperties = Properties()
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile =
                keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            // Amazon does NOT re-sign: release must use the private release key.
            signingConfig = signingConfigs.getByName("release")
            // Keep R8/shrinking OFF (lesson K3: reflection-based SDKs break).
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
