# Amsterdam – geprüfter PC-Meilenstein, 8. November 2026

## Start und gesicherter Ausgangspunkt
Im Projektordner `Start_Zombie_Escape_Europe_PC_Preview.bat` öffnen. Das vorhandene Godot 4.7.2 startet die Hauptszene mit `--amsterdam-werkstatt`; Werkstatt, Käufe und anschließende Amsterdam-Fahrt gehören dadurch zum selben Spielerweg.

Vor den ersten Meilenstein-Änderungen wurde `Sicherungen/Zombie_Escape_Europe_PC_Meilenstein_2026-11-08_17-57-07.zip` erstellt und vollständig gegen die Originaldateien geprüft: 5.541 Dateien, 2.944.059.809 Bytes, SHA-256 je Eintrag, `Verified: true` im zugehörigen JSON. Persönliche Spielstände außerhalb des Projekts wurden nicht verändert. Sämtliche Fahr- und Kaufprüfungen nutzten getrennte APPDATA-Verzeichnisse.

## Änderungen und Abnahmebelege

| Anforderung | Aktueller Stand und tatsächlich ausgeführte Prüfung |
| --- | --- |
| Flüssige Fahrt und Landungen | Aufwendige unveränderliche Brückengrafik zwischengespeichert; Straßenproben pro Bild wiederverwendet. Falschen Hügel vor der Holzrampe entfernt; Brückenkante an sichtbarer Radposition und Federungsfreiheit geprüft. Separate grafische PC-Messung ohne parallele Fahrtests: erste Brücke p95 18,305 ms, Maximum 24,389 ms; Schleuse p95 16,955 ms, Maximum 19,080 ms. `.local_probe/milestone-pacing-alone.log`. Kein Versprechen durchgehend fester 60 FPS. |
| Echte Schleusenflugbahn | Motor II + Nitro I bleiben Zielausbau. Reale Geschwindigkeit und Flugbahn entscheiden; keine erzwungene Abwärtsbewegung als Geschwindigkeitsprüfung. Die regulär erspielte Vollfahrt hat den Sprung ohne Waffe geschafft. Ergänzende physikalische Zielstufenprüfung ist im Grafikbericht dokumentiert. |
| Herausforderungen und Fortschritt | Brücken, Holzrampe, Lastkahn im Hauptweg, Schleusensprung, Gegnergruppen, Holzsperren und explosive Fässer bleiben Teil der 1.800-m-Strecke. Verworfene Lastkahn-Nebenroute und Torbauten bleiben entfernt. Echte Erstversuche über Menü, Einführung, Fahrt, Ergebnis und Werkstatt: 680 m mit Serienwagen; 951 m mit Motor/Tank I; anschließend weitere tatsächlich bezahlte Käufe. `.local_probe/milestone-player-loop-1.log`. |
| Ganze Strecke mit erreichbaren Käufen | Nach ausschließlich verdienten Einnahmen und Mauskäufen: Motor II, Nitro I, Reifen II, Tank III, Panzerung III, sonst Stufe 0 einschließlich Waffe. 1.800 m in 85,58 Simulationssekunden; 410 Münzen Einkommen, 646 Guthaben, etwa 32 % Zustand und 7 % Tank am Ziel. `.local_probe/earned-drive-final.log`. Der vorherige Versuch mit Tank/Panzerung II endete regulär bei 1.625 m und finanzierte die letzten Käufe. Ältere Vollfahrt mit vorzeitig gewährter Waffe ist hierfür ausdrücklich kein Abnahmebeleg. |
| Zieleinfahrt | Neuerer Nutzerentscheid hat Vorrang: kein Hafentor. Detaillierte vorhandene Kaiumgebung, Bodenmarkierung bei 1.800 m, sichere kurze Ausrollphase und Auswertung bleiben. Tatsächliche Eingaben, Pause während Ausrollen, Einkommen genau einmal, gespeicherter Abschluss, Neustart und Breitformat geprüft. `.local_probe/final-arrival.log`: HARBOR_ARRIVAL_OK. |
| Zombies und Zerstörung | Identität bleibt beim Hängen, Hochziehen, Dachkriechen und Herunterfallen erhalten; fünf Typen mit zugeordneten Griffpunkten. Fallbewegung übernimmt Fahrzeugbewegung. Waffen/Fässer reagieren vor dem Wagen. Holzsperren und Splitter verwenden zusammenpassendes Material. Neueste Dachlage: zusätzliche Gruppe auf sechs reduziert, drei je Seite, 160 Weltpixel zwischen Wartepositionen, nur einer je Seite greift direkt an. Normale Begegnungszombies werden dabei nicht zusätzlich darüber gezeichnet. Feuer/Game over/Neustart und Ansicht geprüft: `.local_probe/wreck-spacing.log`. |
| Einheitliche Darstellung | Gemalte Werkstatt-Teilegrafiken, Kartenplakat, subtile Fahrzeugbeleuchtung und kontaktrichtige Reifenschatten. Keine neue Karosserieform oder eigenmächtige größere Rammbockgrafik. Atlas-Ausschnitte und vorhandene Holz-/Steinmaterialien statt wahllos gestreckter Einzelbilder. Details und exakte Grafikprompts: `design/grafikpolitur-werkstatt-2026-11-08.md`. |
| Verständliche Kaufvorschau | Sechs erkennbare Kategorien; MONTIERT und NÄCHSTER AUSBAU getrennt, reale Werte und Preise, Besitz/gesperrt/Maximum erkennbar. Reifenvorschau nutzt das konkrete Teil, andere Kategorien sind als Teilekategorie gekennzeichnet. 96 Vorschauen gegen echte Fahrwerte geprüft: `.local_probe/final-upgrade_preview_test.log`. |
| Unabhängige Käufe und Neustart | Echte Mauskäufe ändern genau eine Kategorie und ziehen den Preis einmal ab. Normal/breit, Plakat mit Maus/Touch, blockiertes Durchklicken und Maximum getestet: `.local_probe/final-ui.log`. Frischer Prozess lädt die regulär erspielten Käufe und 646 Münzen: `.local_probe/earned-reload-final.log`. |
| Schutz vorhandener Spielstände | Alten automatisch startenden Tuningversuch entfernt, der den Kombi auf Serie zurückschreiben konnte. Legacy-Start mit gekauften Teilen und anderen Fahrzeugdaten geprüft: `.local_probe/startup-protection-final.log`. Abschlussmarkierung ist seit Speicherschema 10 Pflicht, unabhängig vom aktuellen Kampagnenschema 12; unvollständige ältere Dateien werden nicht mehr als gültiges Profil migriert. Primärdatei, temporäre Datei, Sicherung, Schema-9-Migration und Erhalt beschädigter Originaldateien geprüft: `.local_probe/final-progress_save_recovery_test.log`. |

## Ansichten und Vergleich
Die früheren Aufnahmen sind historische Vergleichsansichten, keine Behauptung identischer Ausrüstung oder identischer Kameraposition.

Werkstatt vor dieser Überarbeitung:

![Frühere Werkstatt](../build/werkstatt-review-normal.png)

Aktuelle Werkstatt mit gemalten Teilen und echten Werten:

![Aktuelle Werkstatt](../build/grafikpolitur-werkstatt.png)

Aktuelle Werkstatt im breiten Format 1920 × 864:

![Werkstatt breit](../build/grafikpolitur-breit.png)

Aktuelle reduzierte Wrackgruppe:

![Sechs Zombies mit Abstand](../build/wrack-zombiehorde.png)

Ziellinie ohne Tor:

![Aktuelle Zieleinfahrt](../build/hafenausfahrt-ziellinie.png)

Ergebnis der vollständigen, regulär erspielten Fahrt:

![Regulär erspielter Abschluss](../build/spielerweg-ohne-waffe-ergebnis.png)

Auswertung im breiten Format:

![Auswertung breit](../build/hafenausfahrt-auswertung-breit.png)

## Verbleibende Grenzen und nächste sinnvolle Entscheidung
- Der PC-Meilenstein ist startbar und nachweislich durchspielbar. Ob Fahrgefühl, Schwierigkeit und Stil gefallen, bleibt Stefans nächste Spielabnahme; die protokollierte Eingabefahrt ersetzt kein persönliches Urteil zum Spielspaß.
- Animationen bestehen aus gemalten Einzelposen und weichen Übergängen; sie erreichen nicht die Bewegungsfreiheit einer vollständigen Skelettanimation. Die reduzierte Wrackszene wurde sichtbar geprüft, nicht jede mögliche Umkippstelle als eigene Aufnahme.
- Geprüft wurden lokale PC-Vorschau sowie 1280 × 720 und 1920 × 864. Kein reales Telefon, keine Android-Leistungsabnahme und keine belastbare Aussage über andere PCs.
- Panzerungsformen der späteren Stufen bleiben gemäß AGENTS offen für passende Nutzerreferenzen. Hier wurden bestehende Stufen und Werte geprüft, keine zurückgewiesenen großen Rammböcke als neue Freigabe behandelt.
- Keine weiteren Städte/Fahrzeuge ausgearbeitet, kein Architektur-Komplettumbau, keine Veröffentlichung. Die geplante 20-Städte-Reise bleibt Planung.

Als nächstes diesen PC-Stand persönlich fahren und Rückmeldung zu drei konkreten Punkten sammeln: Kontrolle bei der ersten Landung, Lesbarkeit des Schleusensprungs und Motivation der nächsten Käufe. Erst danach einen neuen spielbaren Meilenstein vereinbaren.
