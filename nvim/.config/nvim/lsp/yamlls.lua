return {
    settings = {
        yaml = {
            schemaStore = { enable = false, url = "" },
            schemas = vim.tbl_extend(
                "force",
                require("schemastore").yaml.schemas(),
                { kubernetes = { "k8s/*.yaml", "k8s/**/*.yaml" } }
            ),
            validate = true,
            completion = true,
            hover = true,
        },
    },
}
