> Spätere Nutzerkorrektur vom 8. November: Die großen aufgesetzten Blechdellen wurden entfernt; Schaden nutzt jetzt feine Knicke und die Karosserieverformung. Bodenfreiheit und Kletterkontakt wurden ebenfalls korrigiert. Aktueller Stand: serienkombi-kontakt-schaden-2026-11-08.md.

# Amsterdam – Action- und Schadensausbau, 8. November 2026

## Ziel und umgesetzter Umfang

Die erste Hälfte der bestehenden Amsterdam-Strecke wurde als zusammenhängender Actionabschnitt überarbeitet. Die 1.800-m-Gesamtstrecke, der orange Kombi, die Grachtenkulisse, die vorhandenen Brückensprünge und der Lastkahn bei 820 m bleiben erhalten. Die zuvor entfernte Lastkahn-Nebenroute wurde nicht wieder eingebaut.

Referenzprinzipien: deutliche Höhenwechsel, zerstörbare Begegnungen, sichtbare Fahrzeugzerstörung und nachvollziehbare Gegnerreaktionen. Not Doppler beschreibt diese Grundelemente für Earn to Die 2 in der [offiziellen Veröffentlichung](https://www.notdoppler.com/earntodie2/android-launch-pressrelease.php). Streckengeometrie und neue Bilder sind eigene Arbeiten für dieses Projekt; keine fremden Spielgrafiken wurden übernommen.

## Strecke und Action

- Fünf Kaianstiege deutlich vergrößert: ungefähr bei 190–232 m, 255–299 m, 340–376 m, 671–712 m und 942–997 m angezeigter Strecke. Gemessener stärkster Anstieg im ersten Abschnitt: rund 28,86 Grad. Kollision und sichtbarer Pflasterbelag verwenden dieselbe Höhenfunktion.
- Die Mulde nach dem ersten Brückenabschnitt hat einen längeren, weicheren Auslauf. Der scharfe Gegenanstieg wurde geglättet, damit das Auto dort seinen Schwung besser behalten kann.
- Sechs zusätzliche Zombiegruppen mit normalen Zombies, Arbeitern und Läufern. Leichtere Gegner bleiben zwischen stärkeren Begegnungen erhalten.
- 14 rote Treibstofffässer, meistens als Zweiergruppen. Fasshöhe 47 Weltpixel, Breite proportional rund 27 Weltpixel.
- Die vorhandene Fahrzeugwaffe zündet erreichbare Fässer aus maximal sechs Metern vor der Fahrzeugfront. Beim Rammen entsteht eine kurze Zündverzögerung; das getroffene Fass wird ein Stück mitgeschoben.
- Explosionsradius: 190 Weltpixel, etwa 5,28 m. Benachbarte Fässer können zeitversetzt folgen. Gegner innerhalb des tatsächlichen Radius werden getroffen und über die vorhandene Reaktionsanimation weggeschleudert. Derselbe Gegner und dasselbe Fass werden nicht doppelt belohnt beziehungsweise ausgelöst.
- Holzsperren und Kisten im Explosionsradius können zerbrechen. Zwei Kistenbegegnungen liegen gezielt nahe an Fassgruppen, damit eine rechtzeitig ausgelöste Explosion den Weg freiräumen kann.
- Der Wagen kann nahe am Feuer Schaden nehmen; Entfernung und Panzerung beeinflussen den Schaden. Sprünge schützen nur durch tatsächlichen räumlichen Abstand.
- Eigene gezeichnete Explosion, Metalltrümmer, Aufprallsound mit tieferer Tonlage, kurze begrenzte Kamerabewegung und Fasshinweise. Die Effekte entstehen aus tatsächlichen Zündungen und laufen zeitlich aus.
- Explosionstreffer fließen in die vorhandene Zombiebelohnung und Kombo ein. Keine zweite Währung oder separate Fortschrittsverwaltung.

## Schaden am Kombi

- Originalkarosserie und die bereits montierte Panzerung bleiben Grundlage; Radstand und Fahrzeugproportionen werden durch Schäden nicht neu ausgewählt.
- Blech wird ab mittlerer Beschädigung früher und stärker geknickt. Schwere Schäden öffnen die vordere Haubenpartie; darunter wird ein Motorblock mit Rippen und Leitungen sichtbar.
- Neu generierte unregelmäßige Blechbeulen, Lackabrieb und Glasbruch ersetzen beziehungsweise ergänzen die bisherigen einfachen Schadenslinien. Es gibt keine rechteckigen Schadenskacheln.
- Zusätzliche Kontaktspuren werden nahe am gemeldeten Fahrzeugkontakt angebracht und zahlenmäßig begrenzt.
- Bei zunehmendem Schaden lösen sich kleine Blechteile; bei schwerem Schaden auch eine verformte Haubenpartie. Diese Teile bewegen sich unabhängig in der Welt, drehen sich und blenden aus.
- Metallpanzerung verwendet für die neuen Schadensdetails eine angepasste Metallfärbung. Neue orangefarbene Dellen werden dadurch nicht ungefiltert auf graue Schutzplatten gemalt.
- Glasbruch, Rauch und vorhandene Wrackdarstellung bleiben sichtbar. Bei sehr niedrigem Zustand sinkt die tatsächliche Motorantriebskraft nachvollziehbar: von voller Leistung bei 40 % oder mehr Zustand bis zu 76 % kurz vor vollständiger Zerstörung. Bei Zustand null greift weiterhin das bestehende Fahrtende.
- Ein Hinweis meldet den beschädigten Motor; die Karosserieanzeige zeigt weiterhin den tatsächlichen Gesamtzustand. Upgradepreise, gekaufte Kategorien und persönliche Spielstände werden nicht geändert. Der neue detaillierte Bildsatz gilt zunächst für den Kombi; Lieferwagen und Pickup behalten ihre vorhandene eigene Schadensdarstellung.

## Grafische Einbindung

Neue Bilder wurden vor dem Einbau auf sichtbare Alpha-Grenzen vermessen. Das Fass verwendet den Ausschnitt (139,136), 738 × 1289 Pixel. Die Explosion verwendet (97,73), 1238 × 912 Pixel. Alle neuen Texturen haben verkleinerte Texturstufen. Transparenz an den Bildrändern wurde geprüft.

Ein beim Fahrtest aufgetretener Darstellungsfehler der Wasserunterlage in einer steilen Mulde wurde korrigiert: Sie besteht jetzt aus einzelnen konvexen Flächen und Dreiecken statt einer großen, gelegentlich selbstschneidenden Fläche.

## Neue Bilddateien und Prompts

Erstellt mit dem eingebauten Bildgenerator, anschließend in das Projekt kopiert. Keine API-/CLI-Ausweichlösung.

### assets/amsterdam_explosive_drum_v1.png

Production 2D side-scrolling illustrated game sprite: ONE upright explosive fuel drum, strict flat side elevation with subtly visible top ellipse. Weathered deep red painted steel, two reinforcing ribs, chipped warm cream band and clear black flame hazard pictogram, dark ink outlines, hand painted scratched metal, small dents and dark oily streaks. Readable at 45 pixels tall, matching warm detailed European canal zombie driving game art. Entire barrel isolated with generous margins, no scenery, no floor, no cast shadow, no text, no letters, no other objects. Truly transparent background. Natural steel drum proportions approximately 0.65 width to 1 height.

### assets/kombi_damage_details_v1.png

Stilreferenz: assets/kombi_body_0.5.10.png.

Using the orange estate car ONLY as a material and line-art reference, create a production game damage decal atlas. Exactly four isolated damage details in a strict equal 2 by 2 grid with wide transparent gutters. Top left: irregular crumpled orange painted sheet-metal dent with torn edges, exposed dull silver metal and dark creases, no rectangular outer shape. Top right: long shallow irregular orange paint scrape exposing scratched steel, ragged paint edges, no solid rectangular background. Bottom left: ONLY pale thin spiderweb fracture lines and tiny glass shards, transparent between all lines, no window frame and no colored glass pane. Bottom right: one twisted detached orange bonnet/hood panel with scratched paint, dark underside and broken metal hinge, exact side elevation, no car. Match the reference car's warm orange paint, hand painted texture and dark clean ink contours. These are small overlays and debris for an existing side-view car. Do not draw a complete car, wheels, roof rack, weapon, tank or new accessories. Truly transparent alpha everywhere outside the four isolated objects; no background, no text, no cast shadows. Each object wholly within its own quarter with at least 10 percent margin.

### assets/amsterdam_explosion_v1.png

One isolated compact explosion burst sprite for a hand-painted ink-outlined 2D European zombie driving game. Broad irregular orange and golden fireball with a few distinct dark charcoal smoke lobes around its outer edge, hot pale yellow center, three small sharp metal fragments nearby. Strong readable silhouette, warm painterly texture, crisp dark ink contours, dramatic but not photorealistic. No huge vertical plume, no floor, no buildings, no vehicle, no text. All of the burst fully inside canvas with generous transparent margins. Truly transparent alpha background outside explosion, no rectangular glow or dark backdrop. Landscape composition about 1.3 wide to 1 tall.

## Prüfungen

Neue Prüfungen: räumliche Fass-Kettenreaktion, genau einmalige Gegnerbelohnung, fortschreitende Schadensstufen, abgelöste Teile, Motorzustand, Rücksetzen und gemessene Steigung. Vorhandene Prüfungen: 96 Upgrade-Einträge über drei Fahrzeuge; fünf Zombiearten mit Klettern und Ablösen; unveränderte Schleusenflugbahn; weiterhin durchgehende Straße an der entfernten Nebenroute.

Sichtprüfung: elf Streckenpositionen, eine Explosion und 24 Zustands-/Panzerungs-Kombinationen. Diese Standbilder ergänzen die echte Eingabefahrt; sie ersetzen sie nicht. Die vollständige 1.800-m-Fahrt wurde mit Gas, Balanceeingaben und Nitro vor der Schleusenbrücke gefahren. Persönliche Spielstände wurden dafür nicht verwendet. Abschließende Fahrtwerte und eventuelle Einschränkungen stehen im zugehörigen Prüfprotokoll.

Prüflogik: tests/amsterdam_combat_pass_test.gd. Bildprüfung: tools/amsterdam_combat_gallery.gd. Vollfahrt: tools/visual_drive_probe.gd. Bilder: build/combat-*.png und build/visual-drive-*.png. Logs: .local_probe/combat-*.log.

Keine Prüfung auf einem realen Android-Telefon. Stabile 60 FPS sind weiterhin ein offenes Leistungsziel. Dieser Meilenstein ist für Nutzerfeedback gedacht, bevor weitere Städte oder zusätzliche Großsysteme bearbeitet werden.

## Abschließendes Prüfprotokoll

- Vollständige Tastaturfahrt im endgültigen spielmechanischen Stand: Ziel bei 1.800 m erreicht, 75,83 s, Resttreibstoff 20,89, Zustand 15,60 %. Profil: Motor II, Reifen II, Tank III, Panzerung II, Fahrwerk I, Nitro III und Waffe I. Gas und Balance wurden über echte Eingabeereignisse bedient; Nitro vor der Schleusenbrücke. Kein persönlicher Spielstand wurde verändert.
- Aufgezeichnete PC-Leistung: Median 53 FPS, Minimum 38 FPS. Das ist kein Nachweis stabiler 60 FPS und keine Telefonmessung.
- `combat-drive-verified.log`: komplette Fahrt, keine gemeldeten Darstellungs- oder Skriptfehler.
- `combat-gallery-verified.log`: elf Streckenpositionen, eine Explosion, 24 Zustands-/Panzerungsansichten; keine gemeldeten Fehler. Bilder anschließend visuell kontrolliert.
- `combat-unit-final.log`: Waffe außerhalb der Reichweite zündet nicht; innerhalb der Reichweite zündet sie. Kettenreaktion und Gegnerbelohnung genau einmal, Holzkiste im Radius wird geräumt, Wagen im Radius nimmt Schaden, fortschreitende Schäden und abgelöste Teile, Reparatur setzt Darstellung zurück, maximale Steigung rund 28,86 Grad.
- `combat-upgrades.log`: 96 Upgrade-Einträge über drei Fahrzeuge bestanden.
- `combat-zombies.log`: fünf Zombiearten mit Vorwärtsklettern, Ablösen und Rücksetzen bestanden.
- `combat-lock.log`: langsamer Schleusensprung im Wasser, 135-km/h-Fall erreicht Landung, Game-over und Neustart bestanden.
- `combat-no-side-route.log`: Straße an der entfernten Nebenroute bleibt durchgehend; ursprünglicher 820-m-Kahn und beide Kranlasten bleiben erhalten.

Die Blechteile werden mit eigener Geschwindigkeit, Drehung und Schwerkraft animiert. Die Fahrphysik verwendet weiterhin den bestehenden zentralen Fahrzeugkörper; es wurde kein vollständig aus einzeln kollidierenden Fahrzeugbauteilen aufgebautes System eingeführt.

Start: `Start_Zombie_Escape_Europe_PC_Preview.bat`. Eine laufende alte Vorschau vorher schließen. Der vorhandene Sicherungsstand vom 8. November vor diesem Ausbau wurde nicht überschrieben.

