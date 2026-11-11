> Aktualisierung 8. November 2026: Die optionale Zwei-Lastkahn-Nebenroute wurde auf Nutzerwunsch vollständig entfernt. Ihre nachfolgende Beschreibung ist historisch. Im Bereich 1.040–1.118 m verlaufen wieder die normale Straße und Mauer. Kranlasten, Abschütteln, Kombos und der ursprüngliche Lastkahn bei 820 m bleiben erhalten.

# Amsterdam: vier Action-Erweiterungen – 7. November 2026

## Bedienung und Verhalten

1. Zwei schwingende Kranlasten im Hafen, ungefähr bei 1.405 und 1.653 angezeigten Metern. Warnung ab 75 m vor dem jeweiligen Kran, zusätzlich blinkendes Licht und markierter Gefahrenbereich am Boden. Eine dauerhafte Warnzeile bleibt auch dann sichtbar, wenn eine Landung oder ein Zombie eine andere Meldung auslöst. Bremsen und den richtigen Zeitpunkt wählen oder mit Schwung durchfahren. Schaden und Tempoverlust entstehen erst bei räumlicher Überlappung mit der sichtbaren Last; pro Last höchstens ein Treffer je Fahrt. Treffer erzeugen Partikel und Aufprallsound und unterbrechen die Kombo. Die alte fest eingezeichnete Hakenpartie wird an diesen beiden Kränen ausgeblendet.

2. Abschütteln: Bei mehr als etwa 43 km/h mindestens 0,22 s kräftig bremsen und tatsächlich mindestens 7,2 km/h verlieren. Innerhalb von 1,8 s wieder Gas geben. Nitro verkürzt das Losreißen; normales Gas funktioniert ebenfalls. Das Manöver benötigt Bodenkontakt. Stärkere Zombiegriffe halten länger. Die vorhandene sichtbare Fallanimation wird weiterverwendet. Gleichmäßiges Gas und bloßes gleichzeitiges Drücken ohne Tempoverlust zählen nicht als Bremsmanöver. Keine zusätzliche Pflichtaufrüstung und keine neue Taste.

3. Optionale Lastkahnroute ab angezeigten 1.040 m, Ausfahrt bei etwa 1.118 m. Vor dem Abzweig Bremse halten; die Wahl erfolgt zehn Meter vor der Einfahrt. Ohne Bremsen bleibt die bisherige Straße offen. Zwei befahrbare Kähne mit eigenen Kollisionsflächen, Holzauffahrt, Absprungkante, acht Meter freier Wasserlücke und Ausfahrt. Zweites Deck liegt 30 Weltpixel tiefer. Absprung und Schwerkraft sind echte Fahrzeugphysik; es gibt keine zusätzliche unsichtbare Aufwärtskraft über der Lücke. Die vorhandenen Grafiken werden mit erhaltenen Proportionen genutzt, ergänzt durch Poller, Seile und die sichtbare obere Ausweichbrücke. 60 Zusatzmünzen erst nach Kontakt mit dem zweiten Kahn und sicherer Ausfahrt. Zu wenig Schwung kann im Wasser enden; dann gibt es keinen Routenbonus. Der bisherige Kahn bei 820 m bleibt erhalten. Eine zuvor in der neuen Sprunglücke liegende Sperre wurde hinter die Ausfahrt verschoben.

4. Kombo: Echte Waffen- und Fahrzeugtreffer verlängern die Kette um 4,5 s. Ab dem zweiten Ereignis gibt es zusätzlich 1 bis höchstens 6 Münzen je Ereignis. Kettenanzeige ist auf acht begrenzt. Saubere Sprünge erfordern mindestens 0,35 s Flug, vier Meter Vorwärtsweg, ausreichende Höhe, passende Landelage und begrenzten Aufprall. Sie geben fünf Zusatzmünzen und verlängern die Kette. Bodenwellen zählen nicht automatisch als Sprung; dieselbe Stelle lässt sich nicht mehrfach für Sprungmünzen abfahren. Hindernistreffer, Kranlasttreffer und harte Landungen unterbrechen die Kette; nach 4,5 s ohne neues Ereignis endet sie ebenfalls. Bereits verdiente Münzen bleiben erhalten. Komboanzeige und dauerhafte Gefahrenhinweise haben eigene Zeilen.

## Belohnungen und Spielstand

Alle neuen Münzen gehen in den vorhandenen Aktionsbonus und die bestehende Fahrtabrechnung. Die Auszahlung wird zusätzlich gegen doppelten Aufruf geschützt. Neustart setzt Streckenwahl, Kranstatus, Kombos und Manöver zurück. Persönliche Spielstände wurden nicht für Tests zurückgesetzt. Werkstattwerte, Upgradepreise, Schleusenabstand und die 1.800-m-Streckenlänge bleiben erhalten.

## Ausgeführte Prüfungen

- Komplette 1.800-m-Fahrt mit tatsächlichen Tastatureingaben, einschließlich Schleusenbrücke und beiden Kranbereichen, bis zum Ziel bestanden: 79,68 s. Median 52 FPS, Minimum 35 FPS bei Aufzeichnung; stabile 60 FPS bleiben offen. Diese Vollfahrt wählte die sichere obere Straße am neuen Abzweig.
- Eigenständige Fahrt über die neue Nebenroute mit echten Gas-, Brems- und Nitroeingaben bestanden: beide Kähne, Lücke, Ausfahrt und einmaliger Bonus. Keine Teleportation innerhalb dieses Abschnitts. Der isolierte Test beginnt vor dem Abschnitt; bereits zuvor liegende Streckentrigger werden entsprechend markiert.
- Gegenprobe mit wenig Schwung vor der Kante: Fahrzeug fällt real ins Wasser, Game-over, kein Routenbonus.
- Abschütteln mit echten Tastatureingaben: etwa 90,7 auf 74,8 km/h gebremst, danach Gas/Nitro; Zombie sichtbar freigegeben und Griff entfernt.
- Logikprüfung: gleichmäßiges Gas zählt nicht als Manöver, tatsächlicher Bremsimpuls schon; Kran trifft nur bei sichtbarer Überlappung und einmal; Kombo bezahlt begrenzt und endet korrekt; sichere Straße zahlt keinen Lastkahnbonus; Neustart stellt die Kollisionswahl zurück.
- Bestehende Prüfungen bestanden: 96 Upgrade-Einträge über drei Fahrzeuge; fünf Zombiearten mit Vorwärtsklettern, Ablösen und Rücksetzen; Schleusenbrücke mit langsamer Wasserlandung und erfolgreichem 135-km/h-Fall.
- Sichtbare Prüfbilder der Nebenroute und Kranlast erstellt und kontrolliert. Android und ein reales Telefon wurden nicht getestet.

## Dateien und Prüfnachweise

- `scripts/amsterdam_action.gd`: neue Streckenmechanik, Kollisionsflächen und Darstellung.
- `scripts/amsterdam_preview_course.gd`: Integration und optische Anschlüsse.
- `scripts/wagon.gd`: Abschüttelmanöver, bestehende Zombie-Fallanimation.
- `scripts/driving_test.gd`: Eingaben, Kombos, Hinweise und bestehende Abrechnung.
- `tests/amsterdam_action_test.gd`, `tests/amsterdam_barge_failure_test.gd`.
- `tools/amsterdam_action_drive_probe.gd`, `tools/zombie_shake_drive_probe.gd`.
- Bilder: `build/action-route-0.png` bis `build/action-route-4.png`, `build/action-crane-warning.png`.
- Logs: `.local_probe/action-full-drive.log`, `action-drive.log`, `action-test.log`, `action-slow.log`, `shake-input.log`, `action-upgrades.log`, `action-zombies.log`, `action-lock.log`.
- Sicherheitskopie der drei zuvor vorhandenen geänderten Skripte: `.local_probe/action-backup/`.

Start über `Start_Zombie_Escape_Europe_PC_Preview.bat`; eine laufende alte Vorschau vorher schließen.

