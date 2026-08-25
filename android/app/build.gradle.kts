import java.util.Properties
import java.io.FileInputStream
import java.util.Base64

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// Matches `AppEnv.environment` (`--dart-define=APP_ENV=prod|test|uat`).
// Priority: dart-defines → config/app_env.json → config/app_env.default.
fun readDefaultAppEnv(): String {
    val jsonFile = rootProject.file("../config/app_env.json")
    if (jsonFile.exists()) {
        val match = Regex(""""APP_ENV"\s*:\s*"(\w+)"""").find(jsonFile.readText())
        if (match != null) return match.groupValues[1]
    }
    val configFile = rootProject.file("../config/app_env.default")
    if (configFile.exists()) {
        val value = configFile.readText().trim()
        if (value.isNotEmpty()) return value
    }
    return "test"
}

fun resolveAppEnv(): String {
    val dartDefines = project.findProperty("dart-defines") as String?
    if (dartDefines != null) {
        for (encoded in dartDefines.split(",")) {
            if (encoded.isBlank()) continue
            try {
                val decoded = String(Base64.getDecoder().decode(encoded), Charsets.UTF_8)
                val separator = decoded.indexOf('=')
                if (separator <= 0) continue
                val key = decoded.substring(0, separator)
                val value = decoded.substring(separator + 1)
                if (key == "APP_ENV") return value
            } catch (_: IllegalArgumentException) {
                // Ignore malformed dart-define entries.
            }
        }
    }
    return readDefaultAppEnv()
}

val prodGoogleServicesFile = file("google-services.prod.json")
val testGoogleServicesFile = file("google-services(test).json")
val activeGoogleServicesFile = file("google-services.json")

tasks.register("selectGoogleServicesJson") {
    doLast {
        val source = if (resolveAppEnv() == "prod") {
            prodGoogleServicesFile
        } else {
            testGoogleServicesFile
        }
        check(source.exists()) {
            "Missing Firebase config for APP_ENV=${resolveAppEnv()}: ${source.path}"
        }
        source.copyTo(activeGoogleServicesFile, overwrite = true)
    }
}

tasks.named("preBuild").configure {
    dependsOn("selectGoogleServicesJson")
}

// Load keystore properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.satya_devotte_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    defaultConfig {
         applicationId = if (resolveAppEnv() == "prod") {
        "com.satya_devotte_app"
    } else {
        "com.developer.sathya"
    }
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("release") {
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation(platform("com.google.firebase:firebase-bom:34.12.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.android.play:app-update-ktx:2.1.0")
}