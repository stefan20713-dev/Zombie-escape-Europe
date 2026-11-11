# Amsterdam – mittleren Ausbau abgestimmt, 8. November 2026

## Ergebnis und Start
Die aktuelle PC-Fassung ist mit Motor II, Nitro I, Reifen II, Tank II und Panzerung II ohne Waffe durchfahrbar. Zwei unterschiedliche Fahrverläufe erreichten das Ziel mit Reserve. Zusätzlich wurde ein frischer echter Spielerweg bis zum Abschluss im vierten Versuch geprüft.

Start: `Start_Zombie_Escape_Europe_PC_Preview.bat`. Ein bereits laufendes Spiel neu starten, damit es die geänderten Dateien lädt. Persönliche Spielstände und gekaufte Teile bleiben erhalten.

## Geprüfte Sicherung
Vor den Änderungen wurden die beiden betroffenen Laufzeitdateien in `Sicherungen/Amsterdam_Balance_vorher_2026-11-08_20-21-12.zip` gesichert. Beide Archiveinträge wurden nach dem Schreiben per SHA-256 mit den Originaldateien verglichen; das zugehörige JSON enthält `Verified: true` und die ursprünglichen Dateipfade. Die vorhandenen vollständigen Sicherungen bleiben erhalten.

## Änderungen
- Amsterdam-Verbrauchsfaktor von 0,82 auf 0,68 gesenkt, rund 17 % weniger Verbrauch gegenüber dem vorherigen Amsterdam-Stand. Tankgrößen, kaufbare Stufen und Nitroverbrauch/-leistung bleiben unverändert.
- Die einleitenden Begegnungen bis 700 m behalten ihre bisherige Schadensbelastung. Zwischen 700 und 1.000 m geht der Faktor für panzerungsskalierte Treffer-/Klammer-/Straßenschäden weich von 1,0 auf 0,62 über. Das reduziert die über die lange Strecke angesammelte Belastung. Keine Heilung, kein Lebenspunkte-Auffüllen und keine garantierte Reichweite.
- Der Schadensfaktor ist eine neutrale, instanzbezogene Eigenschaft des gemeinsamen Fahrzeugs. Nur die Amsterdam-Vorschaufahrt setzt ihn; andere Fahrtszenen bleiben bei 1,0. Beim Neustart wird er zurückgesetzt. Es gibt keine Änderung der gekauften Panzerungsstufe und keine Abhängigkeit von Fahrzeuggrafiken.
- Treffer behalten ihre räumlichen Kontakte, typspezifischen Tempoverluste und sichtbaren Reaktionen. Brückengeometrie, reale Geschwindigkeit, Sprungflugbahn, Motor- und Nitroleistung wurden nicht verändert.
- Preise, Einnahmenformeln, Teilefreischaltungen und Speicherschema wurden nicht verändert. Spätere Kaufverfügbarkeit für Utrecht/Breda bleibt ein eigener nächster Planungsschritt.

## Sichtbare Fahrten mit echten Eingaben
Alle Versuche mit isoliertem APPDATA, ohne persönliche Spielstände und ohne Eingriff in laufende persönliche Spielsitzungen. Die vier Profilfahrten verwenden die tatsächlich geänderten Produktionsszenen, keine experimentellen Fahrzeugkopien und keine nachträglich erstatteten Schäden. Gas, Bremsen, Balance und Nitro werden über Tastaturereignisse bedient.

| Profil | Entfernung | Resttank | Zustand | Ergebnis |
| --- | --- | --- | --- | --- |
| Serie, alle Stufen 0 | 671 m | 33,5 % | 0 % | Frühe Käufe bleiben erforderlich. |
| Motor I, Nitro II, Reifen/Tank/Panzerung I | 1.310 m | 9,5 % | 8,7 % | Schleuse erreicht, wegen tatsächlicher Flugbahn ins Wasser gefallen. |
| Motor II, Nitro I, Reifen/Tank/Panzerung II | 1.800 m | 7,7 % | 19,1 % | Abschluss nach 86,27 s. |
| Dasselbe Abschlussprofil; andere Balance-Schwelle und kurze echte Bremsung vor der Schleuse | 1.800 m | 11,9 % | 25,1 % | Abschluss nach 81,05 s. Unterschiedlicher Fahrstil ist nicht automatisch langsamer; dies ist kein Nachweis, dass jeder Fahrfehler abgefangen wird. |

Die frühere Zielspanne 900–1.200 m für Motor I/Nitro II ist damit kein präzises Versprechen. Mit passend mitgekauften übrigen Teilen und guter Fahrt ist die Schleuse als nächstes Hindernis erreichbar. Es wird keine künstliche Begrenzung auf 1.200 m eingeführt. Stefans bisher gemeldete 954 m lassen sich ohne vollständigen Spielstand und identische Fahrweise nicht unmittelbar dagegen vergleichen.

Primärbeleg: `.local_probe/balance-final.log`, strukturierte Ergebnisse `.local_probe/balance-final-results.json`, Prüflauf `tools/amsterdam_balance_final_probe.gd`. Screenshots `build/balance-final-serie.png`, `balance-final-motor1-nitro2.png`, `balance-final-abschluss.png`, `balance-final-abschluss-unruhiger.png` wurden gerendert; Abschluss und Fehlsprung angesehen.

## Echter Spielerweg, Einkommen und unabhängige Käufe
Frischer Spielstand mit normalen 100 Startmünzen; Hauptmenü, Einführung, Losfahren, Auswertung und Werkstatt über tatsächliche Mausereignisse. Keine zusätzlichen Testmünzen und kein vorzeitig freigeschaltetes Teil.

1. Serie: 680 m, Einkommen 136, Guthaben 236. Motor-/Tank-Einstiegspaket für 95 gekauft.
2. Motor/Tank I: 991 m, Einkommen 203. Guthaben 344; Nitro I einzeln für 45 gekauft.
3. Motor/Tank/Nitro I, übrige Teile 0: 991 m, Einkommen 203. Guthaben 502. Nitro wurde in dieser Prüfstrategie erst vor der Schleuse benutzt; deswegen bringt sein Kauf hier noch keinen Reichweitengewinn. Das ist keine Aussage, dass Nitro vor der Schleuse nutzlos sei.
4. Aus den tatsächlichen Einnahmen Motor II, Tank II, Reifen I+II und Panzerung I+II für zusammen 400 gekauft. Jeder Mauskauf zieht genau einmal den tatsächlichen Preis ab und ändert nur seine Kategorie. Danach verbleiben 102 Münzen. Mit diesem Profil ohne Waffe die ganzen 1.800 m geschafft; Einkommen 410, Guthaben nach Rückkehr 512. Alle gekauften Stufen bleiben erhalten.

Damit ist ein möglicher Einstieg innerhalb der geplanten vier bis sieben Versuche direkt nachgewiesen. Das garantiert nicht dieselbe Anzahl bei jeder Kaufreihenfolge oder Fahrweise. Selbst die frühen Fehlversuche finanzieren sinnvolle Käufe; die 540 Münzen Gesamtkosten des Abschlussprofils wurden ohne Sondergutschrift bezahlt.

Protokoll `.local_probe/balance-player-final.log`, Prüflauf `tools/amsterdam_balance_player_probe.gd`. Ergebnisaufnahme `build/balance-spielerweg-balance-vierter-versuch-ergebnis.png`. Frischer Prozess kontrolliert anhand `.local_probe/balance-player-expected.json` das Guthaben 512 und sämtliche Stufen: `.local_probe/balance-reload-final.log`, `tools/amsterdam_balance_reload_probe.gd`.

## Weitere Gegenprüfungen
- Schleusensprung: Motor I/Nitro I scheitert bei realen 122,76 km/h; Motor II ohne Nitro bei 106,78 km/h; Motor II/Nitro I landet bei realen 150,48 km/h korrekt. Die Zielgeschwindigkeit 135 km/h und sichtbare Flugbahn bleiben maßgeblich. `.local_probe/balance-lock.log`.
- 96 Kaufvorschauen gegen tatsächlich konfigurierte Fahrzeugwerte, drei bestehende Fahrzeuge, Maximum und Einsteigerpaket: `.local_probe/balance-upgrade_preview_test.log`.
- Primär-/temporäre/Sicherungsdatei, Migration und Erhalt beschädigter Originale: `.local_probe/balance-progress_save_recovery_test.log`.
- Bodenkontakt für vier vorhandene Reifenstufen: `.local_probe/balance-wheel_ground_contact_test.log`.
- Räumliche Treffer, einmalige Belohnungen, progressive Schäden, ablösbare Teile und Zurücksetzen: `.local_probe/balance-amsterdam_combat_pass_test.log`.

## Grenzen und nächster Schritt
Dies ist eine geprüfte PC-Abstimmung, keine neue Android-Leistungsprüfung. Unterschiedliche Fahrweisen, freiwillig häufiger Nitrogebrauch und schwere Fehler können weiterhin früheres Scheitern verursachen. Jetzt den Stand persönlich spielen und Rückmeldung zu Reserven und Schwierigkeit sammeln. Danach spätere Teile/Preise für Utrecht und Breda festlegen; deren angestrebte fünf bis acht Versuche sind ohne spielbare Strecken noch nicht belegt. Keine weitere Stadt oder neues Fahrzeug wurde gebaut.

## Durch neueren Nutzerauftrag ersetzt
Für den ersten Level waren die hier dokumentierten neun gekauften Stufen zu viel. Aktuell reichen vier Käufe: Motor I+II, Tank I und Nitro I. Reifen und Panzerung sind optional. Maßgeblicher aktueller Prüfbericht: design/amsterdam-vier-kaeufe-2026-11-08.md.
