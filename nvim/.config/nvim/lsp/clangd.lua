return {
    cmd = {
        "clangd",
        "--offset-encoding=utf-16",
        "--clang-tidy",
        "--header-insertion=iwyu",
    },
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
}
