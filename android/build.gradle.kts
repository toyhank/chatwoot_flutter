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

// 自动修复旧版 Flutter 插件缺少 namespace 的问题，并设置编译版本
subprojects {
    plugins.withId("com.android.library") {
        val android = project.extensions.getByName("android") as com.android.build.gradle.LibraryExtension
        // 根据腾讯云文档建议：设置编译版本以解决第三方库兼容性问题
        android.compileSdkVersion(34)
        android.buildToolsVersion = "34.0.0"
        
        if (android.namespace == null) {
            val manifestFile = project.file("src/main/AndroidManifest.xml")
            if (manifestFile.exists()) {
                val manifestContent = manifestFile.readText()
                val packagePattern = "package=\"([^\"]+)\"".toRegex()
                val match = packagePattern.find(manifestContent)
                if (match != null) {
                    android.namespace = match.groupValues[1]
                }
            }
        }
    }
    
    plugins.withId("com.android.application") {
        val android = project.extensions.getByName("android") as com.android.build.gradle.BaseExtension
        if (android.namespace == null) {
             val manifestFile = project.file("src/main/AndroidManifest.xml")
            if (manifestFile.exists()) {
                val manifestContent = manifestFile.readText()
                val packagePattern = "package=\"([^\"]+)\"".toRegex()
                val match = packagePattern.find(manifestContent)
                if (match != null) {
                    android.namespace = match.groupValues[1]
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
