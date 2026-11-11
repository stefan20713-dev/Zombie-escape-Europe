# Nitro – drei sichtbare Ausbaustufen

## Umgesetzt in 0.5.44

- Stufe 0: kein Nitro-Bauteil, Boost bleibt wie bisher gesperrt.
- Stufe 1 und 2: derselbe einzelne horizontale blaue Drucktank mit Stahlbändern, Messgerät, Messingventil und Anschlussleitung.
- Stufe 3: zwei blaue Drucktanks mit gemeinsamem Rahmen, Verteilern und Druckmesser.
- Die beiden transparenten Assets sind `assets/kombi_nitro_single_0.5.44.png` und `assets/kombi_nitro_dual_0.5.44.png`. Sie wurden eigens mit Imagegen auf Basis der gelieferten Referenzen erstellt und in der Karosserieebene des Kombis eingebunden.
- Die Nitroanlage liegt auf dem Dachträger und bleibt getrennt von Tankkanistern, Reifen und Panzerung. Die vorhandene Nitro-Kauf-, Vorrats- und Boost-Logik wurde nicht dupliziert.
- Die Boostflamme beginnt an der sichtbaren Auspufföffnung am Heck. Sie erscheint nur, wenn der bestehende Boost tatsächlich aktiv ist.
- Bildvergleich: `build/nitro_visual_review_0.5.44.png`. Godot bestätigte Bildaufbau und Nitro-Werkstattwerte mit `NITRO_VISUAL_GALLERY_OK` und `UPGRADE_PREVIEW_OK`.

## Ursprüngliche Referenznotizen

Die gelieferten Bilder 1 und 2 bestimmen die visuellen Stufen: Bild 1 gilt für Nitro-Stufe 1 und 2; Bild 2 gilt für Stufe 3. Die Flaschenanzahl zeigt die Ausbaustufe, bestimmt aber nicht automatisch die Vorratsprozentzahl. Vorrat, Verbrauch und Schub bleiben an die vorhandenen Fahrzeugdaten gebunden. Nitro ist ein eigenständiges Upgrade außerhalb der Panzerungsstufen.
