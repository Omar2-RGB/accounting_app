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

// 🚀 الفرمان العسكري المترجم للغة Kotlin DSL 
subprojects {
    afterEvaluate {
        extensions.findByName("android")?.let { ext ->
            (ext as? com.android.build.gradle.BaseExtension)?.let { android ->
                android.compileSdkVersion(36)
                android.targetSdkVersion(36)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}