plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.pos_transfer_module"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Corrected syntax: properties are set with '='
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11

        // FIX: Replaced 'coreLibraryDesugaringEnabled true' with the Kotlin DSL equivalent.
        // Also ensuring Java 17 is set here for modern features/desugaring compatibility.
        // 'isCoreLibraryDesugaringEnabled' must be set using the assignment operator.
        isCoreLibraryDesugaringEnabled = true

        // FIX: The second compileOptions block was redundant, combining settings here:
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString() // Set to match the compileOptions
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.pos_transfer_module"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // The redundant compileOptions block that contained the syntax errors has been removed.

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // your other dependencies...

    // FIX: Replaced 'coreLibraryDesugaring '...' ' with the Kotlin DSL function call.
    // Use parentheses and double quotes for the dependency string.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}