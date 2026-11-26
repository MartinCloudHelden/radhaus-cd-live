# Aufgabe 3: Image scannen

⏱ ca. 15 Minuten · [Zurück zur Übersicht](../README.md) · Folien: *Image scannen mit Trivy* · *Dependabot* · Dienstag: *Shift Left*

## Worum geht es?

Das Image enthält nicht nur unseren Code, sondern auch fremde Bibliotheken. Der Scanner **Trivy** prüft sie auf bekannte Schwachstellen (CVEs). Findet er eine hohe oder kritische Lücke, für die es schon ein Update gibt, stoppt die Pipeline – **bevor** das Image in die Registry kommt. Das ist ein **Gate**.

## Schritt für Schritt

1. Öffne `.github/workflows/cd.yml` und klicke auf den Stift (Bearbeiten).
2. Füge diesen Baustein **zwischen** den Steps `Image bauen` und `Bei GHCR anmelden` ein – gleich weit eingerückt wie `- name: Image bauen`:

```yaml
      - name: Image scannen
        uses: aquasecurity/trivy-action@ed142fd0673e97e23eac54620cfb913e5ce36c25 # v0.36.0
        with:
          image-ref: ${{ env.IMAGE }}
          vuln-type: library
          severity: CRITICAL,HIGH
          ignore-unfixed: true
          exit-code: '1'
```

3. Committe auf `main` und öffne den Lauf im Tab **Actions**.

## Was steht da?

| Zeile | Bedeutung |
|---|---|
| `uses: aquasecurity/trivy-action@ed14…` | Fremde Action, **per SHA festgenagelt** – wie am Dienstag |
| `vuln-type: library` | Nur Bibliotheken prüfen, nicht das Betriebssystem im Image |
| `severity: CRITICAL,HIGH` | Nur kritische und hohe Lücken melden |
| `ignore-unfixed: true` | Nur Lücken, für die es schon ein Update gibt |
| `exit-code: '1'` | Bei einem Fund wird der Step **rot** – das macht den Scan zum Gate |

## Beobachten

1. Der Lauf wird **rot** – das ist Absicht. Klick auf `build` → Step **Image scannen**.
2. Lies die Tabelle: **Welche** Bibliothek? **Welche** Version ist installiert? **Wie viele** Zeilen (CVEs) gibt es?
3. Schau auf die Steps darunter: `Bei GHCR anmelden` und `Image pushen` wurden **übersprungen**. Das unsichere Image ist nie in der Registry angekommen.

## Beheben

Jede Zeile der Tabelle hat ihre eigene **Fixed Version** – die erste Zeile allein reicht nicht. Am einfachsten nimmst du die **aktuelle** Version der Bibliothek:

1. Schau auf [pypi.org/project/urllib3](https://pypi.org/project/urllib3/) nach der aktuellen Version (oben links, z. B. `2.8.0`).
2. Ändere in `requirements.txt` die Zeile `urllib3==1.26.4` auf diese Version.
3. Committe auf `main`. Der neue Lauf ist komplett grün.

## Geschafft, wenn …

- der erste Lauf am Scan gescheitert ist und Push übersprungen wurde,
- nach deiner Änderung der ganze Lauf grün ist.

## Zum Mitnehmen für die Prüfung

**Warum steht der Scan vor dem Push?**

<details>
<summary>Antwort</summary>

Shift Left: Ein Image mit bekannter Lücke soll gar nicht erst in die Registry kommen, aus der Staging und Produktion es holen.

</details>

**Der Scan findet freitags eine kritische Lücke, für die es noch kein Update gibt. Was tun?**

<details>
<summary>Antwort</summary>

Das ist eine Risikoentscheidung: Risiko bewerten (Ist die Lücke bei uns ausnutzbar?), dann entweder nicht ausrollen oder die Lücke **bewusst und dokumentiert** mit Ablaufdatum akzeptieren – mit einer verantwortlichen Person. Einfach den Scan abschalten ist keine Lösung.

</details>

**Du hast `urllib3` gerade von Hand aktualisiert. Wie passiert das im Alltag, ohne dass jemand daran denken muss?**

<details>
<summary>Antwort</summary>

Ein Werkzeug wie **Dependabot** (GitHub) oder **Renovate** (GitLab, Azure DevOps, Bitbucket …) prüft regelmäßig auf neue Versionen und öffnet dafür einen Pull Request. Die Pipeline testet und scannt das Update automatisch, ein Mensch reviewt, dann wird gemergt – Patch-Management über denselben geprüften Weg wie jede Änderung.

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
```

</details>

<details>
<summary>Tipp: Ich habe angehoben, aber der Scan ist immer noch rot</summary>

Schau in der neuen Tabelle auf **Installed Version**: Steht dort deine neue Version? Dann hast du vermutlich die Fixed Version aus der **ersten** Zeile genommen (z. B. `1.26.5`). Die behebt nur diese eine CVE. Nimm die aktuelle Version von pypi.org.

Steht dort noch die alte Version, ist deine Änderung nicht im Image gelandet: Ist sie auf `main` committet?

</details>

## Doku

- [aquasecurity/trivy-action](https://github.com/aquasecurity/trivy-action)
- [Trivy: Schwachstellen-Scan](https://trivy.dev/latest/docs/scanner/vulnerability/)
