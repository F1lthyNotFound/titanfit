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

## Build APK locally (for releases)

```bash
cd "/home/lawliet/Documents/Titanlabs app/titanfit"
export PATH="$HOME/flutter/bin:$PATH"
export ANDROID_HOME="$HOME/android-sdk-home"
flutter build apk --release --dart-define=TITAN_API_BASE=https://titanlabs.up.railway.app
cp build/app/outputs/flutter-apk/app-release.apk build/app/outputs/flutter-apk/titanfit-release.apk
```

**Gradle fix applied:** only `*.gradle.kts` files (removed duplicate `build.gradle`). Gradle **9.1.0** + AGP **9.0.1**.

Do **not** use `/usr/bin/flutter` on Arch (snapshot error). Use `~/flutter/bin` only.

## Test via GitHub Release (recommended)

Download from tenant landing or:

https://github.com/F1lthyNotFound/titanfit/releases/latest/download/titanfit-release.apk?gym=YOUR-GYM-SLUG

On first launch enter the gym code shown on the landing page.

## Release APK (GitHub)

1. Push this repo to GitHub (`YOUR_ORG/titanfit`).
2. Tag: `git tag v0.1.0 && git push origin v0.1.0`
3. Actions uploads `titanfit-release.apk` to Releases.
4. On Titan Labs server set `TITANFIT_RELEASE_APK_URL` if org/repo name differs.

## Web (titanlabs repo) — you still do

1. Deploy `api/controllers/app.php` + landing/download panel changes.
2. Design Settings → Landing → enable **App install** panel → save.
3. Test: `GET /api/controllers/app.php?action=get_flavor&gym=YOUR-SLUG`
