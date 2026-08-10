allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Several plugin AARs (e.g. flutter_plugin_android_lifecycle, pulled in by
// image_picker/file_picker) require consumers to compile against API 36+,
// but some older plugin modules (e.g. file_picker 8.x, connectivity_plus)
// still hardcode a lower compileSdk in their own android/build.gradle. Rather
// than pinning every plugin to a compatible version (which drags in breaking
// API/Kotlin-toolchain changes — see the app-level ndkVersion/compileSdk
// comments), force every Android module in the build to compile against 36.
// Must be registered before the evaluationDependsOn(":app") block below,
// which forces early evaluation of :app and would otherwise make a
// subsequent afterEvaluate registration on it fail ("already evaluated").
subprojects {
    afterEvaluate {
        extensions.findByType(com.android.build.gradle.BaseExtension::class.java)?.apply {
            compileSdkVersion(36)
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
