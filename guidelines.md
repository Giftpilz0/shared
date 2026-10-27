# Guidelines

Preferences for all my repositories. Repo-specific rules live in each repo's CLAUDE.md.

## Workflow

- Tasks run through `just`. `just check` is the definition of done:
  run it and show the result before reporting success.
- Linters/formatters are configured in `.pre-commit-config.yaml`;
  `just lint` runs them, CI runs `just lint`.
- Conventional Commits. Commit only when asked; never push.

## New repositories

- MIT license (`LICENSE`, my name, current year).
- `renovate.json` extending `github>Giftpilz0/shared`; `.github/workflows/ci.yml` (`name: ci`)
  calling the shared lint workflow.

## Writing

- Comments and READMEs are minimal: only what matters and isn't obvious from the code,
  in short, plain sentences.
- README structure: title, badges (workflows + license), one sentence on what it is,
  `## Usage`, `## Development` (`just check` + link to Giftpilz0/shared), `## License`.
  Leave out sections that would be empty.

## Tooling

- Containers: podman and `Containerfile`, never docker/Dockerfile;
  fully qualified image names (`docker.io/library/...`).
- JS/TS: bun as package manager and script runner (no npm/yarn/pnpm).
- Python: Astral tooling: uv (no pip/poetry), ruff, ty.
- Go: golangci-lint, GoReleaser for releases.

## Languages and libraries

- Go by default; Python only when a Python-only library is the reason.
- Go: standard library first; Cobra (CLI), Bubble Tea (TUI), sqlc (no ORM),
  modernc.org/sqlite, pgx.
- Python: FastAPI (web API), Textual (TUI). Other libraries only as widely
  used counterparts of the Go choices, and only if they give a real benefit.
- Web UI: templ + htmx + Tailwind for small apps;
  SvelteKit SPA + shadcn-svelte for rich client-side UIs.

## Deployment

- Images on GHCR, deployed as rootless Podman Quadlet behind a reverse proxy.
- Apps with auth use OIDC against my Keycloak; no local passwords.
