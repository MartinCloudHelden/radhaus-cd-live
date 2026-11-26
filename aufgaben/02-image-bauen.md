# Aufgabe 2: Image bauen und ablegen

⏱ ca. 15 Minuten · [Zurück zur Übersicht](../README.md) · Folien: *Build once, deploy many* · *Versionen* · *Das Image in der Pipeline: Tag oder Digest?*

## Worum geht es?

Aus dem getesteten Code wird **genau einmal** ein Container-Image gebaut. Es bekommt als Namen den **Commit-SHA** – so lässt sich jedes Image eindeutig einem Stand im Code zuordnen. Danach kommt es in die **Registry**, den zentralen Ablageort für Images. Von dort holen es später Staging und Produktion: *Build once, deploy many*.

Du musst nichts selbst programmieren. Du legst eine Datei an, fügst den Baustein ein und **beobachtest**, was passiert.

## Schritt für Schritt

1. Öffne im Repository **Add file → Create new file**.
2. Dateiname: `.github/workflows/cd.yml` (mit Punkt am Anfang, die Schrägstriche legen die Ordner an).
3. Füge diesen Inhalt ein:

```yaml
name: CD

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-python@6d4fd22b20465ccc0f7354476588e8df7c9ca0e0 # v7.1.0
        with:
          python-version: '3.13'
      - run: python -m pip install -r requirements-dev.txt
      - run: python -m pytest -q --cov=shop --cov-report=term-missing --cov-fail-under=90

  build:
    needs: test
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v7
      - name: Image-Namen festlegen
        run: echo "IMAGE=ghcr.io/${GITHUB_REPOSITORY,,}:${GITHUB_SHA}" >> "$GITHUB_ENV"
      - name: Image bauen
        run: docker build --build-arg GIT_SHA="$GITHUB_SHA" --tag "$IMAGE" .
      - name: Bei GHCR anmelden
        uses: docker/login-action@8aa5831fb8d48d8f76594c7ddde61ae58019f550 # v4.8.0
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Image pushen
        run: docker push "$IMAGE"
```

4. **Commit changes** → direkt auf `main`.
5. Öffne den Tab **Actions** und klicke auf den neuen Lauf **CD**.

## Was steht da?

| Zeilen | Bedeutung | Folie |
|---|---|---|
| `on: push: branches: [main]` | Läuft bei jeder Änderung auf `main` | Dienstag: Events |
| `test:` | Erst testen – nichts Ungetestetes wird gebaut | Dienstag: Gates |
| `needs: test` | `build` startet nur, wenn `test` grün ist | Dienstag: `needs` |
| `packages: write` | **Nur dieser Job** darf in die Registry schreiben | Least Privilege |
| `IMAGE=ghcr.io/…:${GITHUB_SHA}` | Name des Images = Repository + Commit-SHA | Versionen |
| `docker build` / `docker push` | Image bauen, dann in die Registry legen | Build once |
| `password: ${{ secrets.GITHUB_TOKEN }}` | Automatischer, kurzlebiger Schlüssel – kein selbst angelegtes Passwort | Secrets |

## Beobachten

- Im Lauf siehst du zwei Kästen: `test` → `build`. Der Pfeil ist das Gate.
- Klicke auf `build` → Step **Image pushen**. Am Ende steht `digest: sha256:…`.
- Geh zur Startseite deines Repositorys. Rechts unter **Packages** steht jetzt `radhaus-cd`. Klick darauf: Der Tag ist ein 40-stelliger SHA.

## Geschafft, wenn …

- der Lauf `CD` mit `test` → `build` grün ist,
- unter **Packages** das Image mit dem Commit-SHA als Tag liegt.

## Zum Mitnehmen für die Prüfung

**Warum ist der Commit-SHA ein besserer Name als `latest`?**

<details>
<summary>Antwort</summary>

Der SHA zeigt eindeutig auf genau einen Stand des Codes. `latest` heißt nur „zuletzt hochgeladen“ und ändert sich ständig. Damit weiß niemand, was läuft, und ein Rollback auf „das vorherige `latest`“ ist nicht möglich.

</details>

**Im Lauf steht `digest: sha256:…`. Was ist der Unterschied zwischen Tag und Digest?**

<details>
<summary>Antwort</summary>

Ein Tag ist nur ein Name und kann neu vergeben werden – jemand kann ein anderes Image mit demselben Tag hochladen. Der Digest ist ein Hash über den Inhalt und damit unveränderlich. Für Produktion daher per Digest deployen oder Tags in der Registry unveränderlich machen.

</details>

**Warum bekommt nur `build` das Recht `packages: write`?**

<details>
<summary>Antwort</summary>

Least Privilege: Nur dieser Job muss schreiben. Wird ein anderer Job manipuliert, kann er kein Image in der Registry überschreiben.

</details>

<details>
<summary>Die komplette <code>cd.yml</code> nach dieser Aufgabe – zum Vergleich</summary>

```yaml
name: CD

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-python@6d4fd22b20465ccc0f7354476588e8df7c9ca0e0 # v7.1.0
        with:
          python-version: '3.13'
      - run: python -m pip install -r requirements-dev.txt
      - run: python -m pytest -q --cov=shop --cov-report=term-missing --cov-fail-under=90

  build:
    needs: test
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v7
      - name: Image-Namen festlegen
        run: echo "IMAGE=ghcr.io/${GITHUB_REPOSITORY,,}:${GITHUB_SHA}" >> "$GITHUB_ENV"
      - name: Image bauen
        run: docker build --build-arg GIT_SHA="$GITHUB_SHA" --tag "$IMAGE" .
      - name: Bei GHCR anmelden
        uses: docker/login-action@8aa5831fb8d48d8f76594c7ddde61ae58019f550 # v4.8.0
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Image pushen
        run: docker push "$IMAGE"
```

</details>

<details>
<summary>Tipp: Der Lauf ist rot</summary>

- `invalid reference format: repository name must be lowercase` → Hast du den Step **Image-Namen festlegen** unverändert übernommen? `${GITHUB_REPOSITORY,,}` macht alles klein.
- `denied` oder `unauthorized` beim Push → Steht `packages: write` unter `build`? Ist die Einrückung gleich wie im Baustein?
- `mapping values are not allowed` oder Ähnliches → Einrückung. YAML braucht **Leerzeichen**, keine Tabs. Vergleiche mit der kompletten Datei oben.

</details>

## Doku

- [GitHub: Docker-Images veröffentlichen](https://docs.github.com/en/actions/tutorials/publish-packages/publish-docker-images)
- [GitHub: Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
