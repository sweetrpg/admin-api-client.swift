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

## Platform Conventions and Decisions

This repo is a submodule of `sweetrpg/platform`. Platform-wide conventions and Architecture
Decision Records live there:

- checked out inside the platform tree: `../../../docs/README.md` (convention index) and
  `../../../docs/adr/README.md` (platform ADRs, `PADR-*`)
- standalone or module-only checkout:
  <https://github.com/sweetrpg/platform/tree/master/docs> and
  <https://github.com/sweetrpg/platform/tree/master/docs/adr>

Accepted `PADR-*` records are binding constraints. Read the ADR index before proposing a
structural change; if a task needs to contradict an accepted record, stop and say so -
propose a superseding ADR rather than working around it. This repo's own service-local
decisions are `ADR-*` and belong in `docs/adr/` here.

Before implementing any feature, complete the
[feature work checkpoint](https://github.com/sweetrpg/platform/blob/master/docs/openspec.md#feature-work-checkpoint)
and record the answers in the issue or PR.
