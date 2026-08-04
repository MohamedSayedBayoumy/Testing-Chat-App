# Chat App — Project Rules

## Project Overview

This is a **Flutter Chat App** that integrates with the **Google Gemini API** to provide AI-powered conversational experiences. The app follows a clean, layered architecture with separation between UI, business logic, and data layers.

---

## Architecture & Patterns

### Layered Architecture

The codebase follows a **feature-first** structure under `lib/`:

```
lib/
├── core/              # Shared infrastructure (network, errors, services, utilities)
│   ├── error/         # Error/failure models (CommonFailedModel, DioFailure)
│   ├── network/       # HTTP client (DioServices)
│   ├── services/      # API service classes (GeminiChatServices)
│   └── app_utils.dart # Shared utilities and constants
├── features/          # Feature modules (each with its own UI, cubit, models, repos, widgets)
│   └── chat/
│       ├── cubit/     # BLoC/Cubit state management
│       ├── models/    # Data models (request, response, message)
│       ├── repos/     # Repository abstraction layer
│       └── widgets/   # Reusable UI widgets
├── routes/            # GoRouter navigation configuration (pages.dart, paths.dart)
├── service/           # Dependency injection setup (GetIt service locator)
└── main.dart          # App entry point
```

### State Management — BLoC / Cubit

- Use **flutter_bloc** with **Cubit** for state management.
- Each feature should have its own `Cubit` and corresponding `State` classes inside a `cubit/` subdirectory.
- Cubits must be injected via the service locator (`GetIt`) and provided through `BlocProvider` at the route level.
- State classes should be simple, using distinct classes or sealed types for each state (e.g., `ChatInitial`, `ChatLoading`, `ChatLoaded`, `ChatError`).

### Dependency Injection — GetIt

- All dependencies are registered in `lib/service/service_locator.dart` via the `DI.execute()` method.
- Use `registerFactory` for transient dependencies, `registerLazySingleton` for singletons.
- Follow the registration order: **Network → Services → Repositories → Cubits**.
- Access dependencies via `serviceLocator<T>()`.

### Navigation — GoRouter

- All routes are defined in `lib/routes/pages.dart` using `GoRouter`.
- Route path constants live in `lib/routes/paths.dart` inside the `AppPaths` class.
- The `AppPaths` constructor is private (`AppPaths._()`) — keep it that way for all constant-only classes.

### Repository Pattern

- Repositories provide an abstraction over data sources.
- Define an **abstract class** (e.g., `ChatRepository`) and a concrete **implementation** (e.g., `ChatRepositoryImpl`).
- Repositories should return `Either<CommonFailedModel, T>` (from the `dartz` package) for error handling.

### Error Handling

- Use the `dartz` `Either` type for functional error handling (`Left` = failure, `Right` = success).
- Network failures are modeled via `CommonFailedModel` and `DioFailure` in `lib/core/error/`.
- Retryable DioExceptions (timeouts, 5xx, 429, 408) should be retried with exponential backoff.

---

## Coding Conventions

### Dart / Flutter Style

- Follow the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style) and the lint rules in `analysis_options.yaml`.
- Use **trailing commas** on all parameter lists and collection literals for better formatting.
- Prefer `const` constructors wherever possible.
- Use `super.key` in widget constructors (Dart 3 super-parameters style).
- Prefer relative imports within `lib/` for sibling files; use package imports (`package:chat_app/...`) for cross-module references.

### Naming

- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables / functions: `camelCase`
- Constants: `camelCase` (not `SCREAMING_SNAKE_CASE`)
- Private members: prefix with `_`
- Cubits: `<Feature>Cubit` (e.g., `ChatCubit`)
- States: `<Feature><StateName>` (e.g., `ChatLoading`)
- Models: `<Name>Model` or `<Name>Response` / `<Name>RequestBody`
- Repositories: `<Feature>Repository` (abstract), `<Feature>RepositoryImpl` (concrete)

### File Organization

- One primary class per file. Helper/private classes may co-locate if tightly coupled.
- Group imports in order: `dart:` → `package:flutter/` → third-party packages → project imports.
- Keep widget files focused — extract complex sub-widgets into the `widgets/` subdirectory.

---

## Network Layer

- **Dio** is the HTTP client, configured in `lib/core/network/dio_services.dart`.
- `PrettyDioLogger` is enabled only in debug mode (`kDebugMode`).
- API keys are injected via interceptors — **never hardcode secrets in committed code** (use environment variables or `.env` files for production).
- The Gemini API base URL is: `https://generativelanguage.googleapis.com/v1beta/models/`

---

## Testing

- Unit tests go in `test/` mirroring the `lib/` structure.
- Use `mocktail` for mocking dependencies in tests.
- Test cubits by verifying state emissions.
- Test repositories by mocking the service layer.

---

## Key Dependencies

| Package              | Purpose                          |
|----------------------|----------------------------------|
| `flutter_bloc`       | State management (Cubit/BLoC)    |
| `dio`                | HTTP networking                  |
| `pretty_dio_logger`  | Debug-only request/response logs |
| `go_router`          | Declarative routing              |
| `get_it`             | Dependency injection             |
| `dartz`              | Functional error handling        |
| `mocktail`           | Testing mocks                    |

---

## Do's and Don'ts

### Do

- ✅ Create a new subdirectory under `features/` for each new feature.
- ✅ Register all new dependencies in `service_locator.dart`.
- ✅ Use `Either` for all service/repository return types that can fail.
- ✅ Write widget tests and cubit tests for new features.
- ✅ Preserve all existing comments and docstrings unrelated to your changes.
- ✅ Use `const` wherever the compiler allows it.

### Don't

- ❌ Put business logic directly in widgets — delegate to Cubits.
- ❌ Use `setState` for complex state — always use Cubit.
- ❌ Import files from `features/` into `core/` — dependencies flow **core → features**, never the reverse.
- ❌ Hardcode API keys in source files — use secure configuration.
- ❌ Skip error handling — always handle `Left` (failure) paths from `Either`.
