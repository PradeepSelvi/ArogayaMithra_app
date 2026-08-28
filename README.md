# ArogyaMitra

Multilingual care-navigation and referral platform. Flutter + Dart on the client,
Supabase (Postgres) for data, auth, realtime and integration adapters.

Implements the baseline in `ArogyaMitra_Complete_PRD_Dart_Flutter.md`.

## Prerequisites

| Tool | Version used | Notes |
|---|---|---|
| Flutter | 3.41.2 stable | Dart 3.11.0 |
| Docker Desktop | running | required for the local Supabase stack |
| Node.js | 18+ | Supabase CLI is a dev dependency |

On Windows, `flutter.bat` needs PowerShell on `PATH`. If `flutter --version` fails
with "PowerShell executable not found", add
`C:\Windows\System32\WindowsPowerShell\v1.0`.

Android builds additionally need the Android `cmdline-tools` component and accepted
licences (`flutter doctor --android-licenses`). Web works without them.

## Setup

```bash
npm install
npm run db:start          # starts Postgres, Auth, Realtime, Storage, Studio
npm run db:reset          # applies migrations, then seeds one district
flutter pub get
```

## Verify

```bash
npm run db:verify   # 63 domain checks: triage, state machine, RLS, audit
npm run smoke       # 34 checks: the full MVP journey over real JWTs
```

`db:verify` runs SQL assertions in a transaction and rolls back. `smoke` drives the
same API surface the apps use, so it exercises row-level security rather than
bypassing it.

## Run

```bash
flutter run -d chrome --target lib/main.dart   # from the app directory
```

| App | Directory | Audience |
|---|---|---|
| Citizen | `apps/citizen` | care request, triage, facility choice, referral tracking |
| ASHA / ANM | `apps/asha` | households, screening, referral, follow-ups |
| Facility console | `apps/facility` | referral queue, readiness publishing |
| District dashboard | `apps/dho` | alerts, referral KPIs, readiness heatmap |

### Local development accounts

Created by `supabase/seed.sql`. They exist only in local seed data.

| Role | Sign-in | Credential |
|---|---|---|
| Citizen | `+91 98765 00002` | one-time code `123456` |
| Medical officer, District HQ | `mo.district@arogyamitra.local` | `ArogyaMitra@2026` |
| Medical officer, PHC Polur | `mo.polur@arogyamitra.local` | `ArogyaMitra@2026` |
| ASHA worker | `asha@arogyamitra.local` | `ArogyaMitra@2026` |
| District Health Officer | `dho@arogyamitra.local` | `ArogyaMitra@2026` |

The two medical officers are at different facilities on purpose: it demonstrates
that one facility cannot see or act on another's referrals.

### Pointing at a hosted project

```bash
flutter run -d chrome \
  --dart-define=DEPLOYMENT_TARGET=staging \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<key>
```

A non-local build refuses to start with the local development keys.

## Layout

```
apps/           citizen, asha, facility, dho
packages/       core, models, networking, authentication, localization, maps, ui_components
supabase/       migrations, seed, domain check suite
scripts/        verification harnesses
```

Package directories follow PRD 10.1; Dart package names are prefixed `am_`
(`packages/core` is `am_core`).

## Where the rules live

Domain logic that must not be bypassable sits in Postgres, not the client:

- **Triage** is a versioned, clinically owned rule set in `triage_rule_sets` /
  `triage_rules`. Red flags are evaluated first, and unmatched input fails safe to
  medium risk, never self-care. Every assessment stores the rule set version and
  matched rule code.
- **Referral transitions** are rows in `referral_transitions`. A trigger rejects
  anything not in that table, so an illegal transition is impossible from any
  client or role.
- **Readiness scoring** and **facility ranking** read weights from
  `config_versions`, so they are tunable per district without a deployment.
- **Audit** is append-only; `UPDATE` and `DELETE` are blocked by trigger.
- **RLS** is enabled on every table. Oversight roles get aggregate views only, no
  row access to patient records.

## Architecture note

The PRD specifies a Dart backend with Keycloak, Redis and S3. Supabase replaces
those layers: Postgres + RLS for data and authorization, Supabase Auth for
identity, Edge Functions for external adapters, Storage for documents. External
integrations (ABDM, Bhashini, eSanjeevani, ambulance dispatch) sit behind adapter
interfaces in `packages/networking/lib/src/adapters/` with mock implementations, so
a production adapter can be substituted without touching the calling workflow.

## Status against the PRD roadmap

| Phase | State |
|---|---|
| 0 Architecture | done |
| 1 Foundation: apps, auth, roles, database | done |
| 2 Facility readiness | done |
| 3 Triage, scoring, referral state machine | done |
| 4 Offline ASHA (SQLite/Drift, sync queue, conflict handling) | not started |
| 5 Voice and language via Bhashini | interface + mock only |
| 6 ABDM / FHIR | tables and ledger only, no adapter |
| 7 Telemedicine, ambulance | interface + mock only |
| 8 Analytics | views and dashboard done |
| 9 Hardening: load, DR, security review | not started |

The triage rules in `supabase/seed.sql` are a **development baseline and are not
clinically approved**. PRD 16 requires a named clinical owner and a documented
approval record before any deployment.
