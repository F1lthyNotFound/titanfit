# TitanFit

Titan Labs member mobile app with **runtime gym flavoring** — one APK, many tenants.

## Setup

```bash
flutter pub get
```

Copy `lib/config/api_config.dart.example` logic: set `defaultApiBase` to your Titan Labs API origin.

## Flavor flow

1. User installs APK from tenant landing (`?gym=slug` on download link).
2. First launch: enter gym code or read slug from deep link / install referrer.
3. App calls `GET /api/controllers/app.php?action=get_flavor&gym=SLUG`.
4. Branding (name, logo, accent hue) cached locally; theme rebuilt.

## Auth

- Register: `auth.php` → `tenant_register` + `gym_slug`
- Login: `app.php` → `mobile_login` (members only, gym-scoped)
- Wrong gym → generic "Wrong username or password"

## Release

Push tag `v*` → GitHub Actions builds `titanfit-release.apk` and uploads to Releases.

```bash
git tag v0.1.0 && git push origin v0.1.0
```

## Design

Base tokens from Titan Labs `docs/DESIGN.md` — monochrome dark-first, Sora/Inter, OKLCH accents from gym `primary_hue`.
