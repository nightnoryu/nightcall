local images = import 'images.libsonnet';

local cache = std.native('cache');
local copy = std.native('copy');
local copyFrom = std.native('copyFrom');

local gosources = [
    "go.mod",
    "go.sum",
    "cmd",
    "pkg",
];

local gocache = [
    cache("go-build", "/app/cache"),
    cache("go-mod", "/go/pkg/mod"),
];

{
    project(appIDs):: {
        apiVersion: "brewkit/v1",

        targets: {
            all: ["modules", "build"],
        } + {
            modules: ["gotidy", "modulesvendor"],

            gotidy: {
                from: "gobase",
                workdir: "/app",
                cache: gocache,
                ssh: {},
                command: "go mod tidy",
                output: {
                    artifact: "/app/go.*",
                    "local": ".",
                },
            },

            modulesvendor: {
                from: "gotidy",
                workdir: "/app",
                cache: gocache,
                command: "go mod vendor",
                output: {
                    artifact: "/app/vendor",
                    "local": "vendor",
                },
            },

            build: [appID for appID in appIDs],
        } + {
            [appID]: {
                from: "gobase",
                workdir: "/app",
                cache: gocache,
                dependsOn: ["modules"],
                command: "go build -trimpath -v -o ./bin/" + appID + " ./cmd/" + appID,
                output: {
                    artifact: "/app/bin/" + appID,
                    "local": "./bin"
                }
            }
            for appID in appIDs
        } + {
            gobase: {
                from: images.gobuilder,
                workdir: "/app",
                env: {
                    GOCACHE: "/app/cache/go-build",
                    CGO_ENABLED: "1",
                    LIBRARY_PATH: "/app/lib",
                    C_INCLUDE_PATH: "/app/lib/include",
                },
                copy: [
                    copyFrom("gosources", "/app", "/app"),

                    copyFrom("whisper", "/app/ggml/include/*.h", "/app/lib/include/"),
                    copyFrom("whisper", "/app/build_go/ggml/src/*.a", "/app/lib"),

                    copyFrom("whisper", "/app/include/*.h", "/app/lib/include/"),
                    copyFrom("whisper", "/app/build_go/src/*.a", "/app/lib/"),

                    copyFrom("llama", "/app/*.h", "/app/lib/include/"),
                    copyFrom("llama", "/app/*.a", "/app/lib/"),
                ]
            },

            gosources: {
                from: "scratch",
                workdir: "/app",
                copy: [copy(source, source) for source in gosources]
            },

            whisper: {
                from: images.gobuilder,
                workdir: "/app/bindings/go",
                copy: copy("/whisper.cpp", "/app"),
                command: "apt-get update && apt-get install -y git cmake && make"
            },

            llama: {
                from: images.gobuilder,
                workdir: "/app",
                copy: copy("/go-llama.cpp", "/app"),
                command: "apt-get update && apt-get install sh && make libbinding.a"
            }
        }
    }
}
