import io.github.keiyoushi.gradle.api.ContentWarning

plugins {
    alias(kei.plugins.extension)
}

keiyoushi {
    name = "E-Hentai"
    versionCode = 37
    contentWarning = ContentWarning.NSFW
    libVersion = "1.4"

    source {
        lang = "ja"
        baseUrl = "https://e-hentai.org"
    }
    source {
        lang = "en"
        baseUrl = "https://e-hentai.org"
    }
    source {
        lang = "zh"
        baseUrl = "https://e-hentai.org"
    }
    source {
        lang = "nl"
        baseUrl = "https://e-hentai.org"
    }
    source {
        lang = "fr"
        baseUrl = "https://e-hentai.org"
    }
    source {
        lang = "de"
        baseUrl = "https://e-hentai.org"
    }
    source {
        lang = "hu"
        baseUrl = "https://e-hentai.org"
    }
    source {
        lang = "it"
        baseUrl = "https://e-hentai.org"
    }
    source {
        lang = "ko"
        baseUrl = "https://e-hentai.org"
    }
    source {
        lang = "pl"
        baseUrl = "https://e-hentai.org"
    }
    source {
        lang = "pt-BR"
        baseUrl = "https://e-hentai.org"
        // Hardcode the id because the language wasn't specific.
        id = 7151438547982231541
    }
    source {
        lang = "ru"
        baseUrl = "https://e-hentai.org"
    }
    source {
        lang = "es"
        baseUrl = "https://e-hentai.org"
    }
    source {
        lang = "th"
        baseUrl = "https://e-hentai.org"
    }
    source {
        lang = "vi"
        baseUrl = "https://e-hentai.org"
    }
    source {
        lang = "none"
        baseUrl = "https://e-hentai.org"
    }
    source {
        lang = "other"
        baseUrl = "https://e-hentai.org"
    }

    deeplink {
        path("/g/..*/..*")
    }
}

val generatedEtagAssetsDir = layout.buildDirectory.dir("generated/assets/etagDb").get().asFile

android {
    sourceSets {
        getByName("main") {
            assets.directories.add(generatedEtagAssetsDir.path)
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
