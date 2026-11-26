# Aufgabe 1: Ankommen

⏱ ca. 5 Minuten · [Zurück zur Übersicht](../README.md)

## Ziel

Du verschaffst dir einen Überblick über den Stand vom Dienstag und die neuen Dateien. Ab Aufgabe 2 bekommst du die YAML-Bausteine fertig zum Einfügen – du musst nichts programmieren. Wichtig ist, dass du **beobachtest**, was die Pipeline tut, und es mit den Folien verbindest.

## Aufgabe

1. Öffne den Tab **Actions**. Beim Anlegen deines Repositorys ist `CI` bereits einmal gelaufen. Ist der Lauf grün?
2. Schau dir diese Dateien kurz an – du musst sie nicht verstehen, nur wissen, wofür sie da sind:
   - `Dockerfile`: Wie viele Stufen hat der Build? Als welcher Benutzer läuft der Shop?
   - `scripts/smoke-test.sh`: Welche zwei Dinge prüft der Smoke Test?
   - `requirements.txt`: Welche Bibliothek in welcher Version braucht der Shop?

## Geschafft, wenn …

- der `CI`-Lauf grün ist,
- du die Fragen aus Schritt 2 beantworten kannst.

<details>
<summary>Antworten zu Schritt 2</summary>

- **Dockerfile:** zwei Stufen (`build` und Laufzeit-Image). Der Shop läuft als Benutzer `1000`, nicht als root.
- **Smoke Test:** 1. antwortet `/health` mit „ok“? 2. sind die Versandkosten bei 50,00 € wirklich 0,00 €?
- **requirements.txt:** `urllib3` in Version `1.26.4`. Merk dir das für Aufgabe 3.

</details>

## Doku

- [Docker: Multi-Stage-Builds](https://docs.docker.com/build/building/multi-stage/)
