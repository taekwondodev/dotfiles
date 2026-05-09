local lombok_jar = vim.fn.expand("$MASON/share/jdtls/lombok.jar")

return {
    cmd = {
        "jdtls",
        string.format("--jvm-arg=-javaagent:%s", lombok_jar),
        "--jvm-arg=-Djava.import.generatesMetadataFilesAtProjectRoot=false",
        "--jvm-arg=-Xmx2G",
    },
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
    before_init = function(_, config)
        local workspace = vim.fn.stdpath("data")
            .. "/jdtls-workspaces/"
            .. vim.fn.fnamemodify(config.root_dir, ":p"):gsub("[/:]", "_")
        vim.list_extend(config.cmd, { "-data", workspace })
    end,
}
