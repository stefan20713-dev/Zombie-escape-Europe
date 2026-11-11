# Amsterdam · PC-Prüfstand

Der gemeinsame PC-Start ist `Start_Zombie_Escape_Europe_PC_Preview.bat`. In der Werkstatt führt **Losfahren** zur aktuellen Amsterdam-Strecke über 1.175 m. Das gewählte Fahrzeug und seine montierten Upgrades werden übernommen. Über **Zur Werkstatt** im Pause- oder Ergebnismenü geht es zurück. Die Fahrt ist eine Vorschau ohne Kampagnenfortschritt. Werkstattkäufe werden wie gewohnt gespeichert.

Der direkte Streckentest mit Serien- und Tuningprofil ist weiterhin über `tools/PC-Teststarts/Start_Amsterdam_Preview_PC.bat` erreichbar. Der normale Godot-Start ohne Vorschauoption öffnet die Hauptkampagne.

| Prüfung | Ergebnis |
| --- | --- |
| Untere Vorschau-Route | 1.175 m in 57,4 s, 25 Treffer, drei Landungen |
| Obere Vorschau-Route | 1.175 m in 45,2 s, 25 Treffer, zwei Landungen, 39 Physikschritte Kontakt mit dem Brückendeck |
| Serien-Kombi | Unterführung bis 535,2 m mit 72,0 km/h an der Abzweigung, gerenderter PC-Lauf in Echtzeit. 95 % der gemessenen Physikschritt-Abstände höchstens 16,70 ms. |
| Vorschau-Touch | Simulierte Berührungen bei 1440 × 648. Gas und Nitro gleichzeitig, getrenntes Loslassen, Bremse und Pause geprüft. |
| Werkstatt | Gerendert bei 1280 × 720 und 1440 × 648. Fahrtstart per Enter geprüft. |
| Gemeinsamer PC-Start | Nitro in separatem Profil gekauft, Übernahme in die 1.175-m-Strecke und Erhalt nach Rückkehr zur Werkstatt geprüft. |
| Kombi-Tuning | 16 Käufe mit Preis und erneutem Laden geprüft. Einzel- und Kombinationsgrafiken gerendert. |
| Fahrwirkung | 44 kurze Vergleichsläufe und 16 Läufe bis hinter die erste Holzbarriere. Waffenabschuss mit Fahrtbelohnung separat in der Hauptkampagne bestätigt. |
| Projektgröße | Nach Entfernen von 27 alten Testordnern 3,47 GB. Vollständige Sicherung vor der Änderung liegt außerhalb des Projektordners. |

Die Fahrten liefen mit simulierten Eingaben. Die Bildfolgen im Abstand von 50 m zeigen nach der Korrektur eine durchgehende Fahrbahn. Sie ersetzen keine Sichtprüfung jedes Zwischenbilds.

Bildnachweise liegen in `build/goal-werkstatt.png`, `build/goal-werkstatt-breit.png`, `build/amsterdam-review-preview.png`, `build/amsterdam-review-upper_route.png`, `build/goal-tuning-einzeln.png` und `build/goal-tuning-kombiniert.png`.

Offen sind die zeitlich durchgehende Prüfung der Hintergrundbewegung und die Touch- und Leistungsprüfung auf Android. Werkstatttor und untere Seitenfensterscheiben verwenden Amsterdam-Streckengrafik. Der Fensterbogen gehört zur festen Illustration, und die Kampagne bietet derzeit nur Amsterdam. Die Waffenwirkung wurde im normalen Spiel geprüft. Die separate Streckenvorschau zeigt die montierte Waffe.
