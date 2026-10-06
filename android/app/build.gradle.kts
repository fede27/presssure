import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Upload key for Play (android/key.properties, not in git).
val keyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

android {
    namespace = "com.fscarel.presssure"
    // 37: permission_handler needs it to compile; the target SDK is unchanged.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.fscarel.presssure"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appLabel"] = "PressSure"
    }

    signingConfigs {
        if (keyProperties.isNotEmpty()) {
            create("release") {
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
                storeFile = file(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        // Development builds are a separate app next to the real one: tests,
        // the OCR benchmark and `flutter run` never touch the real diary.
        debug {
            applicationIdSuffix = ".debug"
            manifestPlaceholders["appLabel"] = "PressSure dev"
        }
        release {
            // Without key.properties (e.g. a fresh clone) the release build
            // falls back to the debug key, so `flutter run --release` works.
            signingConfig = signingConfigs.findByName("release")
                ?: signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Required by flutter_local_notifications for scheduled reminders.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // TensorFlow Lite runtime for tflite_flutter, built from source without
    // proprietary dependencies (https://github.com/egdels/LiteRT, Apache-2.0).
    // Replaces Google's LiteRT AARs, excluded in ../build.gradle.kts. Not an
    // official Google build: check the OCR benchmark (tool/ocr_bench) after
    // every bump. Newer patch releases are listed on Maven Central.
    implementation("de.schliweb:tensorflow-lite-fdroid:1.4.1-fdroid")
    testImplementation("junit:junit:4.13.2")
}
