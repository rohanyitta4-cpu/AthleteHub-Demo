# AthleteHub Demo

**Public, readable Flutter UI sample** for AthleteHub — a baseball & softball stats tracking app for players.

This repo is for **code review and portfolio browsing**. It is **not** the full production product and is **not** set up to run against a live backend out of the box.

---

## What AthleteHub is

Players log games, review season stats and charts, see Scout-style ranks after enough games, and manage profile/settings. The main app shell uses five bottom tabs:

| Tab | What to look at in this repo |
|-----|------------------------------|
| **Home** | `lib/screens/dashboard_screen.dart`, `lib/widgets/dashboard/` (rank hero card, recent games, quick stats) |
| **Stats** | `lib/screens/enhanced_stats_screen.dart`, `lib/widgets/charts/`, stat hero / game log widgets |
| **Log game** | `lib/stats_entry_screen.dart` (flashcards), `lib/stats_quiz_screen.dart` (Zuno chat UI) |
| **History** | `lib/history_screen.dart` |
| **Account** | `lib/account_screen.dart`, `lib/screens/*_settings_screen.dart` |

Also useful: `lib/main_navigation_screen.dart` (tabs + menu), `lib/screens/onboarding_screen.dart`, `lib/theme/`, `lib/utils/player_rank.dart`.

---

## What’s in this public repo

- Flutter **client UI** — screens, widgets, themes, models, navigation
- Sample **Firestore / Storage rules** files (for reading structure, not production secrets)
- Unit **tests** under `test/` for some client helpers

## What’s *not* included (private / production only)

- Cloud Functions (Scout scoring, Zuno/AI backends)
- In-app purchases / Pro billing
- PDF report & spreadsheet export services
- Production Firebase config (`GoogleService-Info.plist`, etc.)
- Deploy scripts, API keys, and internal ops docs

The complete product lives in a **separate private** repository.

---

## How to browse the code

1. Start at `lib/main.dart` → auth gate → `lib/main_navigation_screen.dart`
2. Open the player tabs listed above
3. Rank / Scout **UI** lives mainly under `lib/widgets/dashboard/` and `lib/screens/performance_report_screen.dart`
4. Shared look & feel: `lib/theme/`

You do **not** need to build the app to review the UI structure.

### If you try to run it anyway

```bash
git clone https://github.com/rohanyitta4-cpu/AthleteHub-Demo.git
cd AthleteHub-Demo
flutter pub get
```

Expect missing Pro modules, Firebase config, and backend callables. This tree is intentionally incomplete for a safe public sample.

---

## Stack (client)

- Flutter / Dart  
- Firebase client SDKs (Auth, Firestore, etc. — wiring incomplete without your own project)  
- Provider, charts (`fl_chart`), Google Fonts  

---

## License

All rights reserved. This code is shared for reading and evaluation only. Do not redistribute or ship as a competing product without permission.
