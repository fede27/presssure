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

// tflite_flutter compiles its Java for JVM 11 but leaves Kotlin on the
// JDK's default target: the build refuses the mismatch. Same target for both.
subprojects {
    if (name == "tflite_flutter") {
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
        }
    }
}

// F-Droid: the LiteRT AARs that tflite_flutter pulls from Google Maven carry
// references to a proprietary Play library (com.google.android.play:ai-delivery).
// They only ship the native runtime (the plugin's Kotlin never imports them), so
// they are dropped everywhere and the app adds a build compiled from source
// instead (see dependencies in app/build.gradle.kts). No GPU delegate: the
// engine runs on the CPU (lib/ocr/seg7_engine.dart).
subprojects {
    configurations.all {
        exclude(group = "com.google.ai.edge.litert")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
