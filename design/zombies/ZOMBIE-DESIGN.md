# Zombiearten – fünf Schwierigkeitsstufen

Status: Im ersten Zwei-Welten-Abschnitt umgesetzt ist die normale Regenmantel-Variante. Sie nutzt für den Lauf und fürs Festhalten jeweils eine eigene vierteilige Animationsgrafik; die übrigen Varianten/Profile bleiben für spätere Streckengestaltung vorgemerkt. Die ursprünglichen Konzeptbilder zeigen Standbilder und sind nicht selbst Animationsframes.

## Aktueller Spielabschnitt

- Amsterdam enthält eine einzelne normale Begegnung, Rotterdam eine Gruppe aus drei normalen Zombies. Andere Strecken erhalten in diesem Schritt keine neuen Begegnungen oder Art-Entwürfe.
- Der Laufzyklus wechselt vier klar unterscheidbare Posen mit bewegten Armen und Beinen. Ein Visual-Gallery-Lauf rendert die echte Streckenzeichnung in `build/zombie_run_visual_review_0.5.44.png`.
- Beim Festhalten greifen beide Hände um die Dachkante. Vier Hängeposen bewegen Beine und Mantel, während der Griffpunkt oben stabil bleibt. Vorschau: `build/pc_preview_zombie_latched_kombi.png` und `build/pc_preview_zombie_latched_kombi_motion.png`.
- Stärke, Geschwindigkeit, Griffdauer, zusätzlicher Kraftstoffverbrauch und laufender Schaden kommen aus den vorhandenen Zombie-Profilen und der Fahrzeugphysik; die Bildanimation erzeugt keine separaten Physikkörper.

## Arten und Spielrollen
| Stufe | Art / ID | Erkennung | Verhalten | Antwort des Spielers |
| --- | --- | --- | --- | --- |
| 1 | Schlurfer / shambler | Dünn, gebückt, Zivilkleidung | Langsames Zulaufen, geringe Widerstandskraft, häufiger Grundgegner | Mit Schwung durchfahren |
| 2 | Renner / runner | Schlank, vorgeneigt, rote Kleidungsakzente | Schneller Ansatz, kann sich bei langsamer Fahrt festklammern | Tempo halten; Fenstergitter begrenzen passende Anheftungsfolgen |
| 3 | Arbeiter / worker | Breite Schultern, gelbe Arbeitskleidung, schwere Stiefel | Langsam und schwer, höherer Widerstand beim Fronttreffer | Rammbock und ausreichend Anfahrtsweg |
| 4 | Gepanzerter / armored | Dunkelblaue Schutzwesten, Helm/Visier, Metallteile | Mittleres Tempo, sichtbare Schutzteile müssen beim Treffer nachgeben | Verstärkter Rammbock oder Sprungroute |
| 5 | Brecher / breaker | Sehr breit, höchstens etwa 1,4× normale Höhe, dunkle Platten | Seltener starker Gegner, früh sichtbar; keine plötzlichen unvermeidbaren Blockaden | Anlauf und schwere Frontpanzerung oder klar sichtbare Umfahrung |

Die Schutzwirkungen sind Designziele, keine bereits vorhandenen Features. Vor Anzeige im Spiel tatsächlich implementieren und prüfen. Kategorien sind keine reine Zahlensteigerung: Tempo, Gewicht, Panzerung und Anheften getrennt abstimmen. Brecher nicht schneller als Renner machen. Keine automatische Niederlage, wenn ein Teil fehlt; Alternativen und ausreichende Vorwarnzeit einplanen.

## Progression
Früh hauptsächlich Schlurfer, danach Renner in kleinen Gruppen hinzufügen. Arbeiter zunächst einzeln mit Anlaufstrecke zeigen. Gepanzerte und Brecher erst nach erreichbaren Schutzkäufen einführen. Schwächere Gegner bleiben in späteren Abschnitten erhalten. Keine fünf gleichförmigen Horden mit nur anderen Lebenspunkten bauen. Kampagnenfreischaltungen erst nach Spieltest festlegen, nicht blind an feste Weltennummern koppeln.

## Anschluss an das vorhandene Projekt
Im aktuellen scripts/terrain.gd bestehen Klassen slow, fast und robust. Zuerst slow ↔ shambler, fast ↔ runner und robust ↔ worker sauber zuordnen, vorhandene Spawn-Daten kompatibel halten. armored und breaker gezielt erweitern. Keine zweite unverbundene Gegnerlogik einführen. Schaden, Widerstand, Anheften, Belohnung und Grafik aus einem gemeinsamen Datensatz beziehen.

## Grafische Umsetzung
- Zombies schauen im Normalfall nach links zum von links kommenden Auto.
- Alle Figuren auf gemeinsamer Bodenlinie; ähnliche Größe bei Stufen 1/2/4, Arbeiter breiter, Brecher kontrolliert größer.
- Gut lesbare Konturen bei ungefähr 60–90 Bildschirm-Pixeln Höhe prüfen; Kleidung allein genügt nicht, Silhouette unterscheidet Arten.
- Zustände: warten, gehen/laufen, Treffer, fortgeschleudert, liegen; bei Rennern optional anheften/lösen. Keine Platzhalterpose als vollständige Animation behandeln.
- Transparente Sprites, konsistenter Maßstab und Drehpunkte. Hitboxen passend zu tatsächlich sichtbarer Figur; Treffer sowohl horizontal als auch vertikal prüfen.
- Bei schwereren Gegnern Trefferreaktion und abfallende Schutzteile zeigen, ohne explizite Gore-Darstellung zu benötigen.
- Wiederholte Schadensticks und mehrfach vergebene Belohnungen pro besiegtem Gegner verhindern.

## Empfohlener erster Umsetzungsschritt
Zunächst nur Schlurfer und Renner mit je einer Variante in einem kurzen PC-Testabschnitt umsetzen. Originalvorlagen als Designreferenz verwenden; Animation und Hitboxen getrennt erstellen. Unterschied in Bewegung und Frontkontakt prüfen. Vor weiteren Arten Nutzerfeedback einholen. Keine Store-Arbeiten oder Kampagnenerweiterung nebenbei.
