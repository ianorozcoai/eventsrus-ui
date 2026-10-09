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
subprojects {
    project.evaluationDependsOn(":app")
}

// file_picker 9.0.0's own android/build.gradle hardcodes compileSdk 34 with
// no override hook, which is lower than its flutter_plugin_android_lifecycle
// dependency requires (36+). Force every plugin subproject to compile
// against the same SDK as the app module so that mismatch can't recur.
subprojects {
    if (project.name == "app") return@subprojects
    afterEvaluate {
        extensions.findByName("android")?.let { androidExt ->
            if (androidExt is com.android.build.gradle.BaseExtension) {
                androidExt.compileSdkVersion(36)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
