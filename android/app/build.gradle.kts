import java.io.File
import java.io.FileInputStream
import java.util.Properties
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// FCM: only apply when google-services.json is present (run `flutterfire configure` or add file from Firebase Console).
val googleServicesJson = file("google-services.json")
if (googleServicesJson.exists()) {
    apply(plugin = "com.google.gms.google-services")
}

/** Reads repo-root `dart_defines.json` so the Maps key stays centralized with Flutter defines. */
fun loadGoogleMapsApiKeyFromDartDefines(projectRoot: File): String {
    val f = File(projectRoot, "dart_defines.json")
    if (!f.exists()) return ""
    val text =
        try {
            f.readText()
        } catch (_: Exception) {
            return ""
        }
    fun extract(key: String): String {
        val re = Regex(""""$key"\s*:\s*"([^"]*)"""")
        return re.find(text)?.groupValues?.getOrNull(1).orEmpty()
    }
    return extract("GOOGLE_MAPS_API_KEY").ifEmpty { extract("MAPS_SDK_API_KEY") }
}

android {
    namespace = "com.habra.habra"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.habra.habra"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        val mapsKey = loadGoogleMapsApiKeyFromDartDefines(rootProject.projectDir.parentFile)
        manifestPlaceholders["GOOGLE_MAPS_API_KEY"] = mapsKey
    }

    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = Properties()
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(FileInputStream(keystorePropertiesFile))
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")!!
                keyPassword = keystoreProperties.getProperty("keyPassword")!!
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile")!!)
                storePassword = keystoreProperties.getProperty("storePassword")!!
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            // Include app-level shrinker rules for release builds.
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_11)
    }
}

flutter {
    source = "../.."
}

dependencies {
    // App uses Supabase for backend; no Firebase dependencies.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
