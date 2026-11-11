# Serien-Kombi: Boden, Dachkontakt und Schaden – 8. November 2026

Auf Nutzerfeedback zum schwebenden Serien-Kombi, aufgesetzt wirkenden Seitenschäden und schwebenden Kletterzombie angepasst.

## Änderungen

- Die Federhöhe des Kombis richtet sich nach der sichtbaren Reifenunterkante, Reifenstufe, Fahrzeugmasse und Federstärke. Der transparente Bildrand der Serienreifen zählt nicht als Gummifläche. Auch die Ausgangshöhe und die Freigabehöhe am Schleusensprung verwenden dieselbe Bodenfreiheit.
- Die Räder bleiben an den bisherigen Radkästen und Achspositionen. Lieferwagen und Pickup behalten ihre bisherige Federhöhe.
- Alle 20 Kletterbilder der fünf Zombiearten verwenden vermessene sichtbare Bildausschnitte. Transparente Ränder unter Händen und Knien erzeugen keinen künstlichen Abstand mehr zum Dach.
- Kletterpositionen auf dem Kombi richten sich nach der jeweiligen Körperlänge. Die Hände gelangen höchstens bis zur vorderen Dachkante; der Zombie kriecht nicht weiter über die Windschutzscheibe in die Luft. Höchstens zwei Zombies greifen gleichzeitig am Kombi; rückwärtiges Nachhängen und die vorhandene Fallanimation bleiben erhalten.
- Große aufgemalte orange Blechdellen auf Türen und Kotflügeln entfernt. Die ursprüngliche Lackfläche bleibt sichtbar; dünne vertiefte Knicke und Kratzer ergänzen die tatsächliche Karosserieverformung. Der neu erzeugte Blechbildsatz wird nur noch für abgelöste Teile verwendet; Glasbruch bleibt ein eigener Effekt.

## Geprüft

- Eigenständiger Physiktest mit echter Schwerkraft und Federung, vier Reifenstufen. Gegen die unabhängig vermessenen sichtbaren Reifenränder geprüft: Abstand zwischen etwa -0,03 und +0,08 Weltpixeln im eingeschwungenen Stand.
- Dachkontakt für alle fünf Zombiearten und alle 20 Bilder: sichtbare Unterkante und maximale Handposition geprüft. Vorwärtsklettern, Ablösen und Zurücksetzen bestanden.
- Sichtbare Serien-Kombi-Fahrt mit Gas-Eingaben, Zustand 60 % und Arbeiter-Zombie; Kontrollbilder `build/contact-standard-60.png`, `build/contact-standard-120.png` und `build/contact-standard-159.png`.
- Vollständige 1.800-m-Fahrt bestanden: 75,25 s, Resttreibstoff 24,98, Zustand 32,45 %. Profil Motor II / Reifen II / Tank III / Panzerung II / Fahrwerk I / Nitro III / Waffe I.
- Schleusenprüfung bestanden: niedrigeres Tempo endet im Wasser, 135-km/h-Fall erreicht die Landung; Game-over und Neustart funktionieren.
- Upgradeprüfung mit 96 Einträgen über drei Fahrzeuge bestanden.
- Die PC-Aufzeichnung lag bei 51 FPS im Median und mindestens 35 FPS. Stabile 60 FPS und reale Android-Leistung sind weiterhin offen.

Dateien: `scripts/wagon.gd`, `scripts/zombie_data.gd`, `scripts/vehicle_damage_details.gd`, `scripts/amsterdam_preview_course.gd`. Neue Kontaktprüfungen: `tests/wheel_ground_contact_test.gd`, `tests/zombie_roof_contact_test.gd`, `tools/standard_contact_drive_probe.gd`. Logs: `.local_probe/contact-*.log`.

Persönliche Spielstände und gekaufte Upgrade-Stufen wurden nicht geändert. Die vorhandene ZIP-Sicherung wurde nicht überschrieben.
