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

// 🚀 الفخ العلوي (وضعناه "قبل" أمر التقييم الإجباري)
subprojects {
    afterEvaluate { subProj ->
        subProj.extensions.findByType<com.android.build.api.dsl.LibraryExtension>()?.apply {
            compileSdk = 36
        }
    }
}

// عندما ينفذ هذا السطر الآن، ستكون المكتبات قد حُجزت في الفخ أعلاه
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}