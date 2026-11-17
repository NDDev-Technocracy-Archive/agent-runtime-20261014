set shell := ["bash", "-euo", "pipefail", "-c"]
export GOTOOLCHAIN := "local"

# Lists the commands.
default:
    @just --list

# Fetches the existing module graph without compiling the runtime.
setup:
    go mod download

# Checks Go/command formatting and workflow safety without builds or network access.
check:
    just --fmt --check
    gofmt -l . | diff - /dev/null
    actionlint
    zizmor --offline --no-progress .github

# Runs every existing native race, analysis, build, fuzz and cold-platform gate.
test:
    go test -race ./...
    go vet ./...
    go run ./cmd/check-staticcheck
    go run honnef.co/go/tools/cmd/staticcheck@v0.8.1 ./...
    just build
    go run ./cmd/check-fuzz
    go run ./cmd/check-cold-compile

# Builds the existing native CLI without publishing it.
build:
    go build ./cmd/agent-runtime

# Runs the existing dependency vulnerability gate on the execution host.
vulnerability-check:
    go run golang.org/x/vuln/cmd/govulncheck@v1.7.0 ./...

# Retains the complete accepted-source Git history secret scan.
history-check:
    betterleaks git --no-banner --redact .

# Runs complete source/native/vulnerability/history verification.
verify: check test vulnerability-check history-check
