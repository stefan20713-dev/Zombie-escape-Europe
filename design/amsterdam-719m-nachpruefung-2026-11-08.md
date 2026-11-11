# Nachprüfung: gemeldeter Abbruch bei 719 m

8. November 2026. Auftrag: mit Motor II, Nitro I, Tank I und sonst Serienausrüstung erneut fahren. Nutzer nennt Karosserie/Tank als mögliches Ende. Keine weiteren Änderungen an Schadens- oder Verbrauchswerten auf Verdacht.

## Ergebnis
Mit diesem tatsächlich montierten Profil erreichen die neuen Fahrten **1.800 m**. Der exakte Nutzerabbruch bei 719 m ist damit nicht reproduziert. Im persönlichen Bedienprotokoll wurde aber eine konkrete Abweichung bei der Teileauswahl gefunden.

## Gefundene Auswahlabweichung
Das letzte persönliche Spielprotokoll wurde nur gelesen. Es zeigt nach dem Serienfahrzeug-Umschalten einen nicht erfassten Klick bei (99, 612), danach zwei Upgrade-Käufe, später ausdrücklich Nitro und Tank. Die Werkstatt startete bis zu dieser Korrektur standardmäßig mit `_garage_selected_part = "tires"`; beim Serienfahrzeug-Umschalten wurde diese Auswahl nicht zurückgesetzt. Ohne erfolgreichen Motor-Kategorieklick gehen daher die beiden ersten Käufe auf Reifen I/II, nicht Motor I/II.

Die daraus rekonstruierte Kombination lautet Motor 0, Reifen II, Tank I, Nitro I, Panzerung 0. Die Vergleichsfahrt mit dieser Kombination endet bei **951,61 m** durch zerstörte Karosserie, mit noch 37,41 Einheiten Benzin. Das belegt die Relevanz der unterschiedlichen Ausrüstung, nicht den exakten 719-m-Abbruch. Abweichende Eingaben und Kontakte bleiben mögliche weitere Ursachen.

## Kleine UI-Korrektur
Nur `scripts/hud.gd` geändert:
- Motor ist beim Öffnen der Werkstatt vorausgewählt.
- Beim Umschalten des Serienfahrzeug-Tests wird die Auswahl auf Motor gesetzt und ein eventuell offenes Einstellungsfeld geschlossen.
- Die Kaufbestätigung nennt die tatsächliche Kategorie und Stufe, z. B. **MOTOR STUFE 2 EINGEBAUT**, statt lediglich „Verbesserung eingebaut“.

Keine gekauften Teile gelöscht, keine persönlichen Münzen geändert, keine Spielstände zurückgesetzt. Die Prüfungen liefen in eigenen APPDATA-Verzeichnissen; für den tatsächlichen Serienfahrzeug-Bedienweg wurde eine Kopie des gespeicherten Profils verwendet. Der Originalspielstand wurde dabei nicht beschrieben.

Vor der Änderung: `Sicherungen/Werkstatt_Motorauswahl_vorher_2026-11-08_21-48-06.zip`, nach dem Schreiben SHA-256 mit der Originaldatei verglichen. `Verified: true` im JSON daneben.

## Neue Prüfungen
| Bedienung und Profil | Bei 719 m | Fahrtende |
| --- | --- | --- |
| Motor II, Tank I, Nitro I, sonst 0; nur Gas, Nitro im Schleusen-Anlauf, keine A/D-Korrektur | 57,85 Benzineinheiten von 92, Zustand 51,88 % | 1.800 m; 8,32 Benzineinheiten und 8,65 % Zustand übrig |
| Dasselbe Profil mit A/D-Korrekturen | 62,57 Benzineinheiten, Zustand 64,27 % | 1.800 m; 14,35 Einheiten und 18,69 % Zustand übrig |
| Dasselbe Profil mit früheren Nitro-Abschnitten vor der Schleuse, keine A/D-Korrektur | Kein Abbruch | 1.800 m; 11,93 Einheiten und 23,58 % Zustand übrig |
| Nitro vom Start an dauerhaft gehalten | Kein Abbruch bei 719 m | Rund 1.310 m; Nitro vor der Schleuse leer, Sprung misslingt |

Die obigen Varianten wurden beschleunigt ohne Grafik geprüft. Zusätzlich der **korrigierte echte Werkstatt-Bedienweg grafisch**: Serienfahrzeug-Test öffnen, absichtlich den nicht erfassten Klick nachstellen, zweimal KAUFEN ohne erneute Kategorieauswahl, danach Nitro I und Tank I kaufen. Nach jedem Motorkauf die tatsächliche Motorstufe, unveränderte Reifen 0 und die ausdrückliche Motor-Kaufbestätigung geprüft. Die Fahrt lädt anschließend tatsächlich Motor II, Reifen 0, Tank I, Nitro I, Panzerung 0. Ohne A/D-Korrekturen bis 1.800 m gefahren und Ansicht bei 719 m aufgenommen und angesehen. Die Serien-Test-Strafmultiplikatoren des Werkstattwagens werden nicht in den tatsächlich neu instanziierten Amsterdam-Fahrtwagen übernommen; dies wurde ebenfalls geprüft.

Nachweise:
- `.local_probe/719-modern-plain.log`, `719-modern-balanced.log`, `719-pulse-nitro.log`, `719-all-nitro.log`.
- `.local_probe/719-stock.log`, `719-wrong-part.log`.
- `.local_probe/719-fixed-ui.log`; `tools/amsterdam_719_ui_fixed_probe.gd` enthält den sichtbaren Bedien-/Fahrtest und den 1.800-m-Abschlusscheck.
- `build/spielerweg-719-kontrolle.png`, `build/spielerweg-719-auswahl-korrigiert.png`.

Nebenbefund: Ein normaler Projektstart ohne den Amsterdam-Werkstatt-Modus kann noch den alten Fahrablauf verwenden. Diese Altarchitektur wurde in diesem begrenzten Auftrag nicht umgebaut. Das vorhandene Startprogramm lädt ausdrücklich den aktuellen Modus; im gelesenen persönlichen Bedienprotokoll folgen auf Losfahren die Merkmale der aktuellen Vorschaufahrt. Der alte Weg ist daher kein belegter Grund des gemeldeten Abbruchs.

## Persönlicher Gegencheck
Spiel neu starten, in der Werkstatt unter **MONTIERT** Motor II, Nitro I und Tank I kontrollieren. Nicht die nächste angebotene Stufe mit der montierten verwechseln. Falls die Fahrt weiterhin bei 719 m endet, wird eine Aufnahme des tatsächlichen Ergebnisbilds samt Tank-/Zustandsanzeige benötigt. Der genaue 719-m-Abbruch bleibt bis dahin offen; die hier nachgewiesene Teileauswahl-Abweichung ist korrigiert.
