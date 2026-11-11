# Laufanimationen der schweren Zombies – 7. November 2026

Mit dem integrierten Bildgenerator erstellt. Ausgangsbilder waren jeweils die bestehenden Figuren in assets/zombie_worker_0.7.0.png, assets/zombie_riot_0.7.0.png und assets/zombie_brute_0.7.0.png.

Neue, im Spiel verwendete Dateien:
- assets/zombie_worker_walk_4frames.png
- assets/zombie_riot_walk_4frames.png
- assets/zombie_brute_walk_4frames.png

Gemeinsamer Generierungsprompt, mit dem jeweiligen Figurenabschnitt eingesetzt:

Create a production game animation sprite atlas using the reference character identity and inked hand-painted detailed 2D style. [CHARACTER] Exactly FOUR complete full-body left-facing side-view aggressive grounded walking poses arranged in a strict 2 by 2 equal square grid. One character per cell, all feet fully visible, identical body scale and lighting in every frame. Cycle: left leg forward/right back, passing pose, right leg forward/left back, opposite passing pose. Clearly different leg and arm positions, weighty grounded gait, snarling reaching arms. Keep head, outfit, body proportions from reference. Each sprite centered in its cell with generous transparent gutters on all sides. No character overlaps another cell, no text, no ground or shadow, transparent background. This is an animation atlas, not a scene.

CHARACTER:
- Arbeiter: construction worker orange hardhat, fluorescent yellow safety vest and orange trousers.
- Gepanzerter: armored riot police blue helmet with clear visor, dark blue uniform and black body armor.
- Kettenbrute: large bald heavy brute brown torn long coat, red shirt, iron waist chain and leather wrist guards.

Einbindung in DrivingTestCourse und Terrain. Transparente Ränder werden je Zelle ermittelt; ein gemeinsamer Höhenmaßstab verhindert, dass jede Schrittpose auf eine andere Körpergröße gestreckt wird. Bestehende Einzelbilder bleiben für Trefferreaktionen erhalten.

PC-Prüfung: Für jede der drei Arten eine echte Fahrt mit Gaseingabe bis zum Kontakt. Die Dachlandungsprüfung kontrolliert Luftüberschlag, Rauch vor Feuer, verzögertes Game Over, Neustart und tatsächlichen Wechsel zur Werkstatt. Persönliche Spielstände wurden durch ein getrenntes Testprofil geschützt. Android wurde nicht geprüft.
