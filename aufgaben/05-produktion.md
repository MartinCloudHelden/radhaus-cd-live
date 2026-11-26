# Aufgabe 5: Freigabe und Produktion

⏱ ca. 20 Minuten · [Zurück zur Übersicht](../README.md) · Folien: *Environments* · *Governance* · Dienstag: *Delivery vs. Deployment*

## Worum geht es?

Der letzte Schritt: **Continuous Delivery**. Nach Staging bleibt die Pipeline stehen, bis ein Mensch zustimmt. Erst dann geht es in Produktion. Wer wann freigegeben hat, wird automatisch protokolliert – der **Audit-Trail**.

„Produktion“ ist hier eine Statusseite auf **GitHub Pages**, die zeigt, welche Version und welches Image live sind. Das Skript `scripts/statusseite.sh` erzeugt sie.

## Teil A: Einstellungen (einmalig, im Browser)

1. **Freigabe einrichten:** **Settings → Environments → New environment**, Name `production` → **Configure environment**. Haken bei **Required reviewers**, dich selbst eintragen. **Prevent self-review** bleibt **aus** – du arbeitest allein. **Save protection rules**.
2. **GitHub Pages einschalten:** **Settings → Pages → Build and deployment → Source: GitHub Actions**.

## Teil B: Zwei Jobs anfügen

Füge diesen Baustein **ganz unten** in `cd.yml` an – wieder 2 Leerzeichen eingerückt, eine Leerzeile davor:

```yaml
  freigabe:
    needs: staging
    runs-on: ubuntu-latest
    environment: production
    steps:
      - run: echo "Freigabe erteilt für $GITHUB_SHA"

  produktion:
    needs: freigabe
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    permissions:
      contents: read
      pages: write
      id-token: write
    steps:
      - uses: actions/checkout@v7
      - name: Image-Namen festlegen
        run: echo "IMAGE=ghcr.io/${GITHUB_REPOSITORY,,}:${GITHUB_SHA}" >> "$GITHUB_ENV"
      - name: Statusseite erzeugen
        run: bash scripts/statusseite.sh "$IMAGE"
      - uses: actions/upload-pages-artifact@v5
        with:
          path: public
      - id: deployment
        uses: actions/deploy-pages@v5
```

## Was steht da?

| Zeile | Bedeutung | Folie |
|---|---|---|
| `freigabe:` mit `environment: production` | Hier wartet der Lauf, bis eine eingetragene Person zustimmt | Environments, Delivery |
| `produktion:` mit `needs: freigabe` | Läuft erst nach der Freigabe | Gates |
| `statusseite.sh "$IMAGE"` | Zeigt **dasselbe Image** an, das in Staging getestet wurde | Build once |
| `pages: write`, `id-token: write` | Nur dieser Job darf die Seite veröffentlichen | Least Privilege |

## Teil C: Ausrollen

1. Committe auf `main`. Der Lauf bleibt bei `freigabe` stehen: **Waiting for review**.
2. Öffne den Lauf, klicke **Review deployments**, wähle `production`, schreib einen Kommentar (z. B. „Staging geprüft“), **Approve and deploy**.
3. Klick nach dem Lauf auf die Adresse beim Job `produktion`. Die Statusseite zeigt Version **1.0.0**.
4. **Eine echte Änderung ausrollen:** Ändere in `shop/__init__.py` die Version auf `1.1.0` und committe. Verfolge den Weg durch alle Stufen, gib frei, und prüfe die Statusseite.

## Geschafft, wenn …

- der komplette Lauf `test` → `build` → `staging` → `freigabe` → `produktion` grün ist,
- die Statusseite **1.1.0** und ein Image mit dem passenden Commit-SHA zeigt,
- unter **Deployments** (rechts auf der Startseite) `production` steht – mit Name und Zeit deiner Freigabe.

## Zum Mitnehmen für die Prüfung

**Wo sieht ein Prüfer später, wer wann die Version 1.1.0 freigegeben hat?**

<details>
<summary>Antwort</summary>

Im Lauf beim Job `freigabe` („Approved by …“ mit Kommentar und Zeit) und unter **Deployments → production**. Dazu kommt die Kette Image → Commit → Lauf. Das ist der Audit-Trail – ohne Excel-Liste.

</details>

**Was müsste man ändern, damit aus Continuous Delivery Continuous Deployment wird?**

<details>
<summary>Antwort</summary>

Den Required reviewer im Environment `production` entfernen (oder den Job `freigabe` streichen). Dann geht jeder grüne Stand automatisch live.

</details>

**Wo ist hier die Funktionstrennung – und wo fehlt sie in der Übung?**

<details>
<summary>Antwort</summary>

Code ändern und freigeben sind getrennte Schritte. In der Übung gibst du dir aber selbst frei. Im Betrieb würde man **Prevent self-review** einschalten, damit eine zweite Person zustimmen muss (Vier-Augen-Prinzip).

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

  freigabe:
    needs: staging
    runs-on: ubuntu-latest
    environment: production
    steps:
      - run: echo "Freigabe erteilt für $GITHUB_SHA"

  produktion:
    needs: freigabe
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    permissions:
      contents: read
      pages: write
      id-token: write
    steps:
      - uses: actions/checkout@v7
      - name: Image-Namen festlegen
        run: echo "IMAGE=ghcr.io/${GITHUB_REPOSITORY,,}:${GITHUB_SHA}" >> "$GITHUB_ENV"
      - name: Statusseite erzeugen
        run: bash scripts/statusseite.sh "$IMAGE"
      - uses: actions/upload-pages-artifact@v5
        with:
          path: public
      - id: deployment
        uses: actions/deploy-pages@v5
```

</details>

<details>
<summary>Tipp: Der Lauf wartet nicht auf meine Freigabe</summary>

- Heißt das Environment im Workflow genau `production` – so wie in den Einstellungen?
- Ist unter **Settings → Environments → production** ein **Required reviewer** eingetragen und gespeichert?
- Ist das Repository **öffentlich**? Freigaben in privaten Repositories gibt es nur mit GitHub Enterprise.

</details>

<details>
<summary>Tipp: Der Job <code>produktion</code> scheitert</summary>

Ist unter **Settings → Pages** als Quelle **GitHub Actions** gewählt?

</details>

## Doku

- [GitHub: Environments und Required Reviewers](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/manage-environments)
- [GitHub: Deployments freigeben](https://docs.github.com/en/actions/how-tos/deploy/configure-and-manage-deployments/review-deployments)
