# Poker Master

An iOS poker trainer that drills the three skills that decide most hands: preflop range discipline,
equity estimation, and postflop play against opponents who behave like real player types.

SwiftUI + SwiftData client, backed by a Python/FastAPI service on Cloud Run that handles the
Monte Carlo simulation and hand evaluation. Both halves built and shipped solo.

This repo is the iOS client. The backend lives in a separate private repo; it's described below
because the split is the interesting part of the design.

---

## Training modes

**Basic Preflop** — Heads-up spots generated from a bundled range chart (340+ raise/call entries
covering 6-max and 9-max, from opens through 5-bets). You act, the app scores your action against the
chart and shows what the range actually does in that spot. Charts are editable in-app, so you can
drill your own strategy rather than the shipped default.

**Equity Drill** — You get a hand, a board, and either a villain range or a specific villain hand, and
estimate your equity. The backend scores it by simulation. Scenarios are generated ahead of you into a
three-deep queue, so the next spot is ready the moment you answer the current one.

**Play AI** — Six-handed table against twelve AI profiles (Nit, Maniac, Call Station, Tactician, and
friends). Full betting engine: blinds and position rotation, four streets, all-ins with side pots, and
showdown evaluation.

**Tools** — Range viewer/editor, per-mode statistics, XP and levelling, and tiered challenges.

---

## Architecture

```
┌──────────────────────────────┐         ┌────────────────────────────────┐
│  iOS app (SwiftUI)           │         │  FastAPI on Cloud Run          │
│                              │         │                                │
│  Game managers               │  HTTPS  │  /api/v1/equity/from-range     │
│  ├─ SimplePreFlopManager ────┼── + ────┼─ /api/v1/equity/from-hand      │
│  ├─ EquityDrillManager       │  Bearer │  /api/v1/ai/decision           │
│  └─ AIGameManager            │  token  │  /api/v1/ai/determine-winner   │
│                              │         │  /api/v1/ai/players            │
│  SwiftData (local history)   │         │                                │
│  RevenueCat (entitlements)   │         │  Firebase ID token on every    │
│  Firebase Auth               │         │  route; treys for evaluation   │
└──────────────────────────────┘         └────────────────────────────────┘
                                                       ▲
                                          GitHub Actions → Terraform
```

Preflop training runs entirely on-device — it's a chart lookup, and it has to work on a plane.
Everything involving equity runs server-side: a single AI decision is 2,500–10,000 simulated hands, which
is a poor use of a phone's battery and a good way to stall the main thread. Keeping it on the server
also means AI behaviour and simulation counts can be retuned without an App Store release.

### AI decision model

An AI profile is four floats: `aggression`, `tightness`, `adaptive`, `bluff_frequency`. A decision is:

1. Estimate hand equity by Monte Carlo against `n` random opponents.
2. Build a calling threshold from the pot odds, widened by `tightness` and narrowed by `adaptive`.
3. Roll `bluff_frequency` for a temporary equity boost.
4. Fold below the threshold, call inside a 10-point corridor above it, and above that raise with a
   probability drawn from a logistic curve on the equity surplus, scaled by `aggression`.

The scoring step is a pure function with the RNG injected, which makes it both unit-testable and
measurable. A profiling script sweeps every profile across a grid of equity × pot odds × opponent
count and renders the resulting action-rate curves, so tuning a profile is a measured change rather
than a guess.

### Auth

First launch signs in anonymously, so nothing stands between opening the app and training. An account
can be upgraded later to email/password or Sign in with Apple, and the anonymous credential is linked
rather than replaced, so history and XP survive. Every backend route sits behind a Firebase ID token
dependency; `APIClient` transparently retries once with a force-refreshed token on a 401, and gives up
after that instead of looping.

### Persistence

Each session writes a `Game` with per-hand `PreflopLog` / `EquityLog` / `AIGameLog` children via
SwiftData. That one store powers the statistics screens, challenge progress, and the free-tier limit
(20 hands per day per mode), which is just a date-bounded `#Predicate` rather than a separate counter
to keep in sync.

---

## Stack

| Area | Choice |
| --- | --- |
| UI | SwiftUI, iOS 17.4+, Swift 5 |
| Local storage | SwiftData |
| Auth | Firebase Auth (anonymous, email, Sign in with Apple) |
| Purchases | RevenueCat / StoreKit |
| Backend | FastAPI, Pydantic, [treys](https://github.com/ihendley/treys) |
| Infra | Cloud Run, Artifact Registry, Secret Manager, Terraform |
| CI/CD | GitHub Actions — pytest, ruff, Docker build, `terraform apply` |

## Layout

```
Poker Master/
├── Models/          Card, Deck, Player, AIPlayer + SwiftData models
├── Services/
│   ├── APIs/        APIClient, EquityAPI, VsAIAPI
│   ├── Games/       SimplePreFlopManager, EquityDrillManager, AIGameManager
│   └── ...          Auth, RangeHelper, SubscriptionManager, Log
├── State/           UserProfileState
├── Views/           Home, Play (Preflop / Equity / AI), Ranges, Stats, Profile
└── Utils/
Poker MasterTests/   XCTest unit tests
Ranges.json          Bundled preflop charts, copied to Documents on first launch
```

## Build

```bash
open "Poker Master.xcodeproj"
```

Or from the command line:

```bash
xcodebuild -project "Poker Master.xcodeproj" -scheme "Poker Master" \
  -destination "platform=iOS Simulator,name=iPhone 16" build
```

Dependencies resolve through Swift Package Manager. Running against a local backend is a one-line
change in [APIConfig.swift](Poker%20Master/Services/APIs/APIConfig.swift) — switch the environment to
`.local`.

## Tests

142 unit tests, weighted toward the parts that are expensive to get wrong: the betting loop
(`AIGameManagerTests` covers pot accounting, side pots, all-in edge cases, and non-convergence
guards), plus deck, player, and AI state. The backend adds 22 pytest tests over the decision model,
equity calculator, and auth dependency.

```bash
xcodebuild -project "Poker Master.xcodeproj" -scheme "Poker Master" \
  -destination "platform=iOS Simulator,name=iPhone 16" test
```
