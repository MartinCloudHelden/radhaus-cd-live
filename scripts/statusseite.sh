#!/usr/bin/env bash
# Erzeugt die Statusseite für GitHub Pages im Ordner public/.
# Sie zeigt, welche Version und welches Image gerade "in Produktion" sind.
#
# Nutzung:  bash scripts/statusseite.sh <image>
set -euo pipefail

IMAGE="${1:?Bitte das Image als Parameter angeben}"
VERSION="$(python3 -c 'import shop; print(shop.__version__)')"
ZEIT="$(TZ=Europe/Berlin date '+%d.%m.%Y %H:%M Uhr')"
RUN_URL="${GITHUB_SERVER_URL:-https://github.com}/${GITHUB_REPOSITORY:-}/actions/runs/${GITHUB_RUN_ID:-}"

mkdir -p public
cat > public/index.html <<HTML
<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Radhaus – Produktion</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 40rem; margin: 3rem auto; padding: 0 1rem; color: #1b2a3a; }
    h1 { color: #1f5fa8; }
    dt { font-weight: 600; margin-top: 1rem; }
    dd { margin: 0.25rem 0 0; font-family: ui-monospace, monospace; word-break: break-all; }
  </style>
</head>
<body>
  <h1>🚲 Radhaus – Produktion</h1>
  <dl>
    <dt>Version</dt><dd>${VERSION}</dd>
    <dt>Image</dt><dd>${IMAGE}</dd>
    <dt>Ausgerollt am</dt><dd>${ZEIT}</dd>
    <dt>Pipeline-Lauf</dt><dd><a href="${RUN_URL}">${RUN_URL}</a></dd>
  </dl>
</body>
</html>
HTML

echo "✅ Statusseite erzeugt: public/index.html (Version ${VERSION})"
