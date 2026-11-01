# Overview & Stack

- **Project Type**: Flutter cross-platform client application (`coder_flutter`)
- **Language**: Dart (SDK ^3.9.2)
- **Framework**: Flutter (Material Design UI, WebSocket transport, custom RPC/session state management)

## Essential Commands

- **Setup Dependencies**: `flutter pub get`
- **Build / Codegen**: `flutter pub run flutter_launcher_icons` or `dart run tool/generate_icons.dart`
- **Lint / Static Analysis**: `flutter analyze`
- **Full Test Suite**: `flutter test`
- **Single Test Execution**: `flutter test test/widget_test.dart`

## Architecture & Directory Layout

- `lib/main.dart`: Application entry point.
- `lib/core/`: Core infrastructure including RPC clients, WebSocket transport (`transport/`), services (`services/`), theming, and shared widgets.
- `lib/models/`: Data classes and immutable models (e.g., chat messages, sessions).
- `lib/state/`: State management logic (`coder_state.dart`).
- `lib/views/`: UI views and components split into domain folders (`chat/`, `sidebar/`, `settings/`, `history/`, `widgets/`).
- `tool/`: Build and code generation utility scripts.
- `test/`: Unit and widget tests.

## Code Style & Conventions

- Adhere to official Dart style guidelines and `package:flutter_lints/flutter.yaml` rules configured in `analysis_options.yaml`.
- Use strong typing, explicit return types where appropriate, and avoid dynamic casting unless necessary.
- Follow existing patterns for state management and modular view components.

## Agent Rules & Guardrails

- **Guard Clause**: Never overwrite or modify `AGENTS.md` if it already exists.
- Do not manually modify generated files or configuration files unless requested (e.g. pubspec lockfiles / asset outputs).
- Always verify changes locally using `flutter analyze` and `flutter test`.
