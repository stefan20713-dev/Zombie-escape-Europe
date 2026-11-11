# Grafikpolitur: Werkstatt und Amsterdam – 8. November 2026

## Sicherung vor der ersten Änderung
- Archiv: `Sicherungen/Zombie_Escape_Europe_Vor_Grafik_2026-11-08_17-21-02.zip`
- 5.492 Dateien, 2.906.179.610 Bytes Archivgröße. Alle Einträge nach Erstellung erneut gelesen und mit SHA-256 gegen die Originaldateien geprüft.
- Prüfprotokoll: gleichnamige Datei mit Endung `.zip.json`. Vorhandene ältere Sicherung bleibt erhalten.
- Nicht eingepackt: der Sicherungsordner selbst, der regenerierbare Godot-Importcache, lokale Testprofile und alte `build/backups`. Spielstände außerhalb des Projektordners sind nicht Bestandteil des Archivs; diese Arbeit verändert sie nicht. Portable Werkzeuge, Projektquellen, Grafiken und vorhandene Android-/Signierungsdateien sind Bestandteil der Sicherung.

## Umgesetzt

### Reiseplakat
- Illustrierte Papierkarte als eigenes Bild, ohne eingebrannte Texte oder Fortschrittsdaten.
- Route, aktuelle Stadt und Abschlussmarkierungen werden aus Kennungen und vorhandenem Spielstand darüber gezeichnet. Darstellung bleibt im Seitenverhältnis der Grafik.
- Plakat an der tatsächlichen Wandposition anklickbar und per Touch erreichbar. Vergrößerter Reiseplan mit den vereinbarten 20 Städten und Rückkehr zur Werkstatt oder vorhandenen Streckenkarte.
- Die geplante Reise ist eine eigene Anzeige, kein Freischalten unfertiger Level. Amsterdam bleibt die einzige spielbare Stadt.
- Die Reisezeichnung ist eine stilisierte Spielkarte, keine Navigationskarte.

### Werkstatt und Teile
- Sechs neu generierte, transparente Teileillustrationen: Motorblock, Reifen mit Profil, Benzinkanister, vernietete Panzerplatte, einzelner blauer Nitrotank im Rahmen und Fahrzeugwaffe.
- Quelle der UI-Grafiken: `assets/ui/workshop/engine_v1.png`, `tires_v1.png`, `tank_v1.png`, `armor_v1.png`, `nitro_v1.png`, `weapon_v1.png`.
- Originalgrafiken hochauflösend erhalten; mobile Imports auf 512 Pixel begrenzt und Mipmaps eingeschaltet. Alle sechs geladenen UI-Texturen und ihre transparenten Ecken geprüft.
- Größere Teileillustration im Kaufpanel, klare Felder MONTIERT/NÄCHSTER AUSBAU, echte Stufen und vorhandene Spielwerte. Für Reifen wird die tatsächlich nächste montierbare Reifengrafik groß gezeigt; andere große Bilder sind ausdrücklich als Teilekategorie gekennzeichnet.
- Nutzen umgebrochen statt über Grafiken hinausgeschrieben. Kurzer weicher Wechsel der Teileillustration und Einbau-Bestätigung nach erfolgreichem Kauf; vorhandener Kaufklang bleibt erhalten.
- Gesperrt, zu wenig Geld und Maximum verwenden die vorhandene Kaufentscheidung. Montage und Daten der übrigen Kategorien bleiben unabhängig.
- Nitro-Anzeigefehler korrigiert: tatsächlicher Vorrat 120/140/160 statt bisheriger Vorschau 100/120/140. Das Fahrzeugverhalten wurde nicht geändert. Prozentanzeige des nächsten Schubgewinns wird aus den vorhandenen Kraftwerten berechnet.
- Veraltete Behauptung über die Anzahl nötiger Waffentreffer aus dem Kauftext entfernt.

### Vordergrund, Licht und Bodenkontakt
- Hafen-Holzsperren verwenden nun dieselbe detaillierte Illustration wie die übrigen Holzsperren; auf ihre vorhandene Höhe von 66 Pixeln abgestimmt. Kollision und Streckenpositionen bleiben erhalten.
- Bewegte Holzsplitter tragen die vorhandene Holzmaterial-Textur; Flug, Treffer und Lebensdauer entstehen weiterhin aus dem echten Durchbruch.
- Dezente gemeinsame Fahrzeug-Lichtführung: wärmeres Oberlicht in der Werkstatt, kühleres Umgebungslicht draußen. Keine Änderungen an Karosserieform, Radstand oder gewählten Ausbauteilen.
- Zusätzliche enge Reifenkontaktschatten in der Werkstatt und auf der Straße. Straßenschatten richten sich nach echten Federungskontakten und dem Straßenprofil; keine künstlichen Bodenschatten über offenen Wasserlücken.
- Zombie-Ablösung während des Hochziehens übernimmt jetzt die sichtbare Kletterpose und deren Kontaktgrenzen, statt beim Fallen plötzlich zur Hängepose zu wechseln.

## Ausgeführte Prüfungen
- `graphics_polish_review.gd`: echte Maus- und Touch-Ereignisse, Plakat öffnen/schließen, kein Durchklicken auf darunterliegende Kaufbuttons, sechs Kategorien, Kauf mit genau einmaligem Preisabzug, andere Kategorien unverändert, Maximum ohne weiteren Abzug, Abschlussmarkierung und Zurück-Bedienung.
- Werkstatt bei 1280 × 720 und 1920 × 864 gerendert und angesehen, einschließlich normaler, gesperrter, gekaufter und maximaler Zustände.
- `upgrade_preview_test.gd`: 96 Vorschauen für drei registrierte Fahrzeuge; Nitro-Anzeige zusätzlich gegen tatsächlich konfigurierte Fahrzeugkapazität verglichen.
- `zombie_grip_behavior_test`, `zombie_forward_climb_test`, `amsterdam_combat_pass_test`, `wheel_ground_contact_test`, `amsterdam_lock_upgrade_target_test`: bestanden. Zombie-Galerie einschließlich Ablösung mitten im Hochklettern neu gerendert und kontrolliert.
- Gemeinsame Lichtführung an Kombi, Lieferwagen und Offroad-Pickup in der Werkstatt gerendert; keine weitere Fahrzeugfreischaltung oder Kampagnenänderung.
- Komplette 1.800-m-Fahrt mit echten Tastatureingaben: Motor II, Nitro I, Reifen II, Tank III, Panzerung II, Fahrwerk I, Waffe I. Ziel nach 68,67 Simulationssekunden erreicht; Resttank 34,89, Restzustand 66,90.
- Lokale FPS-Stichproben dieser PC-Fahrt: Median 81, Minimum 51. Das ist kein Nachweis für durchgehend 60 FPS oder ein echtes Android-Telefon.
- Alle Prüfungen mit separaten APPDATA-Verzeichnissen unter `.local_probe`. Persönliche Spielstände wurden nicht zurückgesetzt.
- Finale Protokolle: `.local_probe/graphics-ui-final-clean.log`, `graphics-upgrade-final-clean.log`, `graphics-full-drive.log`, `graphics-grips-final.log`, `graphics-vehicles-final.log`.

## Offen und Start
- Die Änderungen sind ein überprüfbarer Grafikschritt im vorhandenen Amsterdam. Die spätere Kampagne und offene Fahrzeug-/Panzerungsentwürfe wurden nicht eigenmächtig ausgearbeitet.
- Prüfung auf echtem Android-Telefon und endgültige Nutzerabnahme stehen aus.
- Laufende alte Vorschau schließen und `Start_Zombie_Escape_Europe_PC_Preview.bat` neu starten.

## Grafikerstellung
Built-in-Bildwerkzeug verwendet. Die sechs Icon-Originale und die Kartenillustration wurden in den Projektordner kopiert. Originaldateien werden nicht beim Programmstart nachgeladen oder aus einem Benutzer-Cache benötigt.

### Exakte Icon-Prompts

#### engine
Production inventory icon for a hand-painted 2D European zombie driving game. One isolated real mechanical object, chunky readable silhouette, rich illustrated material detail, clear dark ink contours, worn but functional, warm upper-left light and restrained cool shadow, three-quarter view. Painted game asset rather than flat vector symbol, no circular badge, no UI frame. Entire object centered, fills 78 percent of square canvas, 12 percent transparent margin all sides. TRUE RGBA transparent background, alpha zero everywhere outside object, no ground, no cast shadow, NO glow, NO haze, no text or lettering, no logo. Consistent premium mobile game illustration style, clear at small sizes. Subject: A complete recognizable cast-iron automobile ENGINE BLOCK with orange valve cover, four cylinder exhaust manifold, silver machined edges, cooling fins, dark pulley, small bolts, slightly oily used metal. Not a car, not a gear wheel.

#### tank
Production inventory icon for a hand-painted 2D European zombie driving game. One isolated real mechanical object, chunky readable silhouette, rich illustrated material detail, clear dark ink contours, worn but functional, warm upper-left light and restrained cool shadow, three-quarter view. Painted game asset rather than flat vector symbol, no circular badge, no UI frame. Entire object centered, fills 78 percent of square canvas, 12 percent transparent margin all sides. TRUE RGBA transparent background, alpha zero everywhere outside object, no ground, no cast shadow, NO glow, NO haze, no text or lettering, no logo. Consistent premium mobile game illustration style, clear at small sizes. Subject: A single olive-green metal gasoline JERRY CAN, distinctive rectangular can with three-handle bridge on top, capped angled pouring spout, X-shaped pressed reinforcement, scuffed paint revealing steel, orange-brown cap and small fuel-drop emblem without letters.

#### tires
Production inventory icon for a hand-painted 2D European zombie driving game. One isolated real mechanical object, chunky readable silhouette, rich illustrated material detail, clear dark ink contours, worn but functional, warm upper-left light and restrained cool shadow, three-quarter view. Painted game asset rather than flat vector symbol, no circular badge, no UI frame. Entire object centered, fills 78 percent of square canvas, 12 percent transparent margin all sides. TRUE RGBA transparent background, alpha zero everywhere outside object, no ground, no cast shadow, NO glow, NO haze, no text or lettering, no logo. Consistent premium mobile game illustration style, clear at small sizes. Subject: A single automobile tire with strong chunky road/all-terrain tread and silver five-spoke wheel hub, rubber texture and a few scratches, orange central hub nut. Wheel stands upright angled slightly right; no detached parts.

#### armor
Production inventory icon for a hand-painted 2D European zombie driving game. One isolated real mechanical object, chunky readable silhouette, rich illustrated material detail, clear dark ink contours, worn but functional, warm upper-left light and restrained cool shadow, three-quarter view. Painted game asset rather than flat vector symbol, no circular badge, no UI frame. Entire object centered, fills 78 percent of square canvas, 12 percent transparent margin all sides. TRUE RGBA transparent background, alpha zero everywhere outside object, no ground, no cast shadow, NO glow, NO haze, no text or lettering, no logo. Consistent premium mobile game illustration style, clear at small sizes. Subject: One thick blue-grey vehicle armor plate, broad trapezoid, orange-brown corner brackets, four visible steel rivets, beveled metal edges, scratches and small dents. Recognizable as car armor, not medieval shield or body armor.

#### nitro
Production inventory icon for a hand-painted 2D European zombie driving game. One isolated real mechanical object, chunky readable silhouette, rich illustrated material detail, clear dark ink contours, worn but functional, warm upper-left light and restrained cool shadow, three-quarter view. Painted game asset rather than flat vector symbol, no circular badge, no UI frame. Entire object centered, fills 78 percent of square canvas, 12 percent transparent margin all sides. TRUE RGBA transparent background, alpha zero everywhere outside object, no ground, no cast shadow, NO glow, NO haze, no text or lettering, no logo. Consistent premium mobile game illustration style, clear at small sizes. Subject: A single large cobalt-blue nitrous pressure tank held in a compact dark metal rectangular mounting frame, two orange securing bands, silver regulator valve and short black hose. Exactly ONE blue tank, no extra bottles, no lettering.

#### weapon
Production inventory icon for a hand-painted 2D European zombie driving game. One isolated real mechanical object, chunky readable silhouette, rich illustrated material detail, clear dark ink contours, worn but functional, warm upper-left light and restrained cool shadow, three-quarter view. Painted game asset rather than flat vector symbol, no circular badge, no UI frame. Entire object centered, fills 78 percent of square canvas, 12 percent transparent margin all sides. TRUE RGBA transparent background, alpha zero everywhere outside object, no ground, no cast shadow, NO glow, NO haze, no text or lettering, no logo. Consistent premium mobile game illustration style, clear at small sizes. Subject: A compact rugged improvised vehicle-mounted automatic gun, short dark steel barrel facing right, silver receiver, orange mounting bracket and small mechanical swivel pedestal. No human, no hands, no car, no ammunition text. Short compact silhouette sized like a car rooftop accessory.

### Exakter Karten-Prompt
Create a premium hand-painted vintage PAPER MAP illustration for a wall poster in a European post-apocalyptic driving game. Portrait 3:4 composition, complete rectangular weathered cream parchment sheet, tiny worn edges, warm ink, faint fold creases and pencil grid, rich but restrained illustration. Accurate recognisable western European coastline: Netherlands and Belgium top right, France in middle, Spain and Portugal below, tiny Strait of Gibraltar near bottom. Geographic map bounds roughly longitude -10 west to +8 east, latitude 54 north at top to 35 north at bottom; keep a 10 percent paper margin around the map. North up, natural geographic proportions, Atlantic muted blue-grey left, land desaturated olive and sand. Fine engraved coastline, simple internal country borders, subtle mountains in Pyrenees and central Spain, a small compass rose bottom left. Hand-drawn dark contours and painterly texture matching a detailed illustrated 2D zombie road game, warm upper-left lighting. NO LABELS, NO LETTERS, NO TEXT, NO CITY NAMES, NO PINS, NO ROUTE LINES, NO DOTS: all labels and progress will be drawn dynamically in the game. No people, vehicles, modern screens, badges or surrounding room. Entire parchment poster only. Opaque parchment background. Beautiful readable geographic silhouette rather than an abstract polygon.

Kartendatei: `assets/ui/workshop/journey_map_v1.png`, Import auf 1024 Pixel mit Mipmaps.


## Aktueller Vollfahrtnachweis
Die oben protokollierte ältere Vollfahrt mit Waffe I ist kein Nachweis eines regulär erreichbaren Motor-II-Profils. Der spätere echte Spielerweg hat ohne zusätzliche Testmünzen Motor II, Nitro I, Reifen II, Tank III und Panzerung III gekauft und die ganze Strecke ohne Waffe in 85,58 Sekunden geschafft. Aktueller Gesamtbericht: design/pc-meilenstein-abnahme-2026-11-08.md; Protokoll: .local_probe/earned-drive-final.log.
