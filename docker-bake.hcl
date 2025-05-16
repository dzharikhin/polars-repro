target "repro_cc" {
    context = "."
    dockerfile = "dependencies.x86_64.to.armv7.Dockerfile"
    ulimits = [
        "nofile=4096:4096"
    ]
    output = [{ type = "docker" }]
}
target "repro" {
    context = "."
    dockerfile = "Dockerfile"
    contexts = {
      dependencies_arm = "target:repro_cc"
    }
    tags = [ "repro:1.0.2-armv7" ]
    output = [{ type = "docker" }]
    platforms = [ "linux/arm/v7" ]
}

target "rust_repro_cc" {
    context = "."
    dockerfile = "rust_repro_cc.Dockerfile"
    output = [{ type = "docker" }]
}

target "rust_repro" {
    context = "."
    dockerfile = "rust_repro.Dockerfile"
    contexts = {
      dependencies-builder = "target:rust_repro_cc"
    }
    tags = [ "rust_repro:1.3" ]
    output = [{ type = "docker" }]
    platforms = [ "linux/arm/v7" ]
}