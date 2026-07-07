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
    }

    signingConfigs {
        create("release") {
            val keystorePropsFile = rootProject.file("key.properties")
            if (!keystorePropsFile.isFile) {
                throw GradleException("Missing signing config: key.properties not found at ${keystorePropsFile.absolutePath}")
            }
            val lines = keystorePropsFile.readLines()
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
            for (key in required) {
                val value = props[key]
                if (value.isNullOrBlank()) {
                    throw GradleException("Missing required signing property: $key in key.properties")
                }
            }
            storeFile = rootProject.file(props["storeFile"]!!)
            storePassword = props["storePassword"]!!
            keyAlias = props["keyAlias"]!!
            keyPassword = props["keyPassword"]!!
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
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
