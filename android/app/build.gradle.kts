import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Load API keys and signing configuration from properties file
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(keystorePropertiesFile.inputStream())
}
val isReleaseTask = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
val mapsApiKey = keystoreProperties.getProperty("mapsApiKey", "")
fun resolveProjectKeystore(path: String): File {
    val normalized = path.trim()
    val candidate = rootProject.file(normalized)
    if (candidate.exists()) return candidate
    val repoRootCandidate = rootProject.file("../$normalized")
    return repoRootCandidate
}

android {
    namespace = "com.wordnerd.artbeat"
    compileSdk = 36  // Updated for latest plugin compatibility
    ndkVersion = "28.2.13676358"

    buildFeatures {
        buildConfig = true
    }

    // Add build optimization
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
        isCoreLibraryDesugaringEnabled = true
    }

    // Setup signing configuration for release builds
    signingConfigs {
        create("localDebug") {
            val localDebugKeystore = resolveProjectKeystore("debug.keystore")
            if (localDebugKeystore.exists()) {
                storeFile = localDebugKeystore
                storePassword = "android"
                keyAlias = "androiddebugkey"
                keyPassword = "android"
            } else {
                logger.warn("Local debug.keystore not found at project root; falling back to default debug signing.")
            }
        }
        create("release") {
            val keystoreFile = keystoreProperties.getProperty("storeFile")?.let { 
                resolveProjectKeystore(it)
            }
            if (keystoreFile != null && keystoreFile.exists()) {
                storeFile = keystoreFile
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias") 
                keyPassword = keystoreProperties.getProperty("keyPassword")
            } else {
                logger.warn("Release signing config not found - using debug signing")
            }
        }
    }

    defaultConfig {
        // ARTbeat application ID
        applicationId = "com.wordnerd.artbeat"
        minSdk = 24  // Android 7.0 (2016) - Explicit minimum for Firebase compatibility
        targetSdk = 36  // Updated to match compileSdk
        versionCode = 134
        versionName = "2.7.2"
        
        // Enable multidex for large app
        multiDexEnabled = true
        
        // Pass API keys to the build
        manifestPlaceholders["mapsApiKey"] = mapsApiKey
        
        // Override manifest attributes for plugins with incompatible minSdk
        manifestPlaceholders["minSdkVersion"] = 24

        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64")
        }
    }

    buildTypes {
        release {
            // Robust check for release signing config
            val hasReleaseKeystore = keystoreProperties.getProperty("storeFile") != null &&
                keystoreProperties.getProperty("storePassword") != null &&
                keystoreProperties.getProperty("keyAlias") != null &&
                keystoreProperties.getProperty("keyPassword") != null &&
                resolveProjectKeystore(keystoreProperties.getProperty("storeFile")).exists()
            if (isReleaseTask && !hasReleaseKeystore) {
                throw GradleException(
                    "Release build requires a valid signing config in key.properties."
                )
            }
            if (isReleaseTask && mapsApiKey.isBlank()) {
                throw GradleException(
                    "Release build requires mapsApiKey in key.properties."
                )
            }
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                logger.warn("Release keystore not found or incomplete, using debug signing for release build.")
                signingConfigs.getByName("debug")
            }
            
            // Enable R8/ProGuard with proper Stripe 3D Secure rules
            // UPDATED: Re-enabled minification with comprehensive Stripe ProGuard rules
            // to fix 3D Secure challenge crashes (PassiveChallengeViewModel, AttestationViewModel, etc.)
            // TEMPORARY: Disabled due to R8 XML parsing error
            isMinifyEnabled = false
            isShrinkResources = false
            
            // ProGuard rules with Stripe SDK compatibility
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        
        debug {
            // Pin debug signing to project-local debug.keystore for stable Firebase SHA fingerprints.
            val localDebugKeystore = resolveProjectKeystore("debug.keystore")
            signingConfig = if (localDebugKeystore.exists()) {
                signingConfigs.getByName("localDebug")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    jvmToolchain(21)
}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring for flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // Multidex support
    implementation("androidx.multidex:multidex:2.0.1")
    
    // Explicit Google Play Services versions to fix crashes
    // Prevents null object reference crashes in Google Sign-In and related services
    implementation("com.google.android.gms:play-services-auth:21.1.0")
    implementation("com.google.android.gms:play-services-base:18.5.0")
    
    // Ensure AndroidX compatibility
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
    implementation("androidx.activity:activity-ktx:1.10.0")
    
    // Fix for camera_android_camerax compilation error
    implementation("androidx.concurrent:concurrent-futures:1.1.0")
    implementation("org.jspecify:jspecify:1.0.0")

}
