#!/usr/bin/env bash
# Smoke Test: startet ein Radhaus-Image und prüft, ob der Shop antwortet.
#
# Nutzung:  bash scripts/smoke-test.sh <image>
# Beispiel: bash scripts/smoke-test.sh ghcr.io/mein-name/radhaus-cd:abc123...
#
# Lokal ist Port 8080 belegt? Dann z. B.: SMOKE_PORT=18080 bash scripts/smoke-test.sh <image>
#
# Endet mit Fehlercode 1, wenn eine Prüfung scheitert – dann wird der Step rot.
set -euo pipefail

IMAGE="${1:?Bitte das Image als Parameter angeben}"
NAME="radhaus-smoke"
PORT="${SMOKE_PORT:-8080}"
URL="http://localhost:${PORT}"

aufraeumen() {
  docker rm --force "$NAME" >/dev/null 2>&1 || true
}
trap aufraeumen EXIT

fehlschlag() {
  echo "❌ $1"
  echo "--- Container-Log ---"
  docker logs "$NAME" || true
  exit 1
}

echo "▶ Starte $IMAGE"
docker run --detach --name "$NAME" --publish "${PORT}:8080" "$IMAGE" >/dev/null

echo "▶ Prüfe $URL/health"
curl --fail --silent --show-error --retry 15 --retry-all-errors --retry-delay 1 \
  "$URL/health" >/dev/null || fehlschlag "Der Shop antwortet nicht auf /health."
echo "✅ /health antwortet"

echo "▶ Prüfe Versandkosten für 50,00 €"
antwort="$(curl --fail --silent --show-error "$URL/versand?wert=50.00")" \
  || fehlschlag "/versand liefert einen Fehler."
echo "   Antwort: $antwort"
[[ "$antwort" == *'"versandkosten": "0.00"'* ]] \
  || fehlschlag "Bei 50,00 € müssen die Versandkosten 0,00 € sein."
echo "✅ Versandkosten stimmen"

echo "✅ Smoke Test bestanden"
