# Zusatz 1: Rollback

[Zurück zur Übersicht](../README.md)

## Ziel

Version 1.1.0 ist live – und die Chefin will sofort zurück zu 1.0.0. Weil jedes Image mit seinem Commit-SHA in der Registry liegt, muss **nichts neu gebaut** werden: Das alte Image wird noch einmal durch Staging geprüft und nach Freigabe wieder live geschaltet.

## Aufgabe

Lege einen neuen Workflow `.github/workflows/rollback.yml` an, der

1. **nur von Hand** startet (`workflow_dispatch`) und dabei als Eingabe den **vollen Commit-SHA** der gewünschten Version abfragt,
2. die Jobs `staging`, `freigabe` und `produktion` aus `cd.yml` enthält – aber
   - **ohne** `test` und `build`,
   - mit dem Image `ghcr.io/<repo>:<eingegebener SHA>`,
   - und im Job `produktion` mit dem Code **genau dieses Commits** (damit die Statusseite die richtige Version zeigt).

Starte den Rollback mit dem SHA des Commits, der noch Version 1.0.0 hatte.

## Geschafft, wenn …

- der Rollback-Lauf nach deiner Freigabe grün ist,
- die Statusseite wieder **1.0.0** und das alte Image zeigt,
- im Lauf **kein** `docker build` vorkommt.

## Fragen zum Nachdenken

- Warum ist ein Rollback ohne Neubau sicherer als „alten Code auschecken und neu bauen“?
- Was wäre bei Radhaus mit einer Datenbank zusätzlich zu bedenken?

<details>
<summary>Tipp 1: Eingaben für <code>workflow_dispatch</code></summary>

```yaml
on:
  workflow_dispatch:
    inputs:
      commit:
        description: 'Voller Commit-SHA der Version, die wieder live gehen soll'
        required: true
```

Im Workflow erreichst du den Wert über `${{ inputs.commit }}`. [GitHub: Eingaben für manuelle Workflows](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onworkflow_dispatchinputs)

Den SHA findest du unter **Commits** – Klick auf das Kopier-Symbol neben einem Commit.

</details>

<details>
<summary>Tipp 2: Eingaben sicher verwenden</summary>

Setze Eingaben nie direkt in einen `run:`-Befehl ein – jemand könnte dort Shell-Befehle einschleusen. Übergib sie als Umgebungsvariable:

```yaml
      - name: Image-Namen festlegen
        env:
          COMMIT: ${{ inputs.commit }}
        run: echo "IMAGE=ghcr.io/${GITHUB_REPOSITORY,,}:${COMMIT}" >> "$GITHUB_ENV"
```

[GitHub: Skript-Injection vermeiden](https://docs.github.com/en/actions/concepts/security/script-injections)

</details>

<details>
<summary>Tipp 3: Einen bestimmten Commit auschecken</summary>

`actions/checkout` hat die Einstellung `ref`:

```yaml
      - uses: actions/checkout@v7
        with:
          ref: ${{ inputs.commit }}
```

</details>
