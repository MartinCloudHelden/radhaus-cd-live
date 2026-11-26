# Aufgabe 4: Staging mit Smoke Test

⏱ ca. 10 Minuten · [Zurück zur Übersicht](../README.md) · Folien: *Testszenarien* · *Environments*

## Worum geht es?

Bevor etwas in Produktion geht, läuft es in einer produktionsnahen Umgebung: **Staging**. Der Job holt das Image **aus der Registry** – es wird **nicht neu gebaut** – startet es und prüft mit einem **Smoke Test**, ob der Shop lebt. Das Skript dafür ist fertig: `scripts/smoke-test.sh`.

## Schritt für Schritt

1. Öffne `.github/workflows/cd.yml` zum Bearbeiten.
2. Füge diesen Baustein **ganz unten** an. Eine Leerzeile davor; `staging:` steht genau so weit eingerückt wie `build:` (2 Leerzeichen):

```yaml
  staging:
    needs: build
    runs-on: ubuntu-latest
    environment: staging
    permissions:
      contents: read
      packages: read
    steps:
      - uses: actions/checkout@v7
      - name: Image-Namen festlegen
        run: echo "IMAGE=ghcr.io/${GITHUB_REPOSITORY,,}:${GITHUB_SHA}" >> "$GITHUB_ENV"
      - name: Bei GHCR anmelden
        uses: docker/login-action@8aa5831fb8d48d8f76594c7ddde61ae58019f550 # v4.8.0
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Smoke Test
        run: bash scripts/smoke-test.sh "$IMAGE"
```

3. Committe auf `main` und öffne den Lauf.

## Was steht da?

| Zeile | Bedeutung | Folie |
|---|---|---|
| `needs: build` | Staging startet erst, wenn das Image gescannt und abgelegt ist | Pipeline-Stufen |
| `environment: staging` | Der Job gehört zur Umgebung **Staging** – GitHub protokolliert das als Deployment | Environments |
| `packages: read` | Staging darf das Image nur **lesen** | Least Privilege |
| `smoke-test.sh "$IMAGE"` | Startet genau das Image mit diesem SHA und prüft `/health` und die Versandkosten | Smoke Test |

## Beobachten

- Der Lauf hat jetzt drei Kästen: `test` → `build` → `staging`.
- Im Step **Smoke Test**: „✅ /health antwortet“ und „✅ Smoke Test bestanden“.
- Auf der Startseite deines Repositorys steht rechts unter **Deployments** jetzt `staging`.
- Vergleiche den Image-Namen im Log von `build` und `staging`: Er ist **identisch**.

## Geschafft, wenn …

- der Lauf `test` → `build` → `staging` grün ist,
- unter **Deployments** der Eintrag `staging` erscheint.

## Zum Mitnehmen für die Prüfung

**Was prüft der Smoke Test, was die Tests im Job `test` nicht prüfen?**

<details>
<summary>Antwort</summary>

Die Tests in `test` prüfen einzelne Funktionen im Code. Der Smoke Test prüft das **fertige, gestartete Image** von außen – inklusive Dockerfile, Abhängigkeiten und Konfiguration. Er beantwortet: Lebt die Anwendung nach dem Deployment?

</details>

**Warum wird für Staging nicht neu gebaut?**

<details>
<summary>Antwort</summary>

Build once, deploy many: Nur so ist das, was in Staging getestet wurde, bitgenau das, was später in Produktion läuft.

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
      - name: Image scannen
        uses: aquasecurity/trivy-action@ed142fd0673e97e23eac54620cfb913e5ce36c25 # v0.36.0
        with:
          image-ref: ${{ env.IMAGE }}
          vuln-type: library
          severity: CRITICAL,HIGH
          ignore-unfixed: true
          exit-code: '1'
      - name: Bei GHCR anmelden
        uses: docker/login-action@8aa5831fb8d48d8f76594c7ddde61ae58019f550 # v4.8.0
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Image pushen
        run: docker push "$IMAGE"

  staging:
    needs: build
    runs-on: ubuntu-latest
    environment: staging
    permissions:
      contents: read
      packages: read
    steps:
      - uses: actions/checkout@v7
      - name: Image-Namen festlegen
        run: echo "IMAGE=ghcr.io/${GITHUB_REPOSITORY,,}:${GITHUB_SHA}" >> "$GITHUB_ENV"
      - name: Bei GHCR anmelden
        uses: docker/login-action@8aa5831fb8d48d8f76594c7ddde61ae58019f550 # v4.8.0
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - name: Smoke Test
        run: bash scripts/smoke-test.sh "$IMAGE"
```

</details>

<details>
<summary>Tipp: Smoke Test meldet „antwortet nicht auf /health“</summary>

Unter dem Fehler steht das Container-Log. Steht dort ein Python-Fehler? Und: Ist der Step `Bei GHCR anmelden` vor dem Smoke Test dabei?

</details>

## Doku

- [GitHub: Environments](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments)
