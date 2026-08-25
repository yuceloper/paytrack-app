# PayTrack App Architecture

## Architectural Style

The Flutter app uses a **feature-first** architecture. Each feature owns its data, domain and presentation code so new capabilities can be added without growing one global services/models/screens folder.

```text
lib/
├── core/
│   ├── network/
│   ├── routing/
│   ├── theme/
│   ├── storage/
│   ├── notifications/
│   └── widgets/
└── features/
    ├── dashboard/
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    ├── payments/
    ├── credit_cards/
    ├── loans/
    ├── subscriptions/
    ├── bills/
    ├── calendar/
    └── settings/
```

## Feature Rules

- A feature should expose as little internal implementation as possible.
- Screens/widgets do not call HTTP clients directly.
- API models belong in `data`; UI-independent business models belong in `domain`.
- Riverpod providers orchestrate application state and use cases.
- Cross-feature UI is placed in `core/widgets` only when it is genuinely reusable.
- Avoid generic `utils.dart`, `helpers.dart`, and giant shared model files.

## Data Flow

```text
Widget
  -> Provider / Controller
      -> Repository interface
          -> Repository implementation
              -> API / local storage
```

## Extensibility

Future features such as bank connections, email import, household sharing or AI categorization should be introduced as separate features instead of adding conditionals to existing screens.

## Guiding Principle

**Feature code stays with the feature. Infrastructure stays replaceable. UI stays unaware of transport details.**
