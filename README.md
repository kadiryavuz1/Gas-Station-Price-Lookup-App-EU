# ⛽ GasHop — Fuel Price Tracker

> Find the cheapest fuel near you. A cross-platform Flutter app that shows
> nearby gas stations and their live prices on an interactive map.

GasHop locates fuel stations around the user, compares **Diesel / E5 / E10**
prices, and lets drivers save favourites for quick checks. Station data comes
from the [Tankerkönig](https://creativecommons.tankerkoenig.de/) fuel-price API,
which a **Supabase Edge Function pulls on a schedule** and caches in Postgres —
so the app serves many users from the cache instead of hammering the upstream
API. Nearby-station lookups run as a PostGIS geospatial query, and the map is
rendered with OpenStreetMap tiles — no proprietary map SDK required.

---

## ✨ Features

- 🗺️ **Interactive map** of nearby stations (OpenStreetMap via `flutter_map`)
- 📍 **Radius search** — "stations within _X_ km" backed by a PostGIS RPC
- ⛽ **Live price comparison** across Diesel, E5 and E10 grades
- ⭐ **Favourites** — pin stations you check often
- 🌗 **Material 3** theming with full light/dark support
- 🧭 **Three-tab navigation** — Favourites · Map · Settings
- 📱 Builds for **Android & iOS** from a single codebase

## 🏗️ Architecture

A lightweight layered structure with `provider` for state management:

```
lib/
├── main.dart                     # App entry, DI wiring, Supabase init
├── config/
│   └── supabase_config.dart      # Build-time credentials (--dart-define)
├── models/
│   └── gas_station.dart          # Domain model + JSON mapping
├── repository/
│   └── gas_hop_service.dart      # Supabase RPC access layer
├── data/
│   └── fuel_station_state.dart   # ChangeNotifier app state
├── screens/                      # Favourites · Map · Settings
├── services/
│   └── ad_service.dart           # Google Mobile Ads (test units)
├── widgets/                      # Reusable map + UI widgets
└── utils/                        # Navigation helpers, debouncer
```

**Client data flow:** `UI → FuelStationState (ChangeNotifier) → GasHopService → Supabase RPC (get_nearby_stations) → PostGIS`

## 🔌 Backend & Data Pipeline

> The backend lives **outside this repository** — this repo is the Flutter
> client. It's documented here so the full architecture is clear.

Prices and coordinates originate from the **Tankerkönig** fuel-price API. To
stay within Tankerkönig's fair-use limits and keep the app fast, GasHop does
**not** call that API from the device. Instead:

```
Tankerkönig API
      │  (scheduled pull)
      ▼
Supabase Edge Function  ──► writes/updates ──►  Postgres + PostGIS
                                                      │
                                      get_nearby_stations(lat, lng, radius_km)
                                                      │  (RPC)
                                                      ▼
                                              Flutter app (this repo)
```

- **Ingestion** — a **Supabase Edge Function** runs on a schedule, fetches the
  latest station prices from Tankerkönig, and upserts them into the database.
- **Caching** — all client reads hit the cached Postgres data, so thousands of
  users can be served without flooding the upstream Tankerkönig API.
- **Geospatial query** — `get_nearby_stations` is a PostGIS RPC that returns
  stations within a given radius of the user, with distance computed in-database.
- **Client** — the Flutter app only ever talks to Supabase, never directly to
  Tankerkönig.

## 🧰 Tech Stack

| Area            | Choice                                   |
| --------------- | ---------------------------------------- |
| Framework       | Flutter (Dart)                           |
| State           | `provider` (`ChangeNotifier`)            |
| Backend         | Supabase (PostgreSQL + PostGIS RPC)      |
| Data ingestion  | Supabase Edge Function (scheduled)       |
| Data source     | Tankerkönig fuel-price API               |
| Maps            | `flutter_map` + `latlong2` (OpenStreetMap)|
| Networking      | `http`, `url_launcher`                   |
| Monetization    | `google_mobile_ads` (Google test units) |
| Design          | Material 3                               |

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- A Supabase project exposing a `get_nearby_stations(user_lat, user_lng, max_distance_km)` RPC

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Provide backend credentials

No credentials are committed to this repository. Supply them at build time via
a dart-define file:

```bash
cp dart_define.json.example dart_define.json
# then edit dart_define.json with your Supabase URL + anon key
```

```jsonc
{
  "SUPABASE_URL": "https://YOUR-PROJECT-ref.supabase.co",
  "SUPABASE_ANON_KEY": "your-supabase-anon-or-publishable-key"
}
```

> `dart_define.json` is git-ignored, so your keys never leave your machine.

### 3. Run

```bash
flutter run --dart-define-from-file=dart_define.json
```

Ads use Google's official **test** ad units out of the box, so no AdMob account
is needed to try the app.

## 🔐 Configuration & Secrets

This project keeps all environment-specific values out of version control:

- **Supabase URL / key** → injected with `--dart-define`, read in
  [`lib/config/supabase_config.dart`](lib/config/supabase_config.dart)
- **`dart_define.json`, `*.env`, keystores, `local.properties`** → all
  git-ignored (see [`.gitignore`](.gitignore))

## 🙏 Data Attribution

Fuel-price data is provided by the [Tankerkönig](https://creativecommons.tankerkoenig.de/)
API, licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
Map tiles © [OpenStreetMap](https://www.openstreetmap.org/copyright) contributors.

## 📄 License

Released under the [MIT License](LICENSE).
