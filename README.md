# Pulse: AI fitness coach

A Flutter app (iOS, Android, web) that builds a personal workout with AI, guides you through it with a
rest timer, tracks your progress and answers training and nutrition questions.

**Live demo:** https://pulse.askodev.com

## Features
- **Onboarding in one screen.** Pick a goal, level, equipment and session length, then get a plan in one tap.
- **AI workout plans.** Each plan has sets, reps, rest and a form tip for every exercise. Tap an exercise
  after each set and a rest countdown starts. If the AI can't be reached, the app falls back to a
  built-in plan, so you're never stuck.
- **Progress.** Day streak, workouts this week, total minutes, a 7-day chart and your history.
- **AI coach chat.** Answers use your profile and reply in your language.
- **Settings.** Edit your profile, choose light, dark or system theme, and clear your data.
- Designed loading, empty and error states. Material 3 with light and dark themes. Responsive from
  phone (bottom navigation) to desktop (navigation rail). Installable as a PWA.

## Architecture
```
lib/
  models.dart         Profile, Plan, Exercise, WorkoutLog: defensive JSON parsing
  api.dart            CoachApi: HTTP client with timeouts and typed errors
  store.dart          AppStore (ChangeNotifier): state + persistence (shared_preferences)
  stats.dart          Streak and weekly stats (pure functions)
  fallback_plan.dart  Offline plans per equipment and level
  screens/            onboarding, today, progress, coach, settings
functions/api/coach.js  Cloudflare Pages Function: Workers AI (Llama 3.3 70B),
                        validates and clamps all input and output; no API key in the app
test/                 Unit tests (stats, parsing, fallback) + widget tests (full journey, offline mode)
```
State is managed with a `ChangeNotifier` exposed through an `InheritedNotifier`, with no extra packages.
Data stays on the device.

## Run
```bash
flutter pub get
flutter test
flutter run                       # mobile (uses API_BASE, default https://pulse.askodev.com)
flutter build web --release       # web build in build/web
```

## How it was built
I built this app with AI coding tools (Claude Code), and I reviewed, tested and debugged every
change myself: 13 automated tests, plus browser checks of the full journey at phone and desktop sizes.
