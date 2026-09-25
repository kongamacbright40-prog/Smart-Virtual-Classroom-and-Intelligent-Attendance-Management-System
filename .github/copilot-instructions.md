# Copilot instructions — Smart Class

Smart Class is an Android-first Flutter (Material 3) university classroom app
with Student, Lecturer and Administrator experiences. The Flutter project
lives in `scra/` (Dart package `smart_class`).

## Source of truth
- UI: the Google Stitch export (screens 01–40, **there is no screen 37**).
  Recreate designs with Flutter widgets; never use HTML/Tailwind/JS. Do not
  invent screens, backend endpoints or database behaviour.
- Architecture: `scra/docs/architecture.md`; API contract: `scra/docs/api.md`
  + `lib/core/constants/api_endpoints.dart`; entities: `scra/docs/database.md`;
  screen inventory: `scra/docs/screens.md`.

## Rules
1. Inspect existing files first; reuse widgets in `lib/widgets/**`
   (`AppScaffold`, `SmartAppBar`, `AsyncView`, `PrimaryButton`, `AppTextField`,
   cards, `StatusChip`, dialogs...) and tokens (`AppColors`, `AppDimensions`,
   `Formatters`, `Validators`). Do not duplicate components.
2. UI never calls `ApiService`. Screens use repository interfaces from
   `lib/repositories/repositories.dart` (via `context.read<XRepository>()`),
   `AuthProvider`, `SettingsProvider` and `ClassroomController`
   (`ClassroomScope(sessionId: ...)`).
3. New data sources implement the repository interface in
   `lib/repositories/mock/` and `lib/repositories/api/`; wire them in
   `lib/core/di/app_dependencies.dart`.
4. Routes are declared in `lib/core/routing/route_names.dart` and
   `app_router.dart`. Role-scoped routes must start with `/student`,
   `/lecturer` or `/admin` so the guard applies.
5. Models are null-safe with `fromJson`/`toJson` using snake_case keys.
6. Validate every form with `Validators`; handle loading/empty/error states
   (`AsyncView`, `ErrorState` with retry); never let exceptions crash the app.
7. Layouts must not overflow on 360×640 phones: use Expanded/Flexible/Wrap,
   ellipsis and scroll views; no hard-coded screen sizes.
8. No new dependencies without a clear need; no secrets in code; all URLs come
   from `AppConfig` (`--dart-define`).
9. After each change run `flutter analyze` (zero issues) and `flutter test`
   from `scra/`. Write tests for new behaviour under `scra/test/`.
10. Small, focused commits (`feat:`, `fix:`, `test:`, `docs:`...).
