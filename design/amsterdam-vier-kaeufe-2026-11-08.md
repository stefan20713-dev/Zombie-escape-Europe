# Amsterdam – vier Käufe statt fast vollständigem Ausbau

Stand: 8. November 2026. Neuester bestätigter Nutzerauftrag: Das erste Stadtlevel soll wesentlich weniger Upgrades benötigen. Dieser Bericht ersetzt die frühere Amsterdam-Zielanforderung mit Tank, Reifen und Panzerung II.

## Aktuelles Abschlussprofil

| Kategorie | Für die geprüfte Abschlussfahrt gekauft | Kosten insgesamt |
| --- | --- | --- |
| Motor | I und II | 55 + 95 = 150 Münzen |
| Tank | I | 40 Münzen |
| Nitro | I | 45 Münzen |
| Reifen | Serie / 0 | 0 |
| Panzerung | 0 | 0 |
| Fahrwerk, Verbrauch, Bremsen, Waffe | 0 | 0 |

Vier einzelne Käufe in drei Kategorien kosten damit **235 Münzen statt der zuvor benötigten 540 Münzen**. Das ist kein garantierter Erfolg allein aufgrund des Besitzes: Anlauf, tatsächliche Geschwindigkeit, Luftlage und Treffer bleiben wirksam. Motor II und Nitro I bleiben das Ziel für den Schleusensprung. Reifen I und Panzerung I sind freiwillige Hilfen.

## Umsetzung
- Ausschließlich in der Amsterdam-Vorschaufahrt den Kraftstofffaktor von 0,68 auf 0,52 gesenkt. Tankgrößen und Preise bleiben unverändert; Tank I hat weiterhin 92 Einheiten und bringt einen echten Vorteil gegenüber dem Serientank.
- Den bereits vorhandenen, stadteigenen Faktor für panzerungsskalierte Treffer-/Straßen-/Klammerschäden neu abgestimmt: 0,70 am Anfang, weich auf 0,22 zwischen 700 und 1.000 m. So bleibt der ungeschützte Serienkombi bei guter Fahrt ausreichend lange funktionsfähig. Panzerung reduziert Schäden zusätzlich; sie wurde nicht kostenlos montiert.
- Keine Änderung der Motor- oder Nitrokräfte, realen Geschwindigkeiten, Brückenabstände oder Flugbahn. Die Treffer behalten ihre tatsächlichen Kontakte und typspezifischen Tempoverluste. Keine künstliche Reichweitensperre, kein Schadenserstatten nach einem Treffer und keine nachträgliche Tankfüllung im Prüfstand.
- Die Einführung erklärt ausdrücklich Motor II, Nitro I und Tank I als Amsterdam-Ziel und Reifen/Panzerung als freiwillige Hilfen.
- Andere Stadt-/Fahrtszenen behalten ihre neutralen Faktoren. Bestehende Käufe und persönliche Spielstände werden weder zurückgesetzt noch herabgestuft. Preise, Einkommen und Freischaltungen wurden nicht geändert.

## Sicherungen vor Änderungen
- Laufzeitdatei `scripts/driving_test.gd`: `Sicherungen/Amsterdam_Weniger_Upgrades_vorher_2026-11-08_20-42-57.zip`.
- Vor der anschließenden Einführungstextänderung `scripts/hud.gd`: `Sicherungen/Amsterdam_Weniger_Upgrades_HUD_vorher_2026-11-08.zip`.
- Beide Archive wurden nach dem Schreiben gelesen und die Einträge per SHA-256 gegen die Originaldateien geprüft. Die JSON-Dateien daneben enthalten `Verified: true`. Vorhandene vollständige Sicherungen bleiben erhalten.

## Sichtbare Fahrten mit den endgültigen Werten
Die folgenden grafischen PC-Testfahrten liefen mit echten Tastaturereignissen, vollständiger Strecke und tatsächlich geladenen Produktionsszenen. Alle verwendeten ein separates APPDATA-Verzeichnis. Keine persönliche Spielsitzung wurde neu gestartet.

| Ausrüstung / Fahrverlauf | Ergebnis | Resttank | Restzustand |
| --- | --- | --- | --- |
| Nur Motor II, Nitro I und Tank I; alle übrigen Kategorien 0 | 1.800 m nach 82,33 s | 15,4 % | 19,2 % |
| Dasselbe Profil, andere Luftkorrekturschwelle und kurze Bremsung vor der Schleuse | 1.800 m nach 93,17 s | 7,6 % | 6,4 % |
| Zusätzlich freiwillig Reifen I und Panzerung I | 1.800 m nach 86,17 s | 12,9 % | 41,3 % |

Damit ist der Abschluss ohne gekaufte Reifen, Panzerung und Waffe zweimal sichtbar geprüft. Der zweite Verlauf zeigt zugleich, dass ungeschützte Fahrten knapper ausfallen können. Es wird keine Fehlertoleranz für beliebige Überschläge, verfehlte Sprünge oder massiven zusätzlichen Schaden behauptet.

Ein separater Gegencheck mit Motor I/Nitro II und Reifen/Tank/Panzerung I erreicht die Schleuse bei 1.310 m, landet aber wegen der tatsächlichen Flugbahn im Wasser. Mehr Nitro ersetzt den erforderlichen Motor nicht. Dieser Gegencheck wurde beschleunigt ohne Grafik ausgeführt und wird nicht als Bildschirm-/Leistungsprüfung ausgegeben.

Nachweise:
- `.local_probe/minimal-visual.log`, `.local_probe/balance-minimal-results.json`, `tools/amsterdam_minimal_visual_probe.gd`.
- `.local_probe/minimal-weak.log`, `tools/amsterdam_minimal_weak_probe.gd`.
- `build/balance-minimal-abschluss.png`, `balance-minimal-abschluss-unruhiger.png`, `balance-minimal-komfort.png`.
- Der frühere Lauf `.local_probe/minimal-fast.log` war eine Vorabmessung mit anderen Faktoren; er ist ausdrücklich nicht der Nachweis des finalen Stands.

## Echter Spielerweg mit vier bezahlten Käufen und frischem Prozess

Zusätzlich vom echten Startmodus `--amsterdam-werkstatt` über Hauptmenü, Einführung, Fahrt, Ergebnis und Werkstatt gefahren. Käufe und Schaltflächen wurden mit tatsächlichen Mausereignissen betätigt. Keine Sondermünzen, Testwaffe oder direkten Änderungen gekaufter Stufen.

1. Frischer Spielstand: normale 100 Startmünzen, alle Upgrades 0.
2. Erste Serienfahrt: **1.119,82 m**, Einkommen **260**, Guthaben **360**. Ende durch tatsächliche Schadensbelastung.
3. Motor I, Motor II, Tank I und Nitro I einzeln für zusammen **235** gekauft. Guthaben danach **125**. Nach jedem Kauf geprüft: genau einmal Preisabzug, nur die gewählte Kategorie steigt um eins; alle anderen bleiben unverändert.
4. Zweiter Versuch: volle **1.800 m** geschafft, Einkommen **419**, Guthaben **544**. Rückkehr über die echte Ergebnis-Schaltfläche in die Werkstatt; alle vier Käufe bleiben erhalten.
5. In einem neuen Prozess das normale Spiel erneut geladen: Guthaben **544**, Motor II, Nitro I, Tank I; Reifen, Panzerung, Fahrwerk, Verbrauch, Bremsen und Waffe weiterhin 0. Kein automatischer Test-/Serienmodus aktiv.

Das belegt einen möglichen Abschluss im zweiten Versuch mit der niedrigeren Kaufhürde. Die zuvor genannte Spanne von vier bis sieben Amsterdam-Versuchen ist keine vorgeschriebene Mindestdauer mehr. Bei anderer Fahrweise oder Kaufreihenfolge sind weitere Versuche möglich. Es werden keine zusätzlichen Fehlversuche erzwungen, um eine Zahl einzuhalten.

Nachweise: `.local_probe/minimal-player-final.log`, `.local_probe/minimal-player-expected.json`, `.local_probe/minimal-reload-final.log`, `tools/amsterdam_minimal_player_probe.gd`, `tools/amsterdam_minimal_reload_probe.gd`.

## Start, Bilder und Grenzen

Über `Start_Zombie_Escape_Europe_PC_Preview.bat` neu starten, damit eine bereits laufende ältere Spielinstanz die Änderungen lädt. Die folgenden Bilder stammen aus dem aktuellen Stand:

![Abschluss ohne Reifen- oder Panzerungskauf](../build/balance-minimal-abschluss.png)

![Freiwillige Schutz- und Reifenkäufe geben zusätzliche Reserve](../build/balance-minimal-komfort.png)

Der nächste Schritt ist Stefans persönliche Spielabnahme. Danach die späteren Teile und Preise für Utrecht/Breda planen. Diese Städte wurden nicht gebaut; deren fünf bis acht Versuche bleiben Planungsziele. Keine neue Android-/Telefonprüfung und keine Veröffentlichung.

## Nachkorrektur nach persönlichem Spieltest
Der frühe Nitro-Einsatz war in den ursprünglichen Fahrten nicht ausreichend abgedeckt. Er wurde nachgestellt und korrigiert: Nitro I hält beim Kombi jetzt etwa sechs Sekunden; nach Boostende fällt die Geschwindigkeit nicht mehr abrupt auf das Motortempo. Sichtbare Vollfahrt mit frühem Nitro und demselben Vier-Käufe-Profil bestanden. Maßgeblicher Ergänzungsbericht: design/schleusensprung-nitro-anlauf-2026-11-08.md.
