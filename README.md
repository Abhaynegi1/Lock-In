# LockIn

A competitive and tactile focus timer app built with Flutter.

## Features
- **Solo Mode Focus**: Choose between 15, 25, 45, 60-minute or custom sessions.
- **Strict Anti-Distraction Protection**: If enabled, leaving or backgrounding the app forfeits the session to cultivate unbroken focus.
- **Accountability Battles**: Compete against friends and accountability partners in live focus battles.
- **Streak & Goal Tracking**: Track daily progress against configurable focus goals and consecutive day streaks.
- **Tactile Editorial Aesthetic**: Distinctive warm paper background, rich typography, hand-drawn doodle accents, and clean tactile components.

## Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.10.8+)
- Dart SDK
- Java JDK 17 (for Android builds)

### Installation & Running
1. Clone the repository and install dependencies:
   ```bash
   flutter pub get
   ```
2. Run on a connected device or emulator:
   ```bash
   flutter run
   ```

## Continuous Integration & Quality Checks

This repository is guarded by automated GitHub Actions CI (`.github/workflows/ci.yml`) to ensure that code changes never break in production.

### Local Verification Commands
Before pushing commits or submitting pull requests, run the following verification suite:

1. **Check Code Formatting**:
   ```bash
   dart format --output=none --set-exit-if-changed .
   ```
   *(To auto-format files, run `dart format .`)*

2. **Run Static Code Analysis**:
   ```bash
   flutter analyze --fatal-infos --fatal-warnings
   ```

3. **Run Automated Test Suite & Coverage**:
   ```bash
   flutter test --coverage
   ```

4. **Verify Android Build**:
   ```bash
   flutter build apk --debug
   ```

5. **Verify Web Build**:
   ```bash
   flutter build web --release
   ```
