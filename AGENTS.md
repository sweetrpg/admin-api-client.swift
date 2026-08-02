# AGENTS.md

This file provides guidance to Claude Code, Codex, GitHub Copilot, and other coding agents
working in this repository.

## About This Project

`admin-api-client.swift` is the Swift client SDK for `admin-api` (`sweetrpg/admin-api`): fetches
active banner messages and maintenance-mode records for a set of scopes (`platform`,
`service:<name>`). It's a shared extraction of the `AdminClient` pattern that was previously
hand-rolled independently in `main-web` (Rust, out of scope for this package) and `catalog-web`
(Swift, now consumes this package instead). `auth-web` and `directory-web` are its other
consumers. Sibling Python package: `admin-api-client.py`.

Unlike a domain API client SDK (`catalog-api-client.swift`), this package bakes in caching
(90s TTL), a 2s request timeout, and fail-open behavior on every error path - every consumer
must behave identically for this cross-cutting concern, so it isn't left to each app to
re-derive.

## Committing Code

[Conventional Commits](https://www.conventionalcommits.org/): `<type>(<scope>): <description>`.

## Branches and Workflow

Git-flow (see `docs/git-flow.md` in `sweetrpg/platform`): `develop` is the integration branch,
`master` reflects the latest release. Feature/fix branches off `develop`, PR back into `develop`.

## Running Checks Locally

```bash
swift build
swift test
```
