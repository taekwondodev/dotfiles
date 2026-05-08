return {
    -- mason installs a wrapper script that handles jar paths automatically
    cmd = { "jdtls" },
    filetypes = { "java" },
    root_markers = { "pom.xml", "build.gradle", "build.gradle.kts", ".git" },
    settings = {
        java = {
            format = { enabled = false },
            eclipse = { downloadSources = true },
            maven = { downloadSources = true },
            implementationsCodeLens = { enabled = true },
            referencesCodeLens = { enabled = true },
            inlayHints = { parameterNames = { enabled = "all" } },
        },
    },
    init_options = {
        bundles = {},
    },
}
