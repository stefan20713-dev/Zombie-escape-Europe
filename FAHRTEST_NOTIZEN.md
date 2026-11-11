# Fahrtest Kombi – Schritt 1

Direktstart unter Windows: `tools/PC-Teststarts/Start_Fahrtest_PC.bat`. Alternativ in Godot `scenes/driving_test.tscn` starten.

## Steuerung

- `W` oder Pfeil hoch: Gas
- `S` oder Pfeil runter: Bremse
- `Leertaste` oder `Shift`: Boost
- `A` / `D` oder Links / Rechts: Fahrzeug in der Luft neigen
- `R`: Test zurücksetzen
- `Esc`: Test schließen

Der ursprüngliche Kurztest benutzte dasselbe Kombi-Szenenobjekt und dieselbe Fahrphysik wie die Kampagne. Die unten ergänzte Fassung ersetzt den kurzen Prototyp durch den aktuellen 900-m-Testabschnitt mit Gegnern, gewichtetem Hinderniskontakt, Rampe und Landefläche.

## Maßstab und Fahrgefühl

Das Kombi-Modell ist rund 162 px lang. Bei 4 px/m entsprächen das 40,5 m und ein Radstand von knapp 25 m. Mit 36 px/m sind es rund 4,5 m Karosserielänge, 2,75 m Radstand und etwa 0,5 m Radradius. Das Verhältnis von Physik zu bestehender Fahrzeugzeichnung ist damit konsistent.

Der Projekt-Schwerkraftwert liegt bei 350 px/s²; mit `gravity_scale = 0.88` sind das rund 8,6 m/s². Der Serienmotor mit 78.000 N erzeugt bei 420 kg rechnerisch etwa 5,2 m/s² vor Fahrwiderstand und Steigung. Der serienmäßige 28-m/s-Begrenzer entspricht 101 km/h. Boost gibt zusätzlich rund 5,0 m/s² und öffnet beim Kombi eine eigene höhere Geschwindigkeitszone. Das Motormoment am Hinterrad ist auf leichten Gewichtstransfer begrenzt; in der Luft wirkt der Motor zentral. Bremskraft, Rollwiderstand, Federung und Reifen bleiben an der gemeinsamen Fahrzeugphysik.

Die Kamera folgt schneller, zeigt bei steigendem Tempo mehr Strecke voraus und zoomt bei hohem Tempo leicht heraus. Das erhöht den sichtbaren Weg pro Sekunde, ohne die Tachoanzeige als Ersatz für echte Bewegung zu benutzen.

## Geänderte Dateien in diesem Schritt

- `scripts/campaign_data.gd`: gemeinsame Weltmaßstabs-Konstanten (36 px/m; Altmaßstab 4 px/m).
- `scripts/wagon.gd`, `scenes/wagon.tscn`: Fahrzeugkräfte an den korrigierten Maßstab angepasst; reduzierte Gas-Rotation und zentrale Luftbeschleunigung verhindern, dass Gasgeben den Kombi ungewollt herumreißt.
- `scripts/terrain.gd`, `scripts/backdrop.gd`, `scripts/audio_manager.gd`, `scripts/game.gd`: gemeinsame Maßstabs- und Kamera-Anpassungen.
- `project.godot`: Schwerkraft für den neuen Maßstab.
- `scripts/driving_test.gd`, `scripts/driving_test_course.gd`, `scenes/driving_test.tscn`: unabhängige Teststrecke und Testanzeige.
- `tools/PC-Teststarts/Start_Fahrtest_PC.bat`: direkter Windows-Start.

## Grenzen dieser Vorschau

Das ist ein Fahrgefühl-Test, keine fertige Grafikfassung. Die globale Umrechnung auf 36 px/m betrifft auch die Kampagne; bevor daraus ein längerer Abschnitt wird, ist die Vorschau zu fahren und die Strecke danach gezielt zu beurteilen. Schritt 2 mit 45–60 Sekunden, Gegnern und Hindernissen folgt erst nach dem Fahrfeedback.

## Anpassung nach Fahrfeedback – 2. November 2026

- Der künstliche Rampenimpuls ist jetzt an die tatsächliche Geschwindigkeit und 0,65 m Hindernisfreiheit gekoppelt und auf eine kurze Flugkurve begrenzt. Bei ungefähr 100 km/h ergibt die Formel knapp 0,8 Sekunden Flugzeit statt des bisherigen mehrsekündigen Schwebens.
- Der Kombi folgt der Schwerkraft stärker (`gravity_scale = 0.88`). Die Luft-Neigung reagiert etwas träger, während geringere Winkel-Dämpfung Schwung und Überschläge spürbarer macht.
- Auf Rotterdam gibt es sieben zusätzliche, weiche Höhenprofile mit drei klareren Anfahrtsrampen. Vier weitere Begegnungen ergänzen zwei Fässer, eine schnelle Zombiegruppe und ein Wrack.
- Die Straßenkollision wird alle 1,5 m abgetastet, damit gekrümmte Rampen genauer nachgebildet werden.
- In der Luft und beim Aufsetzen auf nur einem Rad richtet eine sanfte Hilfe die Karosserie wieder an der Straßenneigung aus. Gegenlenken wird bei großer Schräglage um 35 % verstärkt.
- Ein Lauf endet nur nach 0,55 Sekunden stabilem Dachkontakt in Straßennähe; eine kurze kopfüber-Pose in der Luft beendet ihn nicht.
- Der separat gezeichnete Schattenkreis unter dem Kombi wurde entfernt.
- Die frühere isolierte Vorschau-Fahrt hatte keinen verwertbaren Abschlussmarker; der automatische Fahrprobe-Schritt bleibt daher offen. Die Einzelfahrphysik-Checks für Luftausrichtung und echte Beschleunigung bestanden inzwischen in einer isolierten Projektkopie. Die neue Zombie-Haftung und der unveränderte Speicherdatensatz beim Serienstart wurden ebenfalls separat erfolgreich geprüft.

## Nächster Fahrzeugstart – Serien-Kombi

- Der nächste normale Spielstart setzt das ausgewählte Fahrzeug für genau diese Sitzung auf Serienwerte, damit sich die unveränderte Fahrphysik prüfen lässt.
- Die bestehenden Upgrade-Stufen werden getrennt gesichert und während dieses Tests nicht überschrieben. Käufe und Fahrzeugwechsel sind bis zum nächsten Neustart gesperrt; dann werden die gespeicherten Stufen wiederhergestellt.
- Bei einem Zombie-Aufprall kann einer der Gegner sichtbar am Auto hängen bleiben und durch zusätzliche Verzögerung Geschwindigkeit abziehen. Leichte Zombies lassen früher los; kräftige bleiben länger. Manche stürzen direkt ab.
- Jeder festhängende Zombie klammert sich mit zwei Händen an das Dach und senkt während des Hängens zusätzlich den Karosseriezustand.
- Der Serien-Kombi ist auf 72 km/h begrenzt. Jede Motorstufe gibt 21 km/h Höchstgeschwindigkeit dazu; drei Stufen erreichen 135 km/h ohne Boost und maximal 160 km/h mit Boost.
- Im Serien-Test sind Spritverbrauch und Trefferschaden erhöht: 1,45-facher Verbrauch, 1,65-facher Schaden und mindestens sechs Zustandsprozent pro Zombie-Aufprall.
- Das Fahr-HUD nutzt jetzt eine analoge Tachoscheibe bis 160 km/h mit integrierter Tankfüllung, blinkender roter Reserve-/Leerwarnlampe und eigener Karosseriezustandsanzeige.

## Meilenstein 1 – Fahrgefühl und Action – 3. November 2026

- Der eigenständige Fahrtest ist 900 m lang. Er kombiniert wellige Anfahrt, zwei Zombiegruppen, leichte Barrieren, schwere Wracks, eine 8-m-Lücke mit echter Landefläche und kurze Erholungsabschnitte.
- Hindernisse und Zombies reagieren bei tatsächlicher Chassis-Überlappung. Die Luftlage schließt Treffer nicht pauschal aus. Leichte Barrieren kosten bei 18 m/s etwa 4 km/h; ein schweres Wrack kostet etwa 14 km/h. Reifen mindern Tempoverlust, Panzerung mindert Schaden.
- Godot-Eingabetest mit W/S/Leertaste/A/D: 8,74 m/s nach 2 s Beschleunigen; 7,97 m/s nach 0,7 s Ausrollen; 4,28 m/s nach 0,8 s Bremsen; 22,76 m/s Boost-Spitze. Die Strecke wurde in 45,47 s mit sechs tatsächlichen Treffern und einer Landung abgeschlossen; die Sprungneigung wurde während des Tests ausgeglichen.
- Die visuelle Prüfung bestätigte ein getrenntes HUD ohne Textüberlappung, die längere Kombi-Silhouette und das kleine Nitro am hinteren Türbereich. Der stabile manuelle Tastendruck wurde in der Desktop-Steuerung nicht durchgehend gefahren; der vollständige Ablauf wurde über reproduzierbare Godot-Tastenereignisse geprüft.
- Direktstart: `tools/PC-Teststarts/Start_Fahrtest_PC.bat`. `T` schaltet im Test zwischen Serien- und Tuningprofil um; `R` setzt die Testfahrt zurück. Das Testprofil verändert weder Speicherstand noch gekaufte Upgrades.
- Dieser Abschnitt ist eine Physik- und Begegnungsvorschau, noch keine grafisch ausgearbeitete Amsterdam-Strecke. Android-APK, weitere Welten und Werkstattarbeit bleiben zurückgestellt.
