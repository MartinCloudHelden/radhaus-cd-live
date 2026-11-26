# Zusatz 2: SBOM erzeugen

[Zurück zur Übersicht](../README.md)

## Ziel

Eine **SBOM** (Software Bill of Materials) ist die Stückliste eines Images: Welche Pakete stecken in welcher Version darin? Wird morgen eine neue Lücke bekannt, sieht man sofort, ob man betroffen ist. Der EU Cyber Resilience Act macht SBOMs für viele Produkte zur Pflicht.

## Aufgabe

1. Ergänze im Job `build` nach dem Push einen zweiten Trivy-Step, der für das Image eine SBOM im Format **CycloneDX** in die Datei `sbom.cdx.json` schreibt.
2. Lade die Datei mit `actions/upload-artifact` (Version `v7`) als **Artefakt** namens `sbom` hoch.
3. Lade das Artefakt nach dem Lauf herunter (unten auf der Übersichtsseite des Laufs) und öffne die Datei. Findest du `urllib3` und seine Version?

## Geschafft, wenn …

- am Lauf ein Artefakt `sbom` hängt,
- die Datei darin `urllib3` mit der Version aus `requirements.txt` enthält.

<details>
<summary>Tipp 1: Trivy als SBOM-Generator</summary>

Mit `format: cyclonedx` und `output: sbom.cdx.json` schreibt Trivy statt einer Tabelle eine SBOM-Datei. `exit-code` lässt du hier weg – die SBOM soll die Pipeline nie rot machen. [Trivy: SBOM](https://trivy.dev/latest/docs/supply-chain/sbom/)

</details>

<details>
<summary>Tipp 2: Gerüst</summary>

```yaml
      - name: SBOM erzeugen
        uses: aquasecurity/trivy-action@<sha> # v0.36.0
        with:
          image-ref: ${{ env.IMAGE }}
          format: cyclonedx
          output: sbom.cdx.json
      - uses: actions/upload-artifact@v7
        with:
          name: sbom
          path: sbom.cdx.json
```

[GitHub: Artefakte speichern](https://docs.github.com/en/actions/tutorials/store-and-share-data)

</details>
