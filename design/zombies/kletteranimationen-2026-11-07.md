# Kletteranimationen – 7. November 2026

Mit dem integrierten Bildgenerator aus den bestehenden Figuren erstellt. Verwendete Dateien im Projekt:

- assets/zombie_normal_crawl_4frames.png
- assets/zombie_runner_crawl_4frames.png
- assets/zombie_worker_crawl_4frames.png
- assets/zombie_riot_crawl_4frames.png
- assets/zombie_brute_crawl_4frames.png

Pro Figur vier nach rechts blickende Kletterposen. Jeweilige Referenz: assets/zombie_[normal|runner|worker|riot|brute]_0.7.0.png.

Gemeinsamer Prompt für alle fünf Referenzfiguren:

Production sprite atlas for the referenced zombie, preserving precisely its outfit, face, colors, material textures and inked illustrated 2D game style. Exactly FOUR FULL-BODY crawling animation poses in a strict equal 2 by 2 grid, one complete character centered in each cell, transparent wide gutters. All four characters face RIGHT, showing their RIGHT-FACING face profile clearly looking forward. Crawling low on hands and bent knees toward the RIGHT along an invisible flat horizontal car roof. Head and shoulders at the RIGHT, hips, coat tails and boots trail to the LEFT. Alternating reaching hands and knees: frame 1 right hand reaches forward, frame 2 pulls chest forward, frame 3 opposite hand reaches forward, frame 4 opposite knee advances. Hands and supporting knees touch the same baseline, body stays low, elbows bent with weight on palms, a threatening purposeful crawling motion. Same scale and body proportions in every frame. All extremities visible and each figure fully contained in its cell. No car, no roof, no floor, no text, no extra objects, no shadows, only four isolated crawling character sprites with transparent background. Do not make them upright walkers or jumping poses.

Der erste Normalzombie-Entwurf hatte einen Hintergrund und wurde nicht eingebunden. Korrekturprompt für die verwendete transparente Version:

Remove the entire gray/white background and all shadows and make the background truly fully transparent alpha. Preserve only the four crawling yellow-coat zombie figures, exactly their existing poses, colors, 2x2 grid positions and size. Do not add any background, floor or shadows. Transparent sprite sheet for a game, isolated figures only.

Verhalten: Alle fünf Arten können sich beim räumlichen Kontakt festklammern. Blickrichtung bleibt zur Motorhaube, auch beim Zurückrollen. Vorwärtsbewegung auf dem Dach wird durch Fahrtwind verlangsamt. Kletterer halten Abstand. Nach Ablauf des Griffs folgt eine kurze sichtbare Fallbewegung in Weltkoordinaten. Neustart entfernt auch diese Figuren.

PC-Prüfungen: Alle fünf Typen über den Begegnungsaufruf geprüft, alle zwanzig Bildausschnitte dargestellt. Vorwärtsbewegung, Blick beim Zurückrollen, Abstand, Abfallen und Aufräumen geprüft. Echte Fahrt mit Gaseingaben: Arbeiter klammert sich fest, klettert über 52 Pixel nach vorne und fällt ab. Untere Amsterdam-Route komplett über 1800 Meter bestanden, 80,2 Sekunden. Vorhandener Festklammer-Test mit Zusatzverbrauch, Bremswirkung und Panzerungsschutz bestanden. Separates Testprofil, persönliche Spielstände erhalten. Android-Leistung nicht geprüft.
