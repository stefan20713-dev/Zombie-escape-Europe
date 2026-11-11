# Schleusenbrücke bei 1.280 m – überarbeitete Maße und Darstellung

Stand 7. November 2026. Die Absprungkante liegt bei angezeigten 1.280 m, entsprechend Weltmeter 1.287. Die Anfahrt beginnt bei angezeigten 1.235 m. Der eigentliche, proportional gezeichnete Holzflügel ist 14 m lang. Die Sprunglücke beträgt jetzt 32,16 m, danach folgen 14 m Landebrücke mit durchgehender Mauer darunter. Der linke Mauerblock endet am Toranfang, der rechte beginnt am Torende. Es fehlen keine freischwebenden Zwischenstücke mehr.

## Geometrie und Flugbahn

135 km/h sind 37,5 m/s. Der vorhandene Maßstab beträgt 36 px/m. Schwerkraft 350 px/s² und Fahrzeugfaktor 0,88 ergeben 308 px/s². Die Plattform liegt jetzt 100 Pixel tiefer als die Absprungkante. Die größere Höhendifferenz und längere Schleuse machen einen zu kurzen Sprung sichtbar nachvollziehbar.

Flugzeit bis zur Plattformhöhe: sqrt(2 * 100 / 308) = ungefähr 0,8058 s.

Abstand: 37,5 * 0,8058 + 70 / 36 = 32,1628 m, umgesetzt als 32,16 m. Der letzte Term berücksichtigt die Vorderradposition des Kombis.

Alle Geschwindigkeiten verwenden dieselbe Schwerkraft und denselben geometrischen Kontakt an der Landekante. Ein Fehlversuch erhält keinen zusätzlichen Abwärtsimpuls. Er setzt die berechnete Fallbewegung fort und stößt an die sichtbare Stirnseite des rechten Mauerblocks. Er wird weder auf die Plattform angehoben noch unter ihr bis zur hinteren Mauer durchgeschoben. Die Kamera folgt beim Scheitern dem Wassersturz. Nach Spritzern und Untergehen erscheint Game Over mit Neustart/Werkstatt.

## Eingebundene Grafiken

Mit dem integrierten Bildgenerator anhand der Nutzerreferenz erstellt, transparente Einzelbauteile:

- assets/amsterdam_lock_drawbridge.png
- assets/amsterdam_lock_landing.png
- assets/amsterdam_lock_gate.png

Die bestehenden Bauteile werden ausschließlich gleichmäßig skaliert und gedreht, ohne Scherung oder Verbiegen. Nur die letzten 14 m der Auffahrt sind ein Holzflügel; davor liegt die normale steinerne Anfahrt. Mauern reichen links bis zur Absprungkante und rechts ab der Landekante durchgehend unter die Brücken. Das Tor füllt die physische Öffnung. Seine transparenten Außenränder sind gemessen beschnitten; nur untergetauchte Bildteile werden an der Wasserlinie abgeschnitten. Die vorhandenen Wasserreflexionen bleiben sichtbar; kein deckender Wasserblock übermalt den Hintergrund. Der alte Hafenkran im Sprungbereich wurde aus dieser Stelle ausgeschlossen.

Gemeinsamer Promptzusatz: Use the attached image only as STYLE and MATERIAL reference. Generate a separate production game sprite: [PART]. Match the hand-painted illustrated dark ink outlines, aged timber, rusty iron details and warm stone-city lighting of the reference. This is a clean isolated game asset with truly transparent alpha background, not a complete illustration. No text.

PART, Brückenflügel: A single raised LEFT-HAND drawbridge leaf seen in exact flat 2D side elevation, rising gently from lower LEFT hinge to a broken upper RIGHT tip at 12 degrees above horizontal. Long weathered golden timber road deck with visibly splintered end, riveted black steel triangular girder underside, large circular pivot at the left end, cast iron black safety railing along its upper back edge. Keep the road contact surface a straight line. No stone quays, no car, no background, no water. Whole isolated bridge leaf with all railings and hinge fully visible and generous transparent margins.

PART, Landefläche: A single RIGHT-HAND landing platform for a canal drawbridge in exact flat 2D side elevation. Flat horizontal weathered golden timber road deck, open left landing edge, black iron safety railing behind deck, metal corner straps and rivets, two heavy wooden trestle supports and diagonal beams below. Full piece visible. No stone quays, no car, no background, no water. Generous transparent margins.

PART, Schleusentor: A closed pair of old Amsterdam canal lock gates seen straight-on in a detailed 2D game side-view setting. Heavy weathered vertical dark timber planks reinforced by riveted black iron straps and diagonal steel braces, rusty ochre machinery and a large handwheel near upper center, a black iron railing across the top. Wide horizontal rectangular paired gate, fully visible with transparent margin. No surrounding stonework, no water, no scenery, no car.

## Tatsächlich geprüft

- Reale Anfahrt über die Rampenkollision: rund 120, 130 und 134 km/h scheitern; 135 km/h schafft die Landung, einschließlich verschiedener Eintrittsphasen.
- Automatisierte Prüfung: gleiche Skalierung auf beiden Grafikachsen, keine Scherung; Mauerkanten genau an der Schleusenöffnung; Fehlversuche folgen derselben Schwerkraftkurve ohne Abwärtskorrektur.
- Sichtbare Fahrt mit echten W-/Leertaste-Eingaben: 148,6 km/h am Absprung erfolgreich, 95,4 km/h zu kurz und Game Over. Aufnahmen in build/schleusenbruecke-v2-*.png.
- Weiterfahrt ab Weltmeter 1160 über die veränderte Brücke bis zum 1800-m-Ziel bestanden. Die ersten 1160 m wurden in diesem Arbeitsschritt nicht erneut vollständig gefahren.
- Wasserabschluss und Neustart im reproduzierbaren Test tests/amsterdam_lock_bridge_test.gd bestanden.
- Separate Testprofile; persönliche Spielstände erhalten. Android wurde in diesem Arbeitsschritt nicht geprüft.

## Mauerabschlüsse nach Referenzausschnitt

Die Fundamente unter dem Holzflügel und der Landebrücke sind gezielt abgesenkt. Holzstützen und Metallfußplatten stehen auf sichtbaren Abdecksteinen; das Mauerwerk überdeckt die Stützen nicht mehr. Die Schleusenöffnung hat beidseitig Eckpfeiler mit versetzten Steinlagen, überstehenden Abdeckplatten, seitlicher Schattenfläche, Beschlägen und Bewuchs nahe der Wasserlinie. Die vorhandene Steintextur wird wiederverwendet. Keine neue verzerrte Gesamtgrafik.

PC-Abnahme: echte Anfahrt und Sprung sowie Detailansichten beider Mauerabschlüsse gerendert und angesehen. Nach letzter Höhenkorrektur liegen die Fußplatten direkt auf dem rechten Steinsockel. Vorhandener Sprungtest mit rund 134 km/h Scheitern und 135 km/h Erfolg bestanden. Aufnahmen: build/schleuse-mauer-spiel.png, build/schleuse-mauer-links.png und build/schleuse-mauer-rechts.png.
