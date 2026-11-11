# Schleusensprung – früher gehaltener Nitro-Einsatz korrigiert

8. November 2026. Nutzer meldet, den Sprung mit Motor II, Nitro I und Tank I nicht zu schaffen. Er hält Gas und Leertaste bereits im Anlauf gleichzeitig. Genau dieses Profil ohne Reifen, Panzerung und weitere Teile wurde nachgestellt. Die vorherigen Vollfahrten verwendeten einen späteren, günstigen Nitro-Beginn und deckten diese Eingabe nicht ausreichend ab.

## Nachgestellter Fehler
Nitro I hatte 120 Vorrat bei 29 Einheiten Verbrauch pro Sekunde, also nur etwa 4,14 Sekunden Schub. Bei frühem Einschalten ging der Vorrat vor dem Absprung aus. Danach begrenzte die Fahrlogik die Geschwindigkeit ohne Ausrollphase sofort auf das normale Motortempo. Es handelte sich nicht um einen fehlenden Tank-, Reifen- oder Panzerungskauf.

| Nitro ab ungefähr | Vorheriger Absprung | Ergebnis vorher | Absprung nach Korrektur | Ergebnis danach |
| --- | --- | --- | --- | --- |
| 1.100 m | 114 km/h | Wasser | 150,48 km/h | Landung geschafft |
| 1.130 m | 114 km/h | Wasser | 149,18 km/h | Landung geschafft |
| 1.200 m | 135,61 km/h | Landung knapp geschafft | 135,61 km/h | Landung geschafft |

Die Prüfskripte vergleichen Weltpositionen. Die HUD-Strecke beginnt sieben Meter später; die Angaben sind deshalb bewusst gerundet. Diese drei Gegenchecks wurden beschleunigt ohne Grafik ausgeführt: `.local_probe/lock-timing-before.log` und `.local_probe/lock-timing-final.log`.

## Änderungen
- Nach Ende oder Loslassen eines tatsächlich aktiven Boosts bleibt vorhandener Schwung erhalten. Der Motor fügt oberhalb seiner normalen Geschwindigkeitsgrenze keine zusätzliche Antriebskraft hinzu; Luft-/Rollwiderstand, Bremsen, Steigung und Treffer bauen Tempo weiter ab. Die reguläre Boost-Obergrenze bleibt bestehen. Kein gratis zusätzlicher Schub und keine erfundene Tachogeschwindigkeit.
- Konfiguration und Neustart setzen diesen Ausrollzustand zurück. Ohne vorherigen Boost gelten die bisherigen Motorgrenzen. Die gemeinsame Änderung wurde auch an den beiden weiteren bereits registrierten Fahrzeugen geprüft; keine neuen Fahrzeuge oder Inhalte erstellt.
- Nitroverbrauch beim Kombi auf 20 Einheiten pro Sekunde abgestimmt. Die unveränderten 120 Einheiten von Nitro I ergeben jetzt etwa sechs Sekunden Schub. Kapazität, Kaufpreis, Schubkraft und Nachladerate bleiben unverändert. Andere bestehende Fahrzeuge behalten ihren Nitroverbrauch von 34 Einheiten pro Sekunde.
- Eine Ausrollkorrektur allein reichte bei den frühen Testeingaben noch nicht. Deshalb wurde zusätzlich die bislang sehr knappe Nitrodauer korrigiert. Der Zwischenversuch ist in `.local_probe/lock-timing-after.log` dokumentiert und nicht als erfolgreicher Endstand ausgegeben.
- Der Hinweis im Anlauf nennt jetzt ausdrücklich: **AB 1160 M GAS + NITRO HALTEN · ZIEL 135 KM/H**.
- Brückenabstand, Absprung-/Landehöhe, Ballistik und Mindestzielgeschwindigkeit bleiben unverändert. Besitz von Motor II/Nitro I garantiert keinen Erfolg, wenn Vorrat schon viel früher vollständig verbraucht wurde, gebremst oder die nötige Geschwindigkeit nicht erreicht wird.
- Keine Änderung von persönlichen Spielständen, Münzen, gekauften Stufen oder Freischaltungen.

## Sichtbare vollständige Prüfung
Zusätzlich eine komplette grafische PC-Fahrt mit Motor II, Nitro I, Tank I und allen anderen Kategorien 0. Gas über W und Nitro über Leertaste gehalten, Nitro bereits ab ungefähr 1.100 m. Keine Teleportation, keine erzwungene Geschwindigkeit und keine zusätzliche Testausrüstung.

Absprung mit 150,48 km/h, echte Landung und anschließend 1.800 m erreicht. Ergebnisaufnahme: `build/lock-nitro-early-fixed.png`, etwa 80,8 Sekunden, rund 16 % Tank und 19 % Zustand verbleiben. Die Aufnahme wurde angesehen. Protokoll `.local_probe/lock-nitro-visual.log`, Prüflauf `tools/lock_nitro_visual_probe.gd`.

## Gegenprüfungen und Sicherung
- `tests/boost_coast_test.gd`: Kombi, Lieferwagen und vorhandener Pickup behalten nach Loslassen/Leerwerden tatsächlichen Schwung; leeres gehaltenes Nitro erzeugt keinen Gratisvorrat; Neustart setzt den Zustand zurück; ohne vorherigen Boost bleibt die normale Motorgrenze unverändert. `.local_probe/nitro-boost_coast_test.log`.
- Bestehender Schleusen-Zielstufentest: Motor I/Nitro I und Motor II ohne Nitro fallen weiterhin ins Wasser; Motor II/Nitro I landet. `.local_probe/nitro-amsterdam_lock_upgrade_target_test.log`.
- 96 Kaufvorschauen gegen reale Fahrzeugwerte für drei registrierte Fahrzeuge: `.local_probe/nitro-upgrade_preview_test.log`.
- Vorherige Laufzeitdateien `wagon.gd` und `driving_test.gd` gesichert in `Sicherungen/Schleusensprung_Nitro_vorher_2026-11-08_21-09-54.zip`; beide Einträge nach dem Schreiben per SHA-256 mit den Originalen verglichen. `Verified: true` im JSON daneben.

## Für den persönlichen Test
Spiel vollständig schließen und über `Start_Zombie_Escape_Europe_PC_Preview.bat` neu starten. Nitro vorher aufsparen und ab ungefähr 1.160 m Gas und Leertaste bis zum Absprung halten. Ein schon leerer Vorrat lädt nur bei losgelassener Nitro-Taste wieder auf; es gibt keine automatische Füllung an der Schleuse. Kein zusätzlicher Upgrade-Kauf nötig. PC geprüft; keine neue Telefonprüfung.
