# Radhaus geht live

Übung zu Abend 2 von „Einführung CI/CD Pipelines“.

Radhaus hat seit Dienstag CI: Jeder Pull Request wird getestet. Aber das Deployment läuft immer noch freitags per SSH, und niemand weiß genau, welche Version gerade läuft. In dieser Übung baust du den **rechten Teil der Pipeline**:

```text
Test → Image bauen → Scan → Registry → Staging + Smoke Test → Freigabe → Produktion
```

Alles läuft innerhalb von GitHub – du brauchst **kein Cloud-Konto**. „Produktion“ ist in dieser Übung eine Statusseite auf GitHub Pages, die zeigt, welche Version und welches Image gerade live sind.

## Dateien

```text
README.md                    diese Anleitung
aufgaben/                    die Aufgaben, eine Datei pro Schritt
shop/versand.py              Versandkosten (der 50-€-Fehler ist behoben)
shop/server.py               kleiner Webserver mit /health und /versand
tests/                       fertige Tests
requirements.txt             Laufzeit-Abhängigkeiten
requirements-dev.txt         zusätzlich Test-Werkzeuge
Dockerfile                   Multi-Stage-Build, läuft nicht als root
scripts/smoke-test.sh        startet ein Image und prüft, ob der Shop antwortet
scripts/statusseite.sh       erzeugt die Statusseite für GitHub Pages
.github/workflows/ci.yml     CI vom Dienstag: Tests und Stilprüfung
```

## Los geht’s: eigenes Repository anlegen

Arbeite in einem **eigenen, öffentlichen** Repository – nur dann sind Environments mit Freigabe, GitHub Pages und Actions-Minuten kostenlos. Es ist ein **neues** Repository, unabhängig von dem vom Dienstag.

**Weg 1 – Vorlage (empfohlen):** Oben auf dieser Seite (`MartinCloudHelden/radhaus-cd`) **Use this template → Create a new repository**, Sichtbarkeit **Public**. [GitHub: Repository aus Vorlage erstellen](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template)

**Weg 2 – Klonen und eigenes `origin`:** Leeres, öffentliches Repository auf GitHub anlegen (ohne README, ohne `.gitignore`), dann:

```bash
git clone https://github.com/MartinCloudHelden/radhaus-cd.git
cd radhaus-cd
git remote set-url origin https://github.com/DEIN-NAME/radhaus-cd.git
git push -u origin main
```

Alle Aufgaben lassen sich im Browser lösen (Taste `.` im Repository öffnet den Editor).

## Ablauf

| Nr. | Aufgabe | Zeit | Theorie dazu | Typische Prüfungsfrage |
|---|---|---|---|---|
| 1 | [Ankommen](aufgaben/01-ankommen.md) | 5 Min | Rückblick Dienstag | – |
| 2 | [Image bauen und ablegen](aufgaben/02-image-bauen.md) | 15 Min | Build once, Versionen, Tag/Digest | Wie stellen Sie sicher, dass in Produktion läuft, was getestet wurde? |
| 3 | [Image scannen](aufgaben/03-image-scannen.md) | 15 Min | Trivy, Dependabot, Shift Left | Wie schützen Sie die Pipeline vor unsicheren Abhängigkeiten? |
| 4 | [Staging mit Smoke Test](aufgaben/04-staging.md) | 10 Min | Testszenarien, Environments | Welche Tests für welches Risiko? |
| 5 | [Freigabe und Produktion](aufgaben/05-produktion.md) | 20 Min | Delivery, Audit-Trail | Wie weisen Sie nach, wer was freigegeben hat? |

Ab Aufgabe 2 bekommst du die **YAML-Bausteine fertig zum Einfügen**. Jede Aufgabe erklärt in einer Tabelle, was die Zeilen bedeuten, sagt dir, worauf du im Lauf **achten** sollst, und endet mit Fragen **zum Mitnehmen für die Prüfung** – mit aufklappbarer Antwort.

**Zusatzaufgaben** für alle, die früher fertig sind:

| Nr. | Aufgabe | Thema |
|---|---|---|
| Z1 | [Rollback](aufgaben/z1-rollback.md) | Wiederherstellung ohne Neubau |
| Z2 | [SBOM erzeugen](aufgaben/z2-sbom.md) | Software-Stückliste |

## Was am Ende entsteht

Eine zweite Workflow-Datei `.github/workflows/cd.yml`, die bei jedem Push auf `main` läuft:

| Job | Macht | Neu in Aufgabe |
|---|---|---|
| `test` | Tests – nichts Ungetestetes wird gebaut | 2 |
| `build` | Image bauen, scannen, in die Registry legen | 2, 3 |
| `staging` | Image aus der Registry starten, Smoke Test | 4 |
| `freigabe` | wartet, bis ein Mensch zustimmt | 5 |
| `produktion` | Statusseite auf GitHub Pages veröffentlichen | 5 |

## Wenn etwas nicht funktioniert

| Beobachtung | Prüfe zuerst |
|---|---|
| Fehler wie `mapping values are not allowed` | Einrückung: YAML braucht Leerzeichen, keine Tabs. Jede Aufgabe hat unten die **komplette Datei zum Vergleich**. |
| `invalid reference format: repository name must be lowercase` | Ist der Step **Image-Namen festlegen** unverändert übernommen? Er wandelt in Kleinbuchstaben um. |
| `denied: permission_denied` oder `unauthorized` beim Push oder Pull | Hat der Job `packages: write` (Push) bzw. `packages: read` (Pull)? Läuft `docker/login-action` **vor** dem Push/Pull? |
| Trivy-Step ist rot | Das ist in Aufgabe 3 Absicht. Lies die Tabelle im Log. Jede Zeile hat ihre eigene Fixed Version – nimm die aktuelle Version der Bibliothek. |
| Smoke Test: „antwortet nicht auf /health“ | Unter dem Fehler steht das Container-Log. Steht dort ein Python-Fehler? |
| Job `freigabe` wartet nicht | Ist im Environment `production` ein **Required reviewer** eingetragen? Heißt das Environment im Workflow genau gleich? |
| Pages-Deployment scheitert | Ist unter **Settings → Pages** als Quelle **GitHub Actions** gewählt? Hat der Job `pages: write` und `id-token: write`? |
