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
    if (project.name != "app") {
        plugins.withId("com.android.library") {
            val androidComponents = extensions.findByType(com.android.build.api.variant.AndroidComponentsExtension::class.java)
            androidComponents?.beforeVariants { variantBuilder ->
                (variantBuilder as? com.android.build.api.variant.HasUnitTestBuilder)?.enableUnitTest = false
                (variantBuilder as? com.android.build.api.variant.HasAndroidTestBuilder)?.enableAndroidTest = false
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
