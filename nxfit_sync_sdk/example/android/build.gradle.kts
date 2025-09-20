allprojects {
    repositories {
        google()
        mavenCentral()

        maven {
            val nxfitGithubUser = project.findProperty("NXFIT_GITHUB_USER") as? String
            val nxfitGithubToken = project.findProperty("NXFIT_GITHUB_TOKEN") as? String

            name = "GitHubPackages"
            url = uri("https://maven.pkg.github.com/NeoEx-Developer/NXFit-SDK-for-Android")

            credentials {
                username = nxfitGithubUser
                password = nxfitGithubToken
            }
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
