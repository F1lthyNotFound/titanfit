#!/usr/bin/env bash
# Use official Flutter SDK (avoids Arch pacman snapshot mismatch on /usr/bin/flutter).
export PATH="${HOME}/flutter/bin:${PATH}"
exec flutter "$@"
