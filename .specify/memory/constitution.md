<!--
=== Sync Impact Report ===
Version change: (new) → 1.0.0
Modified principles: N/A (initial population)
Added sections:
  - Core Principles (5 principles)
  - Technology Stack & Reliability Constraints
  - Feature Development Lifecycle
  - Governance
Removed sections: None
Templates requiring updates:
  - .specify/templates/plan-template.md ✅ reviewed (Constitution Check section aligns)
  - .specify/templates/spec-template.md ✅ reviewed (scope/requirements align)
  - .specify/templates/tasks-template.md ✅ reviewed (task phases align)
Follow-up TODOs: None
=== End Sync Impact Report ===
-->

# Chat App Constitution

## Core Principles

### I. Layered Architecture (Feature-First)

The codebase MUST follow a feature-first layered structure under `lib/`:

- **core/** contains shared infrastructure only: network, error models,
  services, and utilities.
- **features/** contains self-contained feature modules, each with its own
  `cubit/`, `models/`, `repos/`, and `widgets/` subdirectories.
- **routes/** holds GoRouter navigation configuration exclusively.
- **service/** holds dependency injection setup exclusively.
- Dependencies MUST flow `core → features`, never the reverse. Importing
  from `features/` into `core/` is a constitutional violation.
- Each new feature MUST create a new subdirectory under `features/`.

**Rationale**: Strict layering prevents circular dependencies, enables
independent feature development, and keeps the shared core stable.

### II. Cubit-First State Management & Separation of Concerns

All complex state MUST be managed through **flutter_bloc Cubits**, never
through `setState`:

- Every feature MUST have its own `Cubit` and corresponding `State`
  classes inside a `cubit/` subdirectory.
- State classes MUST use distinct classes or sealed types for each state
  (e.g., `ChatInitial`, `ChatLoading`, `ChatLoaded`, `ChatError`).
- Business logic MUST NOT reside in widget classes. Widgets MUST
  delegate all business logic to their associated Cubit.
- Cubits MUST be provided through `BlocProvider` at the route level.

**Rationale**: Centralizing state in Cubits makes behavior testable,
predictable, and decoupled from the UI layer.

### III. Repository Pattern with Functional Error Handling

All data access MUST go through the Repository abstraction layer using
the `dartz` `Either` type:

- Define an **abstract class** (e.g., `ChatRepository`) and a concrete
  **implementation** (e.g., `ChatRepositoryImpl`).
- All repository and service methods that can fail MUST return
  `Either<CommonFailedModel, T>`.
- Callers MUST handle both `Left` (failure) and `Right` (success) paths.
  Ignoring the failure path is a constitutional violation.
- Network failures MUST be modeled via `CommonFailedModel` and
  `DioFailure` in `lib/core/error/`.
- Retryable DioExceptions (timeouts, 5xx, 429, 408) MUST be retried
  with exponential backoff.

**Rationale**: Functional error handling eliminates silent failures and
forces every call site to consider the failure path explicitly.

### IV. Security-First & Dependency Injection

API keys and secrets MUST NOT be hardcoded in source files under any
circumstance:

- All secrets MUST be injected via environment variables, `.env` files,
  or secure runtime configuration.
- All dependencies MUST be registered in
  `lib/service/service_locator.dart` via the `DI.execute()` method.
- Registration order MUST be: **Network → Services → Repositories →
  Cubits**.
- Use `registerFactory` for transient dependencies and
  `registerLazySingleton` for singletons.
- Dependencies MUST be accessed via `serviceLocator<T>()`, never
  instantiated directly at the call site.

**Rationale**: Centralized injection enables testability via mock
substitution and prevents secret leakage into version control.

### V. Test-Driven Development

Tests MUST be written and verified to fail before the corresponding
implementation is written:

- Unit tests reside in `test/` mirroring the `lib/` directory structure.
- Use `mocktail` for mocking dependencies in tests.
- Cubit tests MUST verify state emissions.
- Repository tests MUST mock the service layer.
- Widget tests and Cubit tests MUST be written for every new feature.

**Rationale**: Test-first development catches regressions early, drives
cleaner interfaces, and ensures every feature ships with a safety net.

## Technology Stack & Reliability Constraints

### Required Technology Stack

| Component            | Technology                       | Constraint                                    |
|----------------------|----------------------------------|-----------------------------------------------|
| Framework            | Flutter (Dart SDK ^3.11.0)       | All UI and business logic                     |
| State Management     | flutter_bloc (Cubit)             | No alternative state libraries                |
| HTTP Client          | Dio                              | Configured in `core/network/dio_services.dart` |
| Debug Logging        | PrettyDioLogger                  | Enabled only in `kDebugMode`                  |
| Routing              | GoRouter                         | Declarative routes only                       |
| Dependency Injection | GetIt                            | Single service locator                        |
| Error Handling       | dartz (Either)                   | Mandatory for all fallible operations         |
| Testing Mocks        | mocktail                         | Standard mock library                         |
| AI API               | Google Gemini API                | Base URL: `generativelanguage.googleapis.com` |

### Reliability Requirements

- **Error Recovery**: All network calls MUST implement retry logic with
  exponential backoff for transient failures (timeouts, 5xx, 429, 408).
- **Graceful Degradation**: The app MUST display meaningful error states
  to the user when API calls fail, never raw exceptions or blank screens.
- **Logging**: `PrettyDioLogger` MUST be configured for debug builds.
  Production builds MUST NOT expose request/response logs.

## Feature Development Lifecycle

### Workflow

1. **Branch**: Create a feature branch from `main` following the naming
   convention `<issue-number>-feature-name`.
2. **Structure**: Create a new subdirectory under `features/` with
   `cubit/`, `models/`, `repos/`, and `widgets/` subdirectories.
3. **Register**: Add all new dependencies to `service_locator.dart`
   following the Network → Services → Repositories → Cubits order.
4. **Test First**: Write failing tests for the new feature's Cubit and
   repository layers before writing implementation code.
5. **Implement**: Build the feature following the layered architecture,
   ensuring no violations of the dependency flow.
6. **Verify**: Run all tests, lint checks (`analysis_options.yaml`),
   and ensure the app compiles without warnings.
7. **Merge**: Submit for review. Reviewer MUST verify constitutional
   compliance before approving.

### Coding Standards

- Follow the official Dart Style Guide and project lint rules.
- Use **trailing commas** on all parameter lists and collection literals.
- Prefer `const` constructors wherever the compiler allows.
- Use `super.key` in widget constructors (Dart 3 super-parameters).
- Files: `snake_case.dart` | Classes: `PascalCase` | Variables:
  `camelCase` | Private: prefix with `_`.
- One primary class per file. Group imports: `dart:` → `package:flutter/`
  → third-party → project imports.

## Governance

This constitution is the highest-authority document for the Chat App
project. All code contributions, reviews, and architectural decisions
MUST comply with the principles defined herein.

- **Amendment Process**: Any proposed change to this constitution MUST
  be documented with a rationale, reviewed, and approved before merging.
  The Sync Impact Report (HTML comment at the top of this file) MUST be
  updated to reflect the change.
- **Versioning**: This constitution follows semantic versioning:
  - **MAJOR**: Backward-incompatible principle removals or redefinitions.
  - **MINOR**: New principle or section added, or materially expanded
    guidance.
  - **PATCH**: Clarifications, wording fixes, non-semantic refinements.
- **Compliance Review**: All pull requests MUST verify compliance with
  these principles. Reviewers MUST check for constitutional violations
  before approving. Use the AGENTS.md file for runtime development
  guidance.

**Version**: 1.0.0 | **Ratified**: 2026-08-04 | **Last Amended**: 2026-08-04
