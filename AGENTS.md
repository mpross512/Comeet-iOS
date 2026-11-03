# Comeet iOS: agent guidance

Comeet is a dating app where users receive one potential match each week. This repository contains the SwiftUI app; the ASP.NET Core API is a separate repository.

## Find project context

- Shared project documentation lives in `../Comeet-API/docs/`; start with its [index](../Comeet-API/docs/README.md).
- Skim the shared [status](../Comeet-API/docs/status.md) when starting project work for current priorities and blockers.
- Use [product](../Comeet-API/docs/product.md) for product rules, [architecture](../Comeet-API/docs/architecture.md) for service boundaries, and this repository's [README.md](README.md) for local setup.
- Consult shared feature specifications and decision records when relevant to the task. Read the context the task needs.
- Before inspecting or changing the API repository, read its `AGENTS.md`; sibling repository instructions are not automatically part of this repository's instruction chain.
- When using a worktree, locate the companion repository using the available workspace roots rather than assuming the relative sibling path still works.

## Current implementation

- SwiftUI app; target settings specify iOS 17.0 and Swift 6.0.
- `Comeet/App.swift` is the active entry point. `Views/`, `Models/`, and `Controllers/` contain UI, domain data, and service code.
- Active data access uses the local Swift 6.4 `Packages/ComeetData` repository, URLSession, Keychain, and the Comeet API. UI state stays on the main actor; Supabase and deprecated Firebase clients are removed.
- Xcode 27 / iOS 27 simulator verification is supported while retaining the iOS 17 deployment minimum. API contracts and the operation map live in shared `docs/features/api-data-migration.md`.
- The match view currently renders a collection; an enforced weekly single-offer behavior has not been established.

## Working agreements

- Treat confirmed requirements separately from observed behavior and proposals. Mark unknown product rules as open questions.
- Keep shared product, architecture, status, and decisions in the API repository's `docs/` and link to them rather than duplicating them here.
- Update relevant docs when behavior, integration, priorities, or blockers change.
- Use placeholders for credentials and synthetic examples for user data. Do not copy credential values or personal data into documentation, fixtures, or tool output.
- Identity and domain JSON use camelCase. Verify contracts against both repositories; birthdays are date-only strings and message timestamps are Unix milliseconds.

## Verification

- Use the `Comeet-Debug` scheme for local development. The `Comeet` scheme launches with Release configuration.
- Build an appropriate simulator destination after app code changes when Xcode/packages/configuration are available; see the README for a starter command.
- Run the `Comeet-Debug` scheme's `ComeetTests` test action on an installed simulator. It includes native Swift Testing for the repository and app adapters. Independent tests use `swift test --package-path Packages/ComeetData`. Real HTTP tests require disposable seeded demo accounts; see the shared migration map.
- For documentation-only changes, check links, paths, and consistency with the code; an application build is unnecessary.
- Report missing external configuration or unverified runtime behavior explicitly.
