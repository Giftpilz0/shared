set shell := ["bash", "-euo", "pipefail", "-c"]

# List recipes
default:
    @just --list --unsorted

# Run all linters and formatters (pre-commit); CI runs this too
lint *args:
    pre-commit run --all-files {{args}}

# Definition of done
check: lint
