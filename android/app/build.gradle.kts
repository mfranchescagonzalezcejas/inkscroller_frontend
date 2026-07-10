plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val googleServicesFiles = listOf(
    "google-services.json",
    "src/dev/google-services.json",
    "src/staging/google-services.json",
    "src/pro/google-services.json",
)

if (googleServicesFiles.any { file(it).isFile }) {
    apply(plugin = "com.google.gms.google-services")
}

// Release signing config — loaded lazily at top level so non-release builds
// (debug, dev, staging) are not blocked when key.properties is absent.
val releaseSigningProps: Map<String, String>? = run {
    val propsFile = rootProject.file("key.properties")
    if (!propsFile.isFile) {
        logger.warn("Release signing disabled: key.properties not found at ${propsFile.absolutePath}")
        null
    } else {
        val lines = propsFile.readLines()
        val props = mutableMapOf<String, String>()
        for (line in lines) {
            val trimmed = line.trim()
            if (trimmed.startsWith("#") || trimmed.isEmpty()) continue
            val eq = trimmed.indexOf('=')
            if (eq > 0) {
                props[trimmed.substring(0, eq).trim()] =
                    trimmed.substring(eq + 1).trim()
            }
        }
        val required = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
        val missing = required.filter { props[it].isNullOrBlank() }
        if (missing.isNotEmpty()) {
            logger.warn("Release signing disabled: missing properties in key.properties: $missing")
            null
        } else if (!rootProject.file(props["storeFile"]!!).isFile) {
            logger.warn("Release signing disabled: keystore not found at ${rootProject.file(props["storeFile"]!!).absolutePath}")
            null
        } else {
            props
        }
    }
}

android {
    namespace = "dev.devdigi.inkscroller"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "dev.devdigi.inkscroller"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Default to dev flavor so `flutter test integration_test/` resolves
        // assembleDevDebug instead of failing on missing assembleDebug.
        missingDimensionStrategy("app", "dev")
    }

    signingConfigs {
        if (releaseSigningProps != null) {
            create("release") {
                storeFile = rootProject.file(releaseSigningProps["storeFile"]!!)
                storePassword = releaseSigningProps["storePassword"]!!
                keyAlias = releaseSigningProps["keyAlias"]!!
                keyPassword = releaseSigningProps["keyPassword"]!!
            }
        }
    }

    buildTypes {
        release {
            releaseSigningProps?.let {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }

    flavorDimensions("app")

    productFlavors {
        create("dev") {
            dimension = "app"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "InkScroller Dev")
        }
        create("staging") {
            dimension = "app"
            applicationIdSuffix = ".stg"
            versionNameSuffix = "-stg"
            resValue("string", "app_name", "InkScroller Stg")

        }
        create("pro") {
            dimension = "app"
            resValue("string", "app_name", "InkScroller")

        }

    }
}

flutter {
    source = "../.."
}
