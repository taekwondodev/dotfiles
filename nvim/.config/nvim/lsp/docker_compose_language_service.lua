return {
    cmd = { "docker-compose-langserver", "--stdio" },
    filetypes = { "yaml.docker-compose" },
    root_markers = { "compose.yaml", "compose.yml", "compose.test.yaml", "docker-compose.yaml", "docker-compose.yml" },
}
