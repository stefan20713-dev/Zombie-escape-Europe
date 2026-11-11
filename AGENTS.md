# Zombie Escape Europe – Verbindliche Projektanweisung & Action-Leitfaden

Diese Datei beschreibt die vom Nutzer gewünschte Produktrichtung für Arbeiten in diesem Projekt. Neuere ausdrückliche Nutzeranweisungen haben Vorrang. Zuerst den tatsächlichen aktuellen Code und die betroffenen Dateien prüfen.

## Ziel und Priorität
Ein actiongeladenes, hochexplosives und flüssiges 2D-Seitenansicht-Fahrspiel für Android (mit PC-Vorschau). Das Hauptgefühl des Spiels basiert auf **brutaler Zerstörung, hohem Tempo, spektakulären Sprüngen und spürbarem Treffer-Feedback** beim Durchbrechen von Horden und Barrikaden in verwüsteten europäischen Städten. Referenz für Actiondichte, Treffergefühl, Streckenrhythmus und Fortschritt ist *Earn to Die 2*.

Priorität: 
1. **Zerstörung & Treffer-Feedback:** Horden, Barrikaden und Infrastruktur müssen mit gewaltiger Wucht, Trümmern und Explosionen zerbersten.
2. **Kontrollierbares, flüssiges Fahrgefühl:** Hohe Geschwindigkeit, spürbare Masse, griffige Fahrzeugkontrolle in der Luft und am Boden.
3. **Abwechslungsreiche, vertikale Stadt-Level:** Einzigartige europäische Wahrzeichen, zerstörbare Mehrdeck-Routen und dynamische Hindernisse.
4. **Werkstatt & Fortschritt:** Verständliches Upgradesystem mit sofort spürbarer Leistungs- und Optiksteigerung.

---

## Action- & Destruktions-Design (Kern-Gameplay)

### 1. Zerstörbare Umgebungen & Hindernisse
- **Materialklassen:** Hindernisse sind in klare Wucht-Kategorien eingeteilt:
  - *Leicht (Holzkisten, Plastikzäune, kleine Schilder):* Fliegen ohne nennenswerten Tempoverlust spratzelnd in Trümmern auseinander.
  - *Mittel (Ziegelmauern, Autowracks, Absperrgitter):* Benötigen Schwung oder Panzerung/Rammbock; zerspringen in schwerere Brocken mit Staub- und Funken-Effekten.
  - *Schwer (Betonblockaden, Brückenpfeiler, Einsturz-Elemente):* Benötigen maximale Wucht oder Nitro-Einsatz. Lösen teils Kettenreaktionen aus (z.B. einstürzende Gerüste oder explodierende Tankstellen-Schilder).
- **Zerstörungs-Feedback:** Keine starren Tempodeduktionen! Jede Kollision erzeugt physikalische Trümmerteile (Particle-Physics), Wucht-Stopps, Kamera-Shakes (dosiert) und Sound-Layer (Holz splittert, Metall kreischt, Beton krallt).

### 2. Zombie-Horden & Gegnervielfalt
- **Horden-Physik:** Zombies treten in dichten Trauben auf. Das Durchfahren erzeugt Körper-Ragdolls, Blut-/Matsch-Partikel und akustischen Wucht-Impact.
- **Spezial-Typen:**
  - *Renn-Zombie:* Springt aufs Dach oder die Windschutzscheibe (muss abgeschüttelt oder an Decken abgeriffen werden).
  - *Panzer-Zombie:* Erfordert Rammbock oder Nitroschub, um nicht gestoppt zu werden.
  - *Explosiv-Zombie:* Reagiert bei Treffer mit einer Druckwelle, die umstehende Trümmer wegschleudert und dem Wagen einen Extra-Schub (oder Schaden) verleiht.

### 3. Nitro, Boost & Kamera-Dynamik
- **Zerstörungs-Boost:** Das Durchbrechen großer Zerstörungs-Ketten füllt eine kleine Nitro-Leiste auf oder belohnt mit extra Schwung.
- **Dynamic Action Camera:** Bei Höchstgeschwindigkeit oder Sprüngen zoomt die Kamera leicht heraus, um die Flugbahn und Landefläche zu zeigen. Bei heftigen Impact-Momenten (z.B. Durchbrechen eines Betongebäudes) greift ein intelligenter Micro-Zoom mit weichem Shake.

---

## Streckengestaltung & Europäische Stadt-Identität

### 1. Streckenrhythmus (45–60 Sekunden Kern-Loop)
- Jedes Level folgt einer dramaturgischen Action-Kurve: **Anfahren → Horden-Durchbruch → Rampen-Sprung → Alternative High/Low-Route → Einsturz-Passage → Zerstörungs-Finale.**
- **Keine Leerlauf-Zonen:** Keine langen flachen Strecken ohne Hindernisse, Gegner oder Action-Elemente.

### 2. Vertikalität & Alternative Routen
- **Mehrstöckiges Fahren:** Befahrbare Dächer, U-Bahn-Schächte, eingefallene Autobahnbrücken und Baustellen-Gerüste.
- **Risiko vs. Belohnung:** Die obere Route (z.B. Dächer) erfordert präzisen Sprung/Nitro, bietet aber rasantes Tempo und Trümmer-Boni. Die untere Route ist mit dichten Horden und Trümmern versperrt.

### 3. Verwüstete europäische Architektur
- Städte sind durch Kulisse, Wahrzeichen und Bauweise klar erkennbar (z.B. Grachten & historische Backsteinbauten in Amsterdam, historische Viertel, europäische Straßenbeschilderung), aber deutlich postapokalyptisch zerstört.

---

## Werkstatt, Visualisierung & Performance

- **Sichtbares Power-Up-Gefühl:** Jedes Panzerungs- und Motor-Upgrade verändert das Auto optisch und spürbar. Der Rammbock zermalmt Hindernisse effektiver; Nitro verleiht sichtbare Flammen/Partikel-Schweife.
- **Entkoppelte Datenstruktur:** Jedes Fahrzeug und Stadt-Level besitzt eigene Kennungen und Asset-Pakete. Modifikationen an einem Auto verändern keine anderen Autos.
- **Android & Mobil-Performance:** Zerstörungs-Effekte (Partikel, Ragdolls, Trümmer) müssen gepoolt und optimiert sein, um auch auf Mittelklasse-Smartphones konstante Frame-Raten zu garantieren.

---

## Arbeitsweise & Meilensteine
- **Kein eigenmächtiger Komplettumbau:** Erst das Fahrgefühl und das Zerstörungs-Feedback an einem festgelegten Test-Abschnitt (45–60s) zur Abnahme vorlegen.
- **Schrittweise Action-Optimierung:** Zuerst Trefferphysik & Trümmer → dann Streckenelemente & Vertikalität → dann Feinjustierung der Werkstatt-Werte.