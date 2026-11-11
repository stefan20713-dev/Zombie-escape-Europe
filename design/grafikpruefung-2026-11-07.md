# Grafikprüfung – 7. November 2026

Geprüft wurde der aktuelle spielbare Stand: Amsterdam mit 1.800 m, Hauptmenü, Werkstatt, Karte, Einstellungen, drei Fahrzeuge und Schadensdarstellung. Weitere Städte sind nicht als fertige Spielinhalte vorhanden.

## Umgesetzt
- Neuer gezeichneter Pflasterbelag. Der bisher verdeckende breite Rand wurde reduziert; Steine bleiben auf gerader Straße, Hängen und Rampen sichtbar. UV-Koordinaten folgen der Oberflächentiefe statt der absoluten Höhe.
- Holzrampen verwenden wiederholbare Holzmaserung mit konstantem Maßstab statt einer gestreckten Fläche. Plankenanzahl richtet sich nach Rampenlänge.
- Natürliche Seitenverhältnisse und passende verkleinerte Texturstufen für 30 verwendete Grafiken. Keine hochskalierte Neuzeichnung sämtlicher alter Quellen.
- Neue Mauerdekoration: Rettungsringe, Efeu, Wandlaternen, Entfernungsschilder und dezente Feuchtigkeitsspuren. Keine zusätzlichen Hindernisse auf der Fahrbahn.
- Kleine vertäute Boote mit Wasserreflexen, Wasserbewegung und Vögel. Bootspositionen sind an die sichtbare Wasserfläche gebunden.
- Gezeichnete Hafenkräne ersetzen einfache Linienformen. Füße stehen auf kleinen Wasserstegen hinter der Fahrbahn.
- Dezente warme Lichtreflexe und Staubpartikel in der Werkstatt.
- Lieferwagen und Pickup: Karosserieproportionen korrigiert, Radkästen zu bestehenden Achsen ausgerichtet und Platzhalterräder durch gezeichnete Reifen ersetzt. Einfache Metallanbauten erhielten Kanten, Schatten und Nieten.
- Waffenbild in der Werkstatt passend zugeschnitten und lesbarer dargestellt.
- Karte mit Amsterdam-Panorama und den tatsächlichen Stationen Start, Brückensprung, Lastkahn, Schleusenbrücke und Ziel.
- Keine Änderungen an persönlichen Spielständen, Upgradepreisen, Fahrkräften oder Sprungabständen.

## Gemessene Maße
Weltpixel beziehen sich auf den vorhandenen Spielmaßstab, nicht auf Bildschirmauflösung.

| Element | Maß in Weltpixeln |
| --- | --- |
| Pflasterwiederholung | 216 × 72 |
| Holzwiederholung | 270 × 90 |
| Rettungsring | 28 breit |
| Efeu | 42 breit |
| Wandlaterne | 20 breit |
| Boot | 100 breit, Höhe proportional |
| Hafenkran | 170 hoch, etwa 143 breit |
| Lieferwagenkarosserie | 189 × 94,5 |
| Pickupkarosserie | 184 × 92 |

Transparente Objektgrenzen wurden vor dem Einbau vermessen; unsichtbare Bildränder bestimmen nicht mehr ihre Platzierung.

## Tatsächlich ausgeführte Prüfungen
- 31 sichtbare Prüfansichten, einschließlich 20 Positionen über die gesamte Strecke, Menü, Werkstatt, Karte, Einstellungen, alle drei Fahrzeuge und Schäden. Formate 1280 × 720 und 1600 × 720.
- Komplette Fahrt mit echten Tastatureingaben über 1.800 m bis zum Ergebnisbildschirm: bestanden, etwa 77,7 s. Screenshotaufzeichnung aktiv. Median 53 FPS, Minimum 38 FPS. Stabile 60 FPS sind noch offen; dies ist keine Android-Leistungsabnahme.
- Upgradeprüfung: 96 Einträge über drei Fahrzeuge bestanden; angezeigte und tatsächliche Werte stimmen überein.
- Zombieprüfung: fünf Typen, Vorwärtsklettern, Ablösen und Zurücksetzen bestanden.
- Schleusenbrücke: langsamer Sprung endet im Wasser, 135-km/h-Fall erreicht die Landung; Game-over und Neustart bestanden.
- Abschließende Bildserie nach den letzten rein optischen Anpassungen erneut erstellt. Vollfahrt erfolgte vor den letzten kosmetischen Änderungen an Kran, Karte und Nebenfahrzeugen.

Prüfbilder: `build/visual-audit-after/`, Übersicht `build/visual-audit-after/streckenuebersicht.png`. Fahrbilder: `build/visual-drive-*.png`. Wiederverwendbare Prüfer: `tools/visual_consistency_probe.gd` und `tools/visual_drive_probe.gd`.

## Neue Grafiken und Erzeugung
Mit dem eingebauten Bildgenerator erstellt, anschließend im Projekt gespeichert. Stilreferenz: `assets/amsterdam_lock_landing.png`. Nachfolgend die wiederverwendbaren finalen Prompts.

### assets/amsterdam_street_setts_v2.png
A seamless repeating texture of tightly laid small worn grey granite cobblestones for an Amsterdam street. Entire canvas filled edge to edge, orthographic top view, eight staggered rows and approximately twenty-two columns of small rounded rectangular setts, dark narrow mortar joints, subtle warm grey and blue grey variation, small chips, fine hand-inked outlines and painted material detail. Consistent stone sizes, no large boulders, no perspective, no shadows from outside objects, no plants or objects. Horizontally seamless, also vertically seamless. Wide 3:1 texture tile. Illustrated game style matching the reference materials.

### assets/amsterdam_timber_material_v2.png
A seamless repeating texture of weathered golden-brown heavy timber planks for Amsterdam wooden ramps and barge decks. Entire canvas filled edge to edge with six horizontal parallel narrow planks, dark seams, fine grain, knots, rubbed edges and a few small recessed iron nail heads. Orthographic texture view, consistent plank sizes, no scene perspective, no outer frame, no objects, no large bolts, no black background. Warm illustrated hand-painted game materials with clean dark inked details. Wide 3:1 seamless material tile, both horizontal and vertical edges tile smoothly.

### assets/amsterdam_quay_details_v2.png
Initial design: A production 2D game decoration atlas, strict 2 by 2 grid with exactly four isolated objects, one complete object centered in each cell and wide transparent gutters. TOP LEFT: a weathered orange lifebuoy with cream bands and a loop of rope, seen straight-on mounted on an invisible canal wall. TOP RIGHT: a lush trailing clump of ivy with varied small green and golden leaves, hanging downward from an invisible wall. BOTTOM LEFT: a small old black wrought-iron Amsterdam wall lantern on its short mounting bracket, glowing warm amber, straight-on side elevation. BOTTOM RIGHT: a battered wooden rowboat in exact side elevation, shallow curved dark wood hull, low interior rim, two visible seats, small coiled rope at bow, no water, no people. No ground or shadows, no wall, no background. Transparent alpha background. Consistent hand-painted detailed dark-inked European 2D game style matching reference. No words, no labels, no extraneous objects.

Final edit: Create a clean transparent production game sprite atlas from these four object designs. Remove ALL of the background, glow clouds and cast shadows, including the background visible inside the lifebuoy center and between ivy leaves. Keep ONLY the four sharp-edged objects. Arrange them into a strict 2x2 grid of equal cells: lifebuoy top left, ivy top right, lantern bottom left, boat bottom right. Each entire object must fit completely inside its own cell with at least 10 percent transparent gutters around it; reduce the boat to fit wholly inside the bottom-right cell. No object can cross a cell boundary. Preserve each object's natural proportions, fine ink outlines and painterly colors. Truly fully transparent alpha background everywhere else. No white, grey, brown or black backdrop. No shadows or glows outside objects. No labels.

### assets/amsterdam_dock_crane_v2.png
Create one isolated small antique Amsterdam dock loading crane as a production 2D game scenery sprite. Exact flat side elevation. A compact weathered riveted dark iron vertical tower with braced triangular frame on a low wooden dock pedestal, short angled jib pointing right, visible pulley, hanging cable and single iron hook, a hand-operated winding wheel near its base. All parts complete, no cropping, proportions about 1.1 wide to 1 tall. Hand-painted warm rusty iron, worn timber, dark ink outlines and material detail matching the reference. No dock, no water, no buildings, no ground, no scene. Truly transparent alpha background, no background glows or shadows. One crane only, generous transparent margin.

## Vorschläge für den nächsten spielbaren Meilenstein
Noch nicht umgesetzt: Zombiegruppen gezielt hinter Landungen; angekündigte schwingende Kranlasten; bewusste Abschüttelmanöver durch Bremsen und Beschleunigen; riskante befahrbare Nebenroute über zwei Lastkähne; kurze Fahrtaufgaben mit Kombobelohnungen. Zuerst eine solche Begegnung ausarbeiten und testen, statt alle zugleich einzubauen.
