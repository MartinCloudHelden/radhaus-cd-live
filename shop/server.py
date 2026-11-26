"""Kleiner Webserver für den Radhaus-Shop.

Endpunkte:
  /           Startseite mit Version
  /health     Lebenszeichen für Smoke Tests ("ok")
  /versand    Versandkosten als JSON, z. B. /versand?wert=50.00
"""

import json
import os
from decimal import Decimal, InvalidOperation
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

from shop import __version__
from shop.versand import gesamtpreis, versandkosten

COMMIT = os.environ.get("GIT_SHA", "unbekannt")[:7]


class RadhausHandler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:
        url = urlparse(self.path)
        if url.path == "/health":
            self._antworten(200, "text/plain", "ok")
        elif url.path == "/versand":
            self._versand(parse_qs(url.query).get("wert", [""])[0])
        elif url.path == "/":
            self._antworten(
                200,
                "text/html",
                f"<h1>Radhaus</h1><p>Version {__version__} (Commit {COMMIT})</p>",
            )
        else:
            self._antworten(404, "text/plain", "nicht gefunden")

    def _versand(self, wert: str) -> None:
        try:
            warenwert = Decimal(wert)
            daten = {
                "warenwert": f"{warenwert:.2f}",
                "versandkosten": f"{versandkosten(warenwert):.2f}",
                "gesamtpreis": f"{gesamtpreis(warenwert):.2f}",
            }
        except (InvalidOperation, ValueError):
            self._antworten(400, "application/json", '{"fehler": "ungültiger Wert"}')
            return
        self._antworten(200, "application/json", json.dumps(daten))

    def _antworten(self, status: int, typ: str, inhalt: str) -> None:
        daten = inhalt.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", f"{typ}; charset=utf-8")
        self.send_header("Content-Length", str(len(daten)))
        self.end_headers()
        self.wfile.write(daten)


def main() -> None:
    port = int(os.environ.get("PORT", "8080"))
    print(f"Radhaus {__version__} läuft auf Port {port}", flush=True)
    ThreadingHTTPServer(("0.0.0.0", port), RadhausHandler).serve_forever()


if __name__ == "__main__":
    main()
