allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    
    configurations.all {
        resolutionStrategy {
            force("androidx.concurrent:concurrent-futures:1.1.0")
            force("org.jspecify:jspecify:1.0.0")
            eachDependency {
                if (requested.group == "androidx.camera") {
                    useVersion("1.5.0-alpha02")
                }
            }
        }
        
        // Exclude unavailable play-services-tapandpay from Stripe
        exclude(group = "com.google.android.gms", module = "play-services-tapandpay")
    }
}

subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            extensions.findByType<com.android.build.gradle.LibraryExtension>()?.apply {
                compileSdk = 36
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
