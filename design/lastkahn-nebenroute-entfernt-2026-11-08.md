# Lastkahn-Nebenroute entfernt – 8. November 2026

Auf Nutzerwunsch sind die optionale Zwei-Lastkahn-Route, ihre Rampen, Seile, Poller, obere Ausweichbrücke, Abzweigschilder, Hinweise, Zusatzkollisionen, Wasserabsturzlogik und 60-Münzen-Belohnung entfernt. Die ursprüngliche Straßenkollision wird nicht mehr unterteilt oder durch Bremsen umgeschaltet. Normale Straße, Pflaster und Mauer sind im gesamten Abschnitt wiederhergestellt. Der ursprüngliche Lastkahn bei 820 m sowie Kranlasten, Abschütteln und Kombos bleiben bestehen. Persönliche Spielstände wurden nicht verändert.

Geprüft: durchgehende Kollisionssegmente und Straßenhöhe im ehemaligen Nebenroutenabschnitt; kein zusätzlicher Routenkörper; ursprünglicher Lastkahn vorhanden; Kran-, Abschüttel- und Komboprüfung bestanden. Sichtbare Fahrt mit echten Gas-, Brems- und Nitroeingaben von 1.015 bis über 1.130 Weltmetern bestanden, einschließlich Bremsen an der früheren Abzweigung. Prüfbild `build/action-continuous-road-3.png` zeigt die wiederhergestellte Straße und Mauer. Log: `.local_probe/no-side-route-drive.log`.

Der überholte Wasserabsturztest der Nebenroute wurde durch `tests/amsterdam_no_side_route_test.gd` ersetzt; der bestehende Fahrprüfer kontrolliert jetzt die durchgehende Straße. Sicherheitskopien der zuvor betroffenen Dateien liegen in `.local_probe/remove-side-route-2026-11-08/`.
