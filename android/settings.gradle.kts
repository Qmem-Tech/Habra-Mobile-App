pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    // Keep every Kotlin-using module on the same KGP so dependencies like
    // android-maps-utils:4.1.0 (Kotlin 2.3 metadata) compile cleanly in release.
    resolutionStrategy {
        eachPlugin {
            val id = requested.id.id
            if (id == "org.jetbrains.kotlin.android" ||
                id == "org.jetbrains.kotlin.jvm" ||
                id == "kotlin-android"
            ) {
                useVersion("2.3.21")
            }
        }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.21" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")
