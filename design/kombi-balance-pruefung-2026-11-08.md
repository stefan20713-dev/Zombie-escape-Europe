# Prüfung der Kombi-Ausbaukurve – 8. November 2026

## Ergebnis
Der geplante Drei-Städte-Verlauf ist technisch machbar. Er ist noch nicht als komplette Kampagnenbalance umgesetzt. Amsterdam kann mit Motor II, Nitro I sowie Reifen, Tank und Panzerung II ohne Waffe abgeschlossen werden, wenn Verbrauch und Schadensbelastung passend abgestimmt werden. Ein isolierter grafischer Versuch hat das nachgewiesen; seine Reserven sind für eine verlässliche Freigabe noch knapp. Utrecht und Breda sind nicht gebaut, deshalb sind deren Versuchsanzahlen weiterhin Planungsziele.

Die echten Spielwerte, Kaufpreise, Freischaltungen und persönlichen Spielstände wurden bei dieser Prüfung nicht verändert. Die Experimente verwendeten eigene APPDATA-Verzeichnisse und eine ausschließlich vom Prüfstand geladene Kopie der Fahrtszene. Keine Testmünzen wurden einem persönlichen Profil gutgeschrieben.

## Fahrprüfungen

Alle neuen Fahrten verwendeten echte Tastaturereignisse für Gas, Balance und Nitro, tatsächliche Kontakte, Gegner und die vollständige Strecke. Kein erzwungener Erfolg und kein Teleport über den Sprung.

| Profil / Prüfung | Ergebnis | Einordnung |
| --- | --- | --- |
| Unveränderter Serienwagen, vorhandener realer Spielerweg | 680 m | Innerhalb des geplanten Einstiegsbereichs. |
| Unverändert: Motor I, Nitro II, Reifen/Tank/Panzerung I, sonst 0 | 1.174 m; Zustand 0, Resttreibstoff 5,47 | Bestätigt die Größenordnung 900–1.200 m bei vergleichbar mitgekaufter Ausrüstung. Stefans gemeldete 954 m sind plausibel; seine übrigen Teile und Fahrweise sind nicht vollständig bekannt. |
| Unverändert: Motor II, Nitro I, Reifen/Tank/Panzerung II, sonst 0 | Vorheriger echter Kauf-/Fahrtest: 1.625 m, Tank leer | Der aktuelle Spielstand erreicht die festgelegte Zielbalance noch nicht. |
| Dasselbe Abschlussprofil, nur Verbrauch im Prüfstand um 12 % gesenkt | 1.628 m, Resttreibstoff 12,09, Zustand 0 | Eine reine Tankkorrektur reicht nicht. |
| Dasselbe Abschlussprofil, im Prüfstand 12 % weniger Verbrauch und 20 % weniger von der Panzerungsfunktion skalierten Schaden | 1.800 m in 86,67 s; Resttreibstoff 2,02 von 114 (1,8 %), Zustand 12,89 % | Machbarkeit bei unveränderter Geometrie, Geschwindigkeit und Kaufstufen nachgewiesen. Noch zu geringe Kraftstoffreserve für eine zuverlässige Freigabe an unterschiedlich gute Fahrer. |

Die Schadenskorrektur des letzten Experiments war ein eigener Wagon-Untertyp im Prüfstand; sie betrifft nicht die eigentlichen Panzerungswerte. Sie beweist einen möglichen Abstimmungsbereich, legt aber keine pauschale Verringerung aller Schäden in jeder Stadt oder bei jeder Stufe fest. Der nächste Umsetzungsstand muss auch schwächere Profile erneut prüfen.

Protokolle:
- `.local_probe/milestone-player-loop-1.log` – echte erste Fahrten, Käufe und Einnahmen.
- `.local_probe/earned-drive.log` – unverändertes mittleres Abschlussprofil.
- `.local_probe/balance-mid.log` – neue Motor-I-/Nitro-II-Fahrt.
- `.local_probe/balance-feasibility.log` – nur Verbrauch verändert.
- `.local_probe/balance-combined.log` – Verbrauch und Schaden kombiniert.
- Sichtbarer Abschluss des isolierten Experiments: `build/balance-combined-candidate-ergebnis.png`.

Die aktuellen Versuchsskripte liegen in `tools/amsterdam_balance_mid_probe.gd` und `tools/amsterdam_balance_feasibility_probe.gd`. Die ausschließlich experimentellen Szenenkopien und der abgeleitete Wagon befinden sich unter `.local_probe/balance-feasibility/`; sie werden vom normalen Startprogramm nicht geladen.

## Geld, Käufe und drei Städte

Aus dem aktuellen Code berechnet:
- Amsterdam-Zielprofil kostet insgesamt **540 Münzen**: Motor I+II 150; Reifen I+II 125; Tank I+II 115; Panzerung I+II 105; Nitro I 45.
- Alle fünf Kernkategorien auf Maximum kosten zusammen **1.235 Münzen**, ohne Waffe und Zusatzkategorien.
- Nach dem Amsterdam-Zielprofil fehlen damit nur **695 Münzen** bis zum gesamten Kern-Vollausbau.
- Der gemessene Spielerweg brachte in den ersten drei Versuchen 136 + 201 + 201 = **538 Münzen**, dazu 100 Startmünzen. Das Zielprofil ist somit gut erreichbar.
- Eine gute Vollfahrt brachte **410 Münzen**. Bei unverändert frei verfügbaren Teilen kann man den restlichen Kern-Vollausbau deshalb schon nach wenigen weiteren Amsterdam-Versuchen kaufen. Das passt nicht zum gewünschten Abschluss des Ausbaus erst in Breda.
- Die Waffe kostet derzeit 650 Münzen und verlangt bereits maximalen Kern-Ausbau; außerdem ist sie im Code auf Amsterdam beschränkt. Diese Freischaltung passt nicht zur geplanten sinnvollen Einführung in Utrecht.

Folgerung: Frühe Einnahmen nicht pauschal stark kürzen. Die günstigen Anfangskäufe funktionieren. Stattdessen müssen Verfügbarkeit und Preise der späteren Verbesserungen über die drei Städte geplant werden. Beispielsweise spätere Bauteile an nachvollziehbare Stadt-/Werkstattfunde knüpfen, Motor III in Utrecht und letzte Reserven in Breda anbieten. Bestehende Käufe bleiben erhalten. Keine künstliche Reichweitensperre, kein absichtliches Schwächen des vorhandenen Autos beim Stadtwechsel. Eine Stadtsperre allein garantiert noch keine 5–8 motivierenden Versuche; Streckenbelastung und Kaufzeitpunkte müssen gemeinsam getestet werden.

## Verlässlichkeit der geplanten Versuchsanzahl

Planungsziele bleiben: Amsterdam 4–7, Utrecht 5–8, Breda ungefähr 5–8 normale Versuche. Gute Spieler dürfen früher erfolgreich sein. Es gibt keine feste Anzahl vorgeschriebener Fehlschläge. Nach spätestens zwei ordentlichen Fehlversuchen soll ein hilfreicher Kauf erreichbar sein.

Amsterdam ist dafür als nächstes direkt abstimmbar. Für Utrecht und Breda lässt sich die Anzahl heute nicht ehrlich bestätigen: Streckenlänge, Hindernisse, Schäden, Einnahmen und neue Teile fehlen noch. Es wird ausdrücklich kein Test nicht vorhandener Städte behauptet.

## Empfohlener nächster begrenzter Umsetzungsstand

1. Amsterdam-Verbrauch und konkrete Schadensquellen auf das festgelegte Abschlussprofil abstimmen. Ziel bei ordentlicher Testfahrt: ungefähr 5–10 % Tank und 15–25 % Zustand am Ende, statt der knappen experimentellen Reserve. Dies ist ein Abstimmungsziel, kein garantierter Restwert.
2. Danach mehrere echte Fahrten mit Serie, Motor I/Nitro II und Abschlussprofil durchführen; mindestens eine weniger saubere Fahrt einbeziehen. Sprungflugbahn und tatsächlich benötigte Geschwindigkeit unverändert nachvollziehbar halten.
3. Den Drei-Städte-Teileplan einschließlich Waffe und offenen Panzerungsstufen konkretisieren, bevor neue Freischaltungen eingebaut werden. Bezahlte Käufe und unabhängige Kategorien erhalten.
4. Erst anschließend Utrecht als eigenen spielbaren Abschnitt entwickeln und dort das Ziel von 5–8 Versuchen tatsächlich messen.

## Neuerer Stand nach Freigabe zur Umsetzung
Die oben beschriebenen isolierten Experimente sind historisch. Die reguläre PC-Fassung wurde inzwischen gezielt abgestimmt und erneut geprüft. Aktueller Bericht: design/amsterdam-balance-umsetzung-2026-11-08.md. Die Aussage 'normale Spielwerte unverändert' gilt nur für die frühere Machbarkeitsprüfung, nicht für diesen neueren Umsetzungsstand.
