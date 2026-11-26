"""Tests für den Webserver. Diese Tests sind bereits fertig."""

import json
import threading
from http.server import ThreadingHTTPServer
from urllib.error import HTTPError
from urllib.request import urlopen

import pytest

from shop import __version__
from shop.server import RadhausHandler


@pytest.fixture(scope="module")
def basis_url():
    server = ThreadingHTTPServer(("127.0.0.1", 0), RadhausHandler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    yield f"http://127.0.0.1:{server.server_port}"
    server.shutdown()


def test_health(basis_url: str) -> None:
    with urlopen(f"{basis_url}/health") as antwort:
        assert antwort.read() == b"ok"


def test_startseite_zeigt_version(basis_url: str) -> None:
    with urlopen(f"{basis_url}/") as antwort:
        assert __version__ in antwort.read().decode()


def test_versand_ab_50_euro_kostenlos(basis_url: str) -> None:
    with urlopen(f"{basis_url}/versand?wert=50.00") as antwort:
        assert json.load(antwort)["versandkosten"] == "0.00"


def test_ungueltiger_wert(basis_url: str) -> None:
    with pytest.raises(HTTPError) as fehler:
        urlopen(f"{basis_url}/versand?wert=abc")
    assert fehler.value.code == 400
