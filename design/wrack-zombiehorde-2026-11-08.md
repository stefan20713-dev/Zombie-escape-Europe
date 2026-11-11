# Zombiehorde beim Überschlag

- In Amsterdam starten beim endgültigen Überschlag 16 zusätzliche Gegner aus beiden Richtungen. Verschiedene Arten, versetzte Startpunkte, eigene Geschwindigkeiten und Animationsphasen. Ziele bleiben verteilt, statt alle Figuren auf demselben Punkt zu stapeln.
- Sie bewegen sich auf dem vorhandenen Straßenprofil auf das Wrack zu. Es sind zusätzliche Figuren der Unfallsequenz, keine neuen belohnbaren Treffer und keine zusätzlichen Strafschäden. Die vorhandene Abfolge Rauch, Feuer, Game over nach 3,8 Sekunden bleibt bestehen.
- Die Bewegung wird ausdrücklich während des eingefrorenen Wrackzustands aktualisiert. Pause hält sie an; Neustart entfernt sie vollständig. Normale Streckenbegegnungen bleiben unverändert.
- Gerenderter Test `tests/wreck_horde_test.gd`: 16 Gegner, tatsächliche Annäherung, unveränderte Feuer-/Game-over-Zeit und geleerter Zustand nach Neustart bestanden. Bild `build/wrack-zombiehorde.png` kontrolliert, Prüfprotokoll `.local_probe/wreck-horde-final.log` ohne Skriptfehler.
- Die Zieleinfahrt wurde bei diesem Schritt noch nicht umgebaut; der Nutzer hat dafür zunächst Vorschläge angefordert.

## Weniger Überlagerungen – aktuelle Anpassung
Zusätzliche Wrackgruppe auf sechs Zombies reduziert (drei pro Seite), Abstand der Wartepositionen 160 Weltpixel. Nur einer pro Seite greift unmittelbar an; die anderen bleiben mit Abstand dahinter. Normale Streckenzombies werden während dieser Wrackszene nicht zusätzlich darüber gezeichnet. Fahrt und Neustart verwenden wieder die normalen Gegner. Grafischen Test mit Bildschirmaufnahme ausgeführt; Annäherung, Feuer, Game over und Zurücksetzen bestanden. Aufnahme: build/wrack-zombiehorde.png.
