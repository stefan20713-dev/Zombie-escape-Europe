# Amsterdam – Hafenausfahrt Version 1

## Aktueller Status nach neuer Nutzeranweisung
Das Tor wurde ausdrücklich verworfen und vollständig aus der laufenden Strecke entfernt: Grafik, Vordergrundpfeiler, Schild, Leuchten und Torbeschattung. Zugehörige unbenötigte Laufzeitdateien und das Bild wurden nach Referenzprüfung gelöscht. Die folgende Beschreibung dokumentiert den früheren Entwurf und gilt hinsichtlich des Torbildes nicht mehr als Freigabe.

Ziellinie, sichere Ausrollzone, Abschlussmarkierung, einmalige Münzbelohnung und Auswertung bleiben erhalten. Aktuelle Prüfung ohne Tor: `.local_probe/no-gate-final.log`, bestandener Abschnittstest mit echten Eingaben, gespeicherten Käufen und Abschluss, Pause und Neustart. Die aktuelle Zielansicht wurde gerendert und angesehen. Die Regel steht auch in AGENTS.md.

## Auftrag und Sicherung
Version 1 ausdrücklich vom Nutzer gewählt: aufgebrochene Hafenausfahrt, Amsterdam-Schild, Warnleuchten, erkennbare Ziellinie und kurze Ausrollzone. Das allgemeine Entwicklungsziel bleibt auf Nutzerwunsch pausiert. Dieser Schritt bearbeitet nur die Zieleinfahrt sowie die anschließend gemeldete Blickrichtung und Wrackreaktion der Zombies.

Vor Änderungen wurde `Sicherungen/Zombie_Escape_Europe_PC_Meilenstein_2026-11-08_17-57-07.zip` erstellt und vollständig geprüft: 5.541 Dateien, 2.944.059.809 Bytes. SHA-256-Nachweis in der gleichnamigen `.zip.json`. Regenerierbare Importcaches, lokale Prüfprofile und Sicherungen selbst sind ausgeschlossen.

## Zieleinfahrt
- Neues transparentes Torbild `assets/amsterdam_harbor_exit_v1.png`: Stein und Ziegel, Efeu, beschädigte offene Eisenflügel, Seile, Poller und Warnleuchten. Mipmaps aktiviert, natürliche Proportionen erhalten, sichtbare Bildgrenzen ausgemessen.
- Dynamisch beschriftetes Schild AMSTERDAM / HAVENUITGANG. Feste Straßenmarkierung bei tatsächlich gefahrenen 1.800 m.
- Die letzte Anfahrt wird weich auf eine ebene Ausrollzone geführt; Kollision und sichtbare Straße verwenden dieselbe Höhenfunktion. Zusätzliche Straßenlänge liegt ausschließlich hinter dem Levelziel.
- Nach Nutzerfeedback zur räumlichen Wirkung: eigene Vordergrundebene für beide Pfeiler. Das Auto fährt hinter den Pfeilern und vor den offenen Torblättern. Eine dezente Beschattung verbindet das Fahrzeug mit dem Durchgang; die Grafik wird nicht gestaucht.
- Nach Überqueren der Ziellinie etwa zwei Sekunden kontrolliert mit echter Fahrzeugbewegung ausrollen. Eingaben können keine neue Beschleunigung oder Nitro auslösen. Straßenkontakt und Tacho bleiben aktiv. Pause hält die Ausrollphase an.
- Trefferflächen werden beim Ziel deaktiviert; verspätete Kontakte und Fasszündungen können die erfolgreiche Fahrt nicht nachträglich zerstören. Klammernde Zombies lassen sichtbar los. Sechs Verfolger bleiben hinter der Zieleinfahrt.
- Neue Auswertung mit Strecke, Zombies, Aktionen, Gesamtverdienst, Guthaben und bezahlbarem nächsten Ausbau. Werkstatt und erneute Fahrt direkt erreichbar.
- Bei einer echten Werkstattfahrt wird Amsterdam als abgeschlossen gespeichert und der Bestwert auf mindestens 1.800 m gesetzt. Münzen werden einmalig gutgeschrieben; vorhandene Käufe bleiben erhalten. Direkte Vorschaufahrten kennzeichnen nicht gespeicherte Münzen ausdrücklich.

## Nachkorrektur der Wrackhorde
- Laufatlanten zeigen ursprünglich nach links. Spiegelung deshalb an die tatsächliche Bewegungsrichtung angepasst, einschließlich Verfolgern hinter der Zieleinfahrt.
- 16 Gegner laufen von beiden Seiten heran. Die vorderen zwei pro Seite greifen nach Erreichen des Autos sichtbar an dessen Karosserie, statt bloß daneben zu laufen. Verwendet werden die vorhandenen passenden Figuren aus dem gemeinsamen Posenatlas.
- Weitere Gegner rücken versetzt nach. Blickrichtung, Verzögerung und Annäherung sind pro Gegner gespeichert. Keine zusätzlichen Münzen oder zusätzlichen Strafschäden aus der Unfallsequenz.
- Rauch, Feuer und Game over nach 3,8 Sekunden bleiben erhalten; Neustart entfernt die Horde.

## Tatsächlich geprüft
- `amsterdam_harbor_arrival_test.gd`: echte Tastatureingaben im Zielanlauf, Weiterrollen nach der Linie, kein weiterer Kontakt-Schaden, unveränderte Restwerte, Pause, korrekte und einmalige Belohnung, gespeicherter Stadtabschluss, unveränderte Käufe nach Neuladen, Neustart über tatsächlichen Mausklick auf den neuen Button.
- Auswertung bei 1280 × 720 und 1920 × 864 gerendert und angesehen.
- `wreck_horde_test.gd`: 16 Gegner, richtige Blickrichtung im verwendeten Laufatlas, Annäherung, sichtbarer Griffzustand, Feuer/Game over und bereinigter Neustart. Aktuelle Bilder neu gerendert und kontrolliert.
- `harbor_depth_sequence.gd`: Durchfahrt in aufeinanderfolgenden Positionen vor, zwischen und hinter den Vordergrundpfeilern aufgenommen.
- Vollständige 1.800-m-Fahrt mit Motor II/Nitro I, Reifen II, Tank III, Panzerung II, Fahrwerk I und Waffe I bis zur neuen Auswertung bestanden. Fahrzeit an der Ziellinie 68,67 Sekunden, anschließend Ausrollen. Resttank 34,90 und Karosserie 66,90.
- Gegenprüfungen: ursprüngliche Brückenrouten, Schleusensprung und Dachunfall-Sequenz bestanden.
- Aktuelle Protokolle: `.local_probe/depth-amsterdam_harbor_arrival_test.log`, `depth-wreck_horde_test.log`, `harbor-full-drive.log`, `harbor-depth-sequence.log`.
- Eigene APPDATA-Testprofile; keine persönlichen Spielstände zurückgesetzt. Keine Veröffentlichung und keine Telefonprüfung. Keine Behauptung durchgehend stabiler 60 FPS; lokale FPS-Stichproben der Vollfahrt hatten Median 78 und Minimum 42 bei parallel laufenden Prüfungen.

## Grafikherstellung
Built-in-Bildwerkzeug; endgültige Grafik ins Projekt kopiert, kein Benutzer-Cache als Laufzeitabhängigkeit.

Exakter Prompt:
Production environment sprite for a detailed hand-painted 2D side-scrolling zombie driving game set in Amsterdam. An abandoned Dutch HARBOR EXIT GATE, orthographic side-view game scenery, no perspective road receding into distance. Wide gateway about 1.6:1 aspect, two weathered dark brick and pale stone piers at far left and far right, rusty riveted iron overhead crossbeam. Large EMPTY rectangular dark green sign panel centered above opening for later dynamic lettering. Broken wrought-iron gate leaves are pushed BACK and OUTWARD along far side of gateway, bent hinges, one damaged leaf leaning outward; the ENTIRE central horizontal roadway remains CLEAR. Warm amber beacon lamps on top corners, lamp glass unlit so game can animate light. Ivy, ropes coiled beside piers, small Dutch harbor details, subtle rust and chipped masonry, dark ink outlines, rich painted material detail, warm upper-left lighting and cool shade. The base of both piers lies exactly on the same horizontal baseline, no ground plane and no shadow below baseline, gateway complete with no clipping. No people, no zombies, no vehicles, no water, no background city, no floor, no sky, no text or lettering, no logos. TRUE transparent RGBA everywhere outside the gateway, generous empty transparent margins. Clear open center all the way through to the bottom. This is a reusable game foreground/background asset, not a concept screenshot.

## Start
Alte Vorschau schließen und `Start_Zombie_Escape_Europe_PC_Preview.bat` erneut starten. Nutzerabnahme der Durchfahrt und des Wrackverhaltens steht aus.

