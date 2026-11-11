# Rückmeldungsprüfung – 3. November 2026

## Geprüft und umgesetzt

| Rückmeldung | Ergebnis | Nachweis |
|---|---|---|
| Serienfahrzeug deutlich langsamer; Tuning steigert Tempo; ohne Boost höchstens 135 km/h, mit Boost höchstens 160 km/h | Bestanden. Serienlimit 72 km/h; realer Boost und Motortuning geprüft. Der Serienversuch verbraucht mehr Kraftstoff und nimmt mehr Schaden. | `DRIVING_VELOCITY_OK`, `STOCK_START_MODE_OK` |
| Tank- oder Totalschaden soll das Auto ausrollen lassen; Überschlag soll erkennbar enden und ein Auto in der Luft soll sich zurückdrehen lassen | Bestanden: kontrolliertes Ausrollen bis zum Stillstand, kurze Dachkontaktfrist, Luft-Aufrichtung und Gegenlenken. | `FAILURE_COAST_OK`, `AIR_RIGHTING_OK` |
| Schwierige Hügel, Rampen und eine tatsächlich befahrbare Erasmusbrücke; Brücke darf nicht in der Mitte verschwinden | Bestanden: vier Fahrbahnrampen; die Brücke verwendet dasselbe durchgehende Höhenprofil für Straße und Kollision. Das Bild zeigt den Kombi auf dem angehobenen Deck bei 1200,5 m, 132 km/h, 0 Hindernistreffern und sichtbarem Brückenobjekt. | `ROTTERDAM_SKILL_ROUTE_OK`; `build/pc_preview_rotterdam_erasmusbrug_drive_0.5.45_audit.png` |
| Panzerung soll Treffer reduzieren; Reifen sollen separat getunt werden und sich nicht durch Panzerung verschieben | Bestanden: Panzerungsstufen reduzieren den Schaden; Achsen bleiben gleich; Serie und drei Reifen-Upgrades haben getrennte Grafiken. | `VEHICLE_TUNING_CACHE_OK`, `KOMBI_ARMOR_VISUAL_PROGRESSION_OK`; `build/tire_visual_review_0.7.2.png` |
| Kombi länger zeichnen und Serienreifen kleiner halten; Panzerung darf ungetunte Räder nicht verändern | Bestanden: längere Karosserie, eigenes kleineres Serienrad und drei erkennbare Reifen-Upgrades; Radposition/-größe werden getrennt von Panzerung konfiguriert. | `KOMBI_TIRE_GALLERY_OK`, `TIRE_ARMOR_INDEPENDENCE_OK`; `build/tire_visual_review_0.7.2.png` |
| Panzerung optisch staffeln: Stufe 1 Frontkeil, Stufe 2 Fenstergitter und hoher Schneeschieber, Stufe 3 Schneeschieber plus Seitenplatten | Im direkten Galerievergleich vorhanden. Das Serienauto hat keine Fenstergitter; die Gitter kommen ab Stufe 2. | `build/armor_visual_review_0.5.43.png` |
| Nitro erst nach Kauf; Stufen 1/2 mit einer blauen Flasche, Stufe 3 mit zwei; Boostflamme am Auspuff | Kauf-/Sperrlogik und Grafikgalerie bestanden. Die Flamme ist an aktiven Boost gebunden und beginnt an der Heck-Auspufföffnung. | `UPGRADE_PREVIEW_OK`; `build/nitro_visual_review_0.5.44.png`; PC-Fahrbild mit aktivem Boost |
| Tacho bis 160 km/h anzeigen; Werkstattseite nach Referenz ordnen | Bestanden: manuelle Tachoscheibe endet bei 160; die Werkstatt zeigt Motor, Reifen, Tank, Panzerung und Nitro, „Mehr Teile“ ist entfernt. | Android-Fahrbild 0.5.48; `UPGRADE_PREVIEW_OK` |
| Amsterdam und Rotterdam sollen ohne Ortschilder an ihren Hintergründen erkennbar sein | Bestanden: Grachtenhäuser/-brücke in Amsterdam, Hafenkräne und Erasmusbrug in Rotterdam. | `build/pc_preview_amsterdam_tier3_in_motion_0.5.45.png`; `build/pc_preview_rotterdam_port_background_0.5.45.png` |
| Zombies sollen laufen, mit beiden Händen am Dach greifen, bremsen, Schaden verursachen und bei langsamer Fahrt länger hängen | Bestanden: fünf Profile mit unterschiedlichem Tempo/Schaden/Griffverhalten; Lauf- und Hängeposen bewegen Gliedmaßen. Amsterdam hat eine normale Figur, Rotterdam eine Gruppe aus drei normalen Figuren. Spätere Routen behalten die bereits vorhandenen prozeduralen Gegnergruppen und Horde-Ziele; ihre individuellen Motive sind noch nicht gestaltet. | `ZOMBIE_VARIANTS_OK`, `ZOMBIE_LATCH_OK`, `ZOMBIE_COLLISION_ONCE_OK`; `build/pc_preview_amsterdam_zombie_contact_0.5.45.png` |
| Aufnahme unter Windows darf nicht durch einen automatischen Pausenbildschirm blockiert werden | Bestehen der Fokusprüfung: Aufnahmefokus lässt das Pausefenster geschlossen. | `PC_SCREENSHOT_FOCUS_OK` |
| Werkstattreiter „Mehr Teile“ entfernen und Nitro unter Fahrzeugtuning führen | Die Werkstatt hat die fünf Karten Motor, Reifen, Tank, Panzerung und Nitro; das Upgrade bleibt kaufbar. | `UPGRADE_PREVIEW_OK` |
| Kollisionen, Boost und Reifen sollen sicht- und hörbar reagieren | Bestanden: Auspuffflamme, Reifenabrieb, skalierte Trefferreaktion, Boost-/Musikmischung, Pause und Lautstärke werden geprüft. | `VEHICLE_FEEDBACK_OK`, `AUDIO_SYSTEM_OK` |
| Große Funk- und Statuskästen sollen während der Fahrt verschwinden | Behoben: Statusmeldung und Funktext teilen sich einen schmalen 380 × 28 px Hinweisstreifen links der Pause-Schaltfläche; aktive Ereignisse erscheinen zuerst, danach Funktext. | `RUN_HUD_NOTIFICATION_OK`; Android-Fahrbild 0.5.46 |
| Android-Fahrt soll spielbar flüssig laufen | Offen. 0.5.48 Release auf dem API-36-AVD: Median 2 FPS, 189,46 ms Prozesszeit, 90,19 ms Physikzeit, 165 Draw Calls. Der vollständige Touch-/Speicher-/Kaltstartlauf bestand, aber die Fahrt ist nicht flüssig. 0.5.49 rendert die 2D-Szene im Viewport-Modus mit niedrigerer interner Auflösung; Android-Abnahme fehlt, weil beim Emulatorstart nur 0,79 GB auf C: frei waren. | `build/android/touch_milestone_road-collision-chunks-release-r2-2026-11-03_performance.txt`; `build/android/touch_milestone_road-collision-chunks-release-r2-2026-11-03_run.png`; 0.5.49-AVD-Startmeldung |

### Android-Nachprüfung am 3. November 2026

- Der API-36-AVD `Medium_Phone_API_36.1` ist weiterhin eingerichtet, aber aktuell nicht gestartet.
- Auf C: waren 1,57 GB frei. Es lief kein Emulator- oder ADB-Prozess.
- ADB 37.0.1 scheiterte beim Start des lokalen Dienstes auf Port 5037 und zwei freien Alternativports. Auch der projektinterne ADB-Aufruf lieferte denselben Fehler.
- Ein direkter `adb nodaemon server`-Start gab zusätzlich `failed to create fdevent interrupt socketpair: Invalid argument` zurück. ADB bleibt damit die konkrete Blockade; C: hatte bei der erneuten Prüfung 1,54 GB frei.
- Deshalb wurde in dieser Nachprüfung kein APK installiert und kein Emulatorlauf wiederholt. Als Nächstes muss ADB wieder zuverlässig starten; danach ist ein neuer Lauf nur sinnvoll, wenn genügend freier Speicher verfügbar ist.

## Gebündelte Prüfläufe

- Serien-/Fahr-/Brücken-Audit: `build/godot_vehicle_milestone_2026-11-03-feedback-audit_20261103_013713_980/` — alle 13 Abschnitte bestanden.
- Nitro-Galerie und Upgrade: `build/godot_vehicle_milestone_2026-11-03-feedback-audit_20261103_013823_758/` — alle Abschnitte bestanden.
- Zombieprofile, Lauf-/Griffverhalten, Frontkontakt und Fahrzeugkonfiguration: `build/godot_vehicle_milestone_2026-11-03-feedback-audit_20261103_013906_867/` — alle Abschnitte bestanden.
- Reifengalerie: `build/godot_vehicle_milestone_2026-11-03-feedback-audit_20261103_013950_106/` — bestanden.
- Fahrgefühl, Kollisionen und Sound: `build/godot_vehicle_milestone_2026-11-03-feedback-audit_20261103_014825_695/` — alle 11 Abschnitte bestanden. Der isolierte 35,9-s-PC-Fahrtest erreichte im Serienmodus 598,1 m bei 72 km/h Höchsttempo; 1 Zombiegruppe, 1 Kontakt, 1 Hindernis ohne Treffer.
- HUD und Android: `build/godot_vehicle_milestone_0.5.46-hud_20261103_020914_458/` — Hinweisstreifen und freier Pausenknopf bestanden. Der API-36-Emulator bestätigte Appstart, 11 Touchziele, Gas halten/freigeben, Pause/Zurück, Speichern und Kaltstart-Wiederherstellung. Screenshot: `build/android/touch_milestone_hud-notification-2026-11-03_run.png`.
- Android-Kollisionsbudget: `build/godot_vehicle_milestone_0.5.47-mobile-collision_20261103_024409_305/` — Amsterdam 1.361, Rotterdam 1.461 Straßenpunkte statt 2.215; 220 m Landebahn und durchgehende Rotterdam-Brückenkollision bestanden. Der APK-AVD-Touchlauf bestand; aktive Fahrt blieb bei Median 4 FPS. Godot meldete nach `[ DONE ] export` Exitcode `-1073741819`, obwohl APK-Installationslauf, Signatur und Ausrichtung bestanden.
- Android-Release 0.5.48: vollständiger Lauf bestand Appstart, elf Touchaktionen, gehaltenes Gas, Pause/Zurück, Speichern und Kaltstart-Wiederherstellung (25,42 m; Musiklautstärke 51 %). 15 Fahrproben ergaben Median 2 FPS, 189,46 ms Prozesszeit und 90,19 ms Physikzeit. Fahrbild: `build/android/touch_milestone_road-collision-chunks-release-r2-2026-11-03_run.png`.
- 0.5.49: Debug-APK exportiert und statisch geprüft; Android-Emulator startete wegen zu wenig freiem Platz auf C: nicht. Der gebündelte Windows-Fahrtest bestand mit 60 FPS, 598,1 m in 35,87 s; Artefakte unter `build/godot_vehicle_milestone_0.5.49-viewport-startup-regression_20261103_042328_486/`.

### Leistungsanalyse nach dem ADB-Fehler

- Der gespeicherte Android-Lauf vom 3. November zeigt bei stehendem Auto bereits 33–245 ms Physikzeit und 107–365 ms Prozesszeit pro gemeldetem Messfenster; damit ist der Befund nicht allein durch Fahrtempo oder Kamerastreifen erklärbar. Es sind alte Messwerte aus 0.5.48 und keine Messung des aktuellen Quellstands.
- Im aktuellen Code ließ die Zombie-Kollision zuvor für praktisch jede noch nicht erreichte Gruppe pro Physikschritt die vollständige gedrehte Karosserie/Zombie-Überlappung berechnen. Die meisten Gruppen befinden sich weit außerhalb möglicher Reichweite.
- `scripts/game.gd` und `scripts/terrain.gd` verwenden jetzt großzügige horizontale Abstandsvorprüfungen: Zombiegruppen und Fässer/Wracks bekommen die genaue Formüberlappungsprüfung erst in räumlicher Nähe. Feste Profil-, Strecken- und Bodendaten werden wiederverwendet; Verfolgung und Darstellung müssen sie nicht mehr pro Schritt neu aus Profilkopien oder Höhenberechnungen lesen.
- Diese Änderung wurde noch nicht auf Android gemessen: Der aktuelle ADB-Dienst startet weiterhin nicht, und ein echter Android-Telefontest liegt nicht vor. Daher ist eine Leistungsverbesserung bislang eine begründete Erwartung, kein bestätigtes Ergebnis.
- Der gebündelte Godot-4.7.2-Prüflauf `0.5.49-zombie-broadphase-final` bestand Import, Aufrichtverhalten, Fahrzeug-/Audioreaktionen, räumlichen Zombiefrontkontakt, Festhalten, Serienstart, PC-HUD, Tempo-/Boostband und Startpaket. Die simulierte PC-Fahrt dauerte 35,87 s, legte 623,5 m mit 60 FPS zurück und registrierte 1 Zombiegruppe, 1 Zombiekontakt sowie 1 Hindernis ohne Treffer; der Build wurde im isolierten Prüfspeicherstand ausgeführt. Artefakte: `build/godot_vehicle_milestone_0.5.49-zombie-broadphase-final_20261103_114722_089/`.
- Der Serienstart-Test prüft den Treffer jetzt bei gleichem Aufpralltempo gegen das getunte Fahrzeug. Ergebnis: Serie nimmt beim Hindernistreffer 1,65-mal so viel Schaden; vorher verglich der Test einen stehenden Treffer mit einer absoluten 33-%-Grenze, obwohl die Spiellogik den Schaden nach Tempo skaliert.

## Bewusst zurückgestellt

- Die detaillierte Erkennbarkeit der übrigen 28 Städte: Du wolltest die anderen Strecken später gestalten. Amsterdam und Rotterdam sind bereits über ihre Kulissen erkennbar, ohne Ortsschilder.
- Individuelle Gestaltung der späteren Zombiebegegnungen: Der Kampagnen-Prototyp enthält dort noch prozedurale Gruppen, die auch für bereits hinterlegte Horde-Ziele gebraucht werden.
- Store-Aufgaben und finale AAB-Erstellung: bis zum Spiel-Feedback zurückgestellt. Die vorhandene APK ist ein persönlicher Debug-Build, kein Store-Build.
- Android-Leistungsabnahme 0.5.49 auf Emulator und echtem Telefon: offen. Beim letzten AVD-Start waren auf C: nur 0,79 GB frei.
- Der Werkstatthintergrund bleibt vorerst einfach, wie von dir gewünscht.

## Nächster Schritt

Die PC-Vorschau startet mit `Start_Zombie_Escape_Europe_PC_Preview.bat`; 0.5.49 besteht dort den automatisierten Fahrtest. Für eine echte Android-Abnahme muss zuerst Speicherplatz auf C: frei werden; danach den 0.5.49-AVD-Touch- und Bildratenlauf erneut ausführen. Der Brückenfahr-Capture ist `build/pc_preview_rotterdam_erasmusbrug_drive_0.5.45_audit.png`.
