# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
flutter pub get

# Run the app (Android or Chrome)
flutter run
flutter run -d chrome

# Analyze / lint
flutter analyze

# Run tests
flutter test

# Build
flutter build apk          # Android APK
flutter build appbundle    # Android AAB (Play Store)
flutter build web          # Web
```

## Architecture

**Wedpilot** is a cross-platform (Android + Web) wedding planning app with three distinct user roles: **Couple**, **Vendor**, and **Admin**. Role is determined at login time from the email pattern (demo mode — `vendor@…` → vendor, `admin@…` → admin, anything else → couple).

### State management — Riverpod

All state lives in `lib/providers/`. The central one is `authProvider` (`StateNotifierProvider<AuthNotifier, AuthState>`). `AuthState` carries the logged-in `User`, the role-specific profile (`CoupleProfile` or `VendorProfile`), and loading/error flags. Convenience providers (`currentUserProvider`, `coupleProfileProvider`, `vendorProfileProvider`) derive from it.

The router watches `authProvider` via `_RouterNotifier` (a `ChangeNotifier` fed by `ref.listen`) and re-evaluates redirects on every auth state change. This is what drives the splash → onboarding → login → role-shell flow automatically.

`settingsProvider` (`NotifierProvider<SettingsNotifier, AppSettings>`) persists theme mode, font size, and notification prefs to a Hive box (`app_settings`). Auth tokens are stored separately in Flutter Secure Storage via `lib/core/services/token_service.dart`.

### Navigation — GoRouter + StatefulShellRoute

`lib/core/router/app_router.dart` owns all routes. The key structural pieces:

- **Global redirect** — unauthenticated requests go to `/login`; authenticated users on auth screens are sent to their role home (`/couple/dashboard`, `/vendor/dashboard`, `/admin/dashboard`).
- **Three `StatefulShellRoute.indexedStack` shells** — `CoupleShell`, `VendorShell`, `AdminShell`. Each shell preserves tab state across switches. The shell widget owns the `NavigationBar` (bottom nav) and the `AppDrawer` (slide-in menu, couple shell only).
- **Push routes** — settings, notifications, checklist, messages, etc. are pushed on top of the shell (no bottom nav).
- **Public route** — `/i/:shareToken` (public invitation view) bypasses auth.

The three shell widgets live in `lib/shell/`. `CoupleShell` is a `StatefulWidget` with a `GlobalKey<ScaffoldState>` shared down the tree via `ShellScaffold` (`lib/core/inherited/shell_scaffold.dart`) so that inner screens can open the drawer with `ShellScaffold.of(context)?.scaffoldKey.currentState?.openDrawer()`.

### Theming

`lib/core/theme/app_theme.dart` defines both light and dark `ThemeData` (Material 3). `lib/core/theme/app_colors.dart` is the single source of truth for all colors — do not inline color literals. `lib/core/theme/app_text_styles.dart` exposes static getters (`AppTextStyles.headlineLarge`, `.bodySmall`, etc.) using Google Fonts Playfair Display (headings) and Inter (body).

`AppSettings.fontSize` drives a `textScaler` multiplier in `lib/app.dart` so all text scales with user preference. High-contrast and reduced-motion flags are also read here.

### Models

All models in `lib/models/` carry `toJson`/`fromJson` factories and use computed getters for derived values (e.g. `CoupleProfile.daysUntilWedding`, `Budget.remainingBudget`, `Budget.isOverBudget`). They use `equatable` for value equality. The most structurally complex are:

- `VendorProfile` — nested `VendorService`, `VendorMedia`, and `VendorMatch` scoring (reputation, budget, location, availability).
- `Budget` — `BudgetCategory` (allocated vs spent), `BudgetCustomItem`, `Expense` (with receipt URLs).
- `Invitation` — `InvitationTemplate` (free/premium), `RsvpResponse`, `Guest` list, share channels.

Default budget allocations and vendor categories are constants in `lib/core/constants/app_constants.dart`.

### Feature screens

Screens live under `lib/features/<feature>/screens/`. Features: `auth`, `couple`, `vendor`, `admin`, `invitation`, `shared`. Screens are `ConsumerWidget` or `ConsumerStatefulWidget` and import only what they need from providers.

### Widgets

`lib/widgets/` holds reusable components: `WedButton`, `WedCard`, `AppDrawer`, `LoadingShimmer`, `WedSnackbar`. Prefer these over raw Material widgets to stay consistent.
