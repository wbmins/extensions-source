plugins {
    alias(kei.plugins.extension)
}

keiyoushi {
    name = "E-Hentai"
    className = "EHentai"
    versionCode = 26
    contentWarning = ContentWarning.NSFW
    libVersion = "1.4"
    baseUrl = "https://e-hentai.org"
}

val generatedEtagAssetsDir = layout.buildDirectory.dir("generated/assets/etagDb").get().asFile

android {
    sourceSets {
        getByName("main") {
            assets.srcDirs(generatedEtagAssetsDir)
        }
    }
}

tasks.register<Copy>("moveEtagDb") {
    val etagFile = rootProject.file("etag.db")
    if (!etagFile.exists()) {
        throw GradleException("etag.db does not exist")
    }
    from(etagFile)
    into(generatedEtagAssetsDir)
    doLast {
        etagFile.delete()
    }
}

tasks.named("preBuild") {
    dependsOn("moveEtagDb")
}
