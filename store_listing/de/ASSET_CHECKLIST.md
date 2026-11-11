# Play-Store-Material — Prüfliste

Die Bildvorgaben wurden mit den aktuellen offiziellen Google-Play-Hilfeseiten abgeglichen. Die 3er-Regel für Screenshots gilt für Empfehlungsflächen im Store; die nötige Anzahl je Gerätebereich in Play Console ist separat zu prüfen.

| Material | Datei | Vorgabe | Stand |
|---|---|---|---|
| App-Icon | `app_icon_512.png` | 512×512, PNG 32-bit mit Alpha, höchstens 1 MB | lokal erzeugt und geprüft |
| Feature-Grafik | `feature_graphic_1024x500.png` | 1024×500, PNG 24-bit ohne Alpha | lokal beschnitten und geprüft |
| Spielscreenshots | `screenshots/0.5.35/*.png` | Für Spielempfehlungen mindestens 3 Querformatbilder im 16:9-Format ab 1920×1080, PNG 24-bit ohne Alpha | aus QA-APK auf Android-16-AVD erfasst |

## Screenshots

- `01_fahrt.png`: echtes Fahrbild aus Amsterdam, direkt aus dem installierten QA-Build.
- `02_werkstatt.png`: Fahrzeug und Upgrade-Auswahl.
- `03_funkarchiv.png`: In-Game-Funkarchiv.

Alle Bilder stammen direkt aus dem laufenden Spiel bei einer AVD-Auflösung von 1920×1080; sie wurden nicht nachträglich gestreckt. Die Kampagnenkartenaufnahme wurde nicht übernommen, weil die Navigation während der Erfassung auf der Werkstatt blieb.

## Vor Play-Console-Einreichung

- Finale Screenshots auf einem echten Android-Telefon visuell abnehmen.
- Play-Console-App-Eintrag, Supportkontakt und Datenschutz-URL ergänzen.
- Anzeigen-/UMP-Datenverwendung, Zielgruppe und Inhaltsfreigabe korrekt angeben.
- Mit dem privaten Upload-Keystore ein signiertes AAB erstellen und dessen Zertifikat prüfen.
- Store-Texte gegen den final veröffentlichten Funktionsumfang aktualisieren.

Offizielle Vorgaben: [Grafik- und Screenshot-Material](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en) · [Store-Eintrag und Zeichenlimits](https://support.google.com/googleplay/android-developer/answer/9859152?hl=en)
