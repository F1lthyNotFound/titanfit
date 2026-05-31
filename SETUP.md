# TitanFit — setup (Arch Linux)

## Why `/usr/bin/flutter` fails

Arch `flutter` + `dart` packages can desync → `Wrong full snapshot version`.

**Fix:** use Flutter cloned to `~/flutter` (already installed by setup). Always put it **before** `/usr/bin` in `PATH`.

## One-time: shell PATH

Add to `~/.bashrc` (or `~/.zshrc`):

```bash
export PATH="$HOME/flutter/bin:$PATH"
```

Then:

```bash
source ~/.bashrc
flutter doctor
```

Or run any command via:

```bash
./scripts/flutter.sh doctor
./scripts/flutter.sh pub get
./scripts/flutter.sh run
```

## Optional: fix Arch packages (needs sudo)

If you prefer system Flutter later:

```bash
sudo pacman -Syu flutter dart
```

Only use **one** Flutter on PATH — not both `~/flutter` and `/usr/bin/flutter`.

## Android (for APK / device)

`flutter doctor` may warn about cmdline-tools. Install Android Studio or cmdline-tools, set:

```bash
export ANDROID_HOME="$HOME/android-sdk-home"   # your SDK path
flutter doctor --android-licenses
```

## Run the app

```bash
cd "/home/lawliet/Documents/Titanlabs app/titanfit"
flutter pub get
flutter run
```

Point API at your backend:

```bash
flutter run --dart-define=TITAN_API_BASE=https://YOUR-RAILWAY-URL
```

Or edit `lib/config/api_config.dart` → `defaultApiBase`.

## Release APK (GitHub)

1. Push this repo to GitHub (`YOUR_ORG/titanfit`).
2. Tag: `git tag v0.1.0 && git push origin v0.1.0`
3. Actions uploads `titanfit-release.apk` to Releases.
4. On Titan Labs server set `TITANFIT_RELEASE_APK_URL` if org/repo name differs.

## Web (titanlabs repo) — you still do

1. Deploy `api/controllers/app.php` + landing/download panel changes.
2. Design Settings → Landing → enable **App install** panel → save.
3. Test: `GET /api/controllers/app.php?action=get_flavor&gym=YOUR-SLUG`
