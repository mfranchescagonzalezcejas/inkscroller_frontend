import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")

if (keyPropertiesFile.exists()) {
    keyPropertiesFile.inputStream().use { keyProperties.load(it) }
}

fun resolveSigningProperty(key: String, envVar: String): String? =
    keyProperties[key]?.toString()?.ifBlank { null } ?: System.getenv(envVar)?.ifBlank { null }

val releaseStoreFilePath = resolveSigningProperty("storeFile", "KEYSTORE_FILE_PATH") ?: "upload-keystore.jks"
val releaseStorePassword = resolveSigningProperty("storePassword", "KEYSTORE_PASSWORD")
val releaseKeyPassword = resolveSigningProperty("keyPassword", "KEY_PASSWORD")
val releaseKeyAlias = resolveSigningProperty("keyAlias", "KEY_ALIAS")
val releaseStoreFile = file(releaseStoreFilePath)

val isReleaseSigningConfigured = listOf(releaseStorePassword, releaseKeyPassword, releaseKeyAlias).all { !it.isNullOrBlank() } &&
    releaseStoreFile.exists()

gradle.taskGraph.whenReady {
    val isReleaseTask = allTasks.any { task ->
        task.path.contains("Release") &&
            (task.name.contains("assemble", ignoreCase = true) ||
                task.name.contains("bundle", ignoreCase = true) ||
                task.name.contains("package", ignoreCase = true) ||
                task.name.contains("install", ignoreCase = true))
    }

    if (isReleaseTask && !isReleaseSigningConfigured) {
        throw GradleException(
            "Release signing is not configured. Provide android/key.properties with storeFile/storePassword/keyPassword/keyAlias " +
                "or set KEYSTORE_FILE_PATH, KEYSTORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD before running release builds."
        )
    }
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
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
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
            keyAlias = releaseKeyAlias ?: "RELEASE_SIGNING_NOT_CONFIGURED"
            keyPassword = releaseKeyPassword ?: "RELEASE_SIGNING_NOT_CONFIGURED"
            storePassword = releaseStorePassword ?: "RELEASE_SIGNING_NOT_CONFIGURED"
            storeFile = releaseStoreFile
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
