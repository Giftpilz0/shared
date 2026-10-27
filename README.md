# shared

[![ci](https://github.com/Giftpilz0/shared/actions/workflows/ci.yml/badge.svg)](https://github.com/Giftpilz0/shared/actions/workflows/ci.yml)
[![license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Shared setup for my repositories: guidelines, Renovate preset, lint workflow and justfile conventions.

## Usage

### Guidelines

[`guidelines.md`](guidelines.md) applies to every repository. My dotfiles clone this repository and
import it from `~/.claude/CLAUDE.md`.

### Renovate

`renovate.json`:

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["github>Giftpilz0/shared"]
}
```

Repository-specific `packageRules` and `customManagers` go below `extends`. The preset:

- `config:recommended`, all non-major updates grouped into one PR, weekly schedule (Europe/Berlin)
- updates `.pre-commit-config.yaml` hooks
- updates versions annotated in YAML files and `Containerfile`/`Dockerfile`:

```yaml
# renovate: datasource=github-releases depName=restic/restic
restic_version: 0.18.1
```

```dockerfile
# renovate: datasource=docker depName=docker.io/library/alpine
ARG ALPINE_VERSION=3.24
```

Optional fields after `depName`, in this order: `registryUrl=`, `extractVersion=`, `versioning=`.

### Lint workflow

`.github/workflows/lint.yml` runs `just lint` (pre-commit on all files) in the calling repository.
It installs uv, just and pre-commit, plus Go when `go.mod` exists, OpenTofu when `*.tf` files exist and Node + bun when a `bun.lock` exists.

```yaml
jobs:
  lint:
    uses: Giftpilz0/shared/.github/workflows/lint.yml@main
```

Release, deploy and container workflows stay in the repositories themselves.

### Justfile

Every repository has a `justfile` with `set shell := ["bash", "-euo", "pipefail", "-c"]` and the
recipes that apply, using these names:

| Recipe        | Meaning                                                   |
| ------------- | --------------------------------------------------------- |
| `default`     | `just --list --unsorted`                                  |
| `lint`        | `pre-commit run --all-files`, what CI runs                |
| `check`       | definition of done: `lint` + `test` (+ `build`)           |
| `test`        | unit tests                                                |
| `build`       | build artifacts                                           |
| `dev` / `run` | local development / run from source                       |
| `clean`       | remove build output                                       |
| `deploy`      | push to the real target (playbook, chezmoi, device, Copr) |

Linters and formatters are configured in `.pre-commit-config.yaml`. Common hooks: pre-commit-hooks
(case conflict, end of file, trailing whitespace), mdformat, actionlint; shellcheck + shfmt
(`-i 4 -ci`) where there is shell, golangci-lint where there is Go.

### Stripping bot commits

`scripts/strip-bot-commits.sh` rewrites `main` without bot and merge commits (Renovate, Dependabot,
GitHub Actions, Flux, Copilot). Bot changes are folded into the next human commit. It never pushes.
My dotfiles keep a clone of this repository in `~/.local/share/giftpilz0-shared`:

```sh
cd <repo>
~/.local/share/giftpilz0-shared/scripts/strip-bot-commits.sh   # backup branch + git bundle next to the repo
git push --force-with-lease origin main
```

This rewrites history: other clones must reset, and tags on rewritten commits no longer point into
`main` (the script lists them).

## Development

Run `just` for all recipes and `just check` before committing.

## License

[MIT](LICENSE)
