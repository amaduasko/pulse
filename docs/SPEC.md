# Pulse: AI fitness coach (Flutter)

A portfolio app: a small, finished Flutter app for iOS, Android and the web, with real AI features.

## Journeys and "done" from the user's view

1. **First launch → personal plan in one minute.** Four quick choices (goal, level, equipment,
   session length) on one screen, with sensible defaults. "Create my plan" fetches an AI workout.
   The user never types anything to get started.
2. **Today → do the workout.** The plan shows each exercise with sets, reps, rest and a form tip.
   Tapping an exercise marks its sets one by one. Finishing a set starts a rest countdown.
   "Finish workout" saves it to history. "New plan" asks the AI for another one.
3. **Progress.** The current streak (consecutive days with a workout), workouts this week, total minutes,
   a 7-day bar chart and a list of past workouts. Empty state explains how to get the first entry.
4. **Coach chat.** Ask anything about training or food. Answers come from the AI and use the
   user's profile, in the user's language. Suggested questions fill the empty chat.
5. **Settings.** Change the profile (the next plan uses it), switch light/dark/system theme,
   and clear all data (with confirmation).

## Quality bar
- Every AI call has a loading state, and a designed error state with retry. If the AI fails,
  the plan falls back to a built-in plan for the profile, labeled as such, so the user is never stuck.
- Data stays on the device (shared_preferences). There's no account and no tracking.
- Material 3, light and dark, works at 360–1440px wide, tap targets ≥ 40px, text ≥ 16px in fields.
- The AI runs on a Cloudflare Pages Function (`functions/api/coach.js`) using Workers AI.
  The server validates and caps every input and output, and no key is shipped in the app.
- Tests: streak/stats math, plan parsing and fallback, a widget test of onboarding → plan.
