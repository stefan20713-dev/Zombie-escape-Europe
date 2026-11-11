# Verbindlicher Auftrag: ausschließlich Panzerungsupgrade

Diese Vorgabe ersetzt für die aktuelle Arbeit die früher vorgeschlagenen unabhängigen Käufe für Rammbock, Fenstergitter und Licht sowie den früheren Vollausbau. Es wird ausschließlich die vorhandene Kategorie PANZERUNG gestaltet und später umgesetzt. Keine zusätzliche Kaufkategorie RAM oder GITTER anlegen.

## Bestätigte Reihenfolge
0. Originaler Serien-Kombi ohne neue Schutzteile.
1. Fenstergitter: feine Streben und angepasste Rahmen, Fenster bleiben sichtbar.
2. Fenstergitter + der bisherige Rammbock aus Stufe 3. Aktuelle verbindliche Bildvorlage: 02-rammbock-v3.png. Der frühere sehr kleine Keil entfällt.
3. Fenstergitter + ein nochmals deutlich größerer, höherer und stärker verstärkter Rammbock; ersetzt den Rammbock aus Stufe 2. Aktuelle verbindliche Bildvorlage: 03-rammbock-v3.png.
4. Vorherige Schutzteile + erste angeschraubte Metallplatten an den unteren Türen.
5. Voll ausgebaute PANZERUNG: gleiche Gitter, verstärkter großer Rammbock und vollständigere, geformte Metallplatten an Türen und Schwellern. Orange Serienkarosserie klar erkennbar.

KEIN Zusatzlicht, KEIN Nitro-Anbau, KEINE Geländereifen, KEINE Höherlegung, KEIN Motortuning in dieser Bildfolge. Serienräder, Radstand und Fahrzeugidentität beibehalten. Bestehende andere Upgrade-Systeme und bereits gekaufte Teile bleiben beim späteren Einbau funktionsfähig, werden durch den Panzerungskauf jedoch nicht verändert oder kostenlos freigeschaltet.

## Dateien
Die fünf Bildkonzepte zeigen nur Panzerungsstufen. Für Stufe 2 und 3 ausschließlich die neueren Dateien mit Endung -v3 verwenden. Die Bilder 04-metallplatten.png und 05-vollausbau.png bleiben Vorlagen für Metallplatten und Gitter; deren alte Rammböcke sind überholt. In beiden Stufen den neuen großen Rammbock aus 03-rammbock-v3.png unverändert weiterverwenden. Das Originalasset assets/kombi_body_0.5.10.png bleibt die verbindliche Grundlage. Imagegen-Konzepte sind visuelle Referenzen, keine fertigen zusammengesetzten Fahrzeugsprites. Kleine Abweichungen zwischen Bildern nicht als beabsichtigte Änderungen an Karosserie oder Rädern übernehmen.

## Späterer Umsetzungsauftrag
Zuerst aktuellen Code und Spielstände lesen. Vorhandenes armor-Feld verwenden und kontrolliert von bisher drei auf fünf kaufbare Stufen erweitern. Keine gespeicherten Käufe verlieren. Eine einmalige, versionierte Migration definieren und dokumentieren, damit ein bisheriger Vollausbau seine bisher bezahlte Wirkung behält; keine stillschweigende Abwertung oder erneute Bezahlung alter Wirkungen. Preise und Effekte je Stufe transparent und an tatsächliche Trefferarten gebunden festlegen.

Panzerungsstufe darf weder Motor-/Tank-/Nitrostufe noch Reifen oder Radstand verändern. Aufsummierte Upgrade-Punkte dürfen beim Kombi keine fremde Komplettkarosserie aktivieren. Schutzteile als getrennte transparente Ebenen zum Serienauto montieren; Räder bleiben unabhängig drehbar. Der große Rammbock ersetzt den kleinen, sie werden nicht übereinander gezeichnet.

Kauf, Vorschau, Münzabzug, Stufenanzeige und Speicherung an vorhandene Werkstatt anbinden. Jede Stufe muss einzeln sichtbar sein, in Garage und Fahrt identisch. Ab Stufe 2 Frontkontakt entsprechend der Rammbockausdehnung berücksichtigen; tatsächliche Kollisionen prüfen und Bodenfreiheit erhalten. Schutzwirkung muss implementiert sein, bevor UI sie verspricht. Keine pauschalen Licht-, Nitro- oder Geschwindigkeitsboni.

Zunächst Serienzustand und Stufe 1 liefern, PC-Vorschau bereitstellen und Feedback abwarten. Danach Stufen 2–5 einzeln umsetzen. Keine Kampagnen-, Store- oder anderen Tuningarbeiten nebenbei.

Aktueller Arbeitsschritt in diesem Chat: nur Konzepte und Übergabeauftrag erstellen, keine Änderung am Spielcode.
