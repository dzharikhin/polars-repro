group "default" {
    targets = [ "deps", "repro" ]
}
variable "REPRO_VERSION" {
}
variable "VER" {
  default = "${REPRO_VERSION}-armv7-32k"
}
target "deps" {
    context = "."
    dockerfile = "dependencies.x86_64.to.armv7.Dockerfile"
    ulimits = [
        "nofile=4096:4096"
    ]
    tags = [ "repro_dependencies:${VER}" ]
    output = [{ type = "docker" }]
}
target "repro" {
    context = "."
    dockerfile = "Dockerfile"
    contexts = {
      dependencies_arm = "target:deps"
    }
    tags = [ "repro:${VER}" ]
    output = [{ type = "docker" }]
    platforms = [ "linux/arm/v7" ]
}