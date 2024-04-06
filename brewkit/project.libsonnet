local images = import "images.libsonnet";

local cache = std.native("cache");
local copy = std.native("copy");
local copyFrom = std.native("copyFrom");

// External cache for go compiler, go mod, golangci-lint
local gocache = [
    cache("go-build", "/app/cache"),
    cache("go-mod", "/go/pkg/mod"),
];

// Sources which will be tracked for changes
local gosources = [
    "go.mod",
    "go.sum",
    "cmd",
    "pkg",
];

{
    // Function that generate project build definitions, including code generating, app compilation and e.t.c
    project(appIDs):: {
        apiVersion: "brewkit/v1",

        targets: {
            all: ["modules", "build", "test"],

            build: [appID for appID in appIDs],

            gobase: {
                from: images.gobuilder,
                workdir: "/app",
                env: {
                    GOCACHE: "/app/cache/go-build",
                },
                copy: copyFrom(
                    "gosources",
                    "/app",
                    "/app"
                ),
            },
        } + {
            [appID]: {
                from: "gobase",
                workdir: "/app",
                cache: gocache,
                dependsOn: ["modules"],
                command: "go build -trimpath -v -o ./bin/" + appID + " ./cmd/" + appID,
                output: {
                    artifact: "/app/bin/" +  appID,
                    "local": "./bin",
                },
            }
            for appID in appIDs // expand build target for each appID
        } + {
            gosources: {
                from: "scratch",
                workdir: "/app",
                copy: [copy(source, source) for source in gosources]
            },

            modules: ["gotidy", "modulesvendor"],

            gotidy: {
                from: "gobase",
                workdir: "/app",
                cache: gocache,
                ssh: {},
                command: "
                    go mod tidy
                ",
                output: {
                    artifact: "/app/go.*",
                    "local": ".",
                },
            },

            // export local copy of dependencies for ide index
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

            test: {
                from: "gobase",
                workdir: "/app",
                cache: gocache,
                command: "go test ./...",
            },
        },
    },
}
