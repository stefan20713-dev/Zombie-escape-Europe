# Modularer Kombi-Ausbau – Entwicklungsauftrag

ÜBERHOLT für die aktuelle Arbeit: Der Nutzer hat ausschließlich fünf PANZERUNGSSTUFEN beauftragt. Verbindlich ist jetzt ../tuning-v2/PANZERUNG-AUFTRAG.md. Keine separaten Käufe für Rammbock und Gitter umsetzen; Licht, Nitro und Geländereifen gehören nicht zu dieser Panzerungsfolge.

Verwende den bestehenden Serien-Kombi aus assets/kombi_body_0.5.10.png als verbindliche Fahrzeugidentität. Die PNGs in diesem Ordner sind mit Imagegen erzeugte Konzeptbilder für die einzelnen Ausbauschritte, keine fertigen beweglichen Sprites. Orange Karosserie, Fenster, Türen und Radstand beibehalten. Räder weiterhin unabhängig von der Karosserie drehen. Die Karosserie darf beim Kauf eines beliebigen Teils nicht zu einem anderen Fahrzeug wechseln.

## Bildfolge und einzeln kaufbare Teile
Die Bildfolge zeigt einen kumulativen Beispielausbau. Im Spiel müssen unabhängige Kombinationen möglich sein: etwa Licht ohne Gitter oder Nitro ohne Rammbock.

| Bild | Neuer Anbau | Eigene Kauf-ID | Wirkung |
| --- | --- | --- | --- |
| 00-serie.png | Serienfahrzeug | keine | Basis aus vorhandenem Spiel |
| 01-rammbock.png | Verschraubter Stahlkeil vorne | ram | Besseres Durchbrechen, weniger Tempoverlust bei passenden Fronttreffern |
| 02-fenstergitter.png | Gitter mit Rahmen über Fenstern | window_guards | Schutz bei passenden Gegner-/Karosserietreffern |
| 03-zusatzlicht.png | Dachscheinwerfer und Front-Zusatzlampen | lights | Sichtbare Beleuchtung; bei Nacht Sichtbarkeit verbessern, keine erfundenen Motorboni |
| 04-nitro.png | Blaue Flasche, Halter, Ventil, Leitung | vorhandene Nitro-ID prüfen | Tatsächlicher Boost-Schub, Vorrat/Verbrauch und Dauer konsistent abstimmen |
| 05-vollausbau.png | Türpanzerung, Geländereifen/Fahrwerk, Motor-/Auspuffdetails | vorhandene Upgrade-IDs | Bereits vorhandene Funktionsupgrades anbinden |

Rammbock, Fenstergitter und Licht erhalten eigene Einträge im Bereich KAROSSERIE / ANBAUTEILE. Motor, Reifen, Tank, Panzerung, Nitro bleiben erreichbar; horizontal scrollbare Kategorien oder sauber getrennte Unterbereiche verwenden statt acht schmaler Karten. Keine funktionierenden bestehenden Käufe entfernen.

## Arbeitsschritt 1: Daten und Serienzustand
Lies den aktuellen Code und vorhandene Upgrade-IDs. Das Projekt kann sich seit Erstellung dieser Vorgabe weiterentwickelt haben. Vorhandenes Nitro wiederverwenden. Ersetze die von aufsummierten Upgrade-Punkten abhängige vollständige Karosserieumschaltung durch unabhängig kombinierbare sichtbare Bauteile. Bestehende Daten migrieren, ohne Käufe oder Spielstände zu verlieren. Neue Felder erhalten Standard 0; bestehende Panzerung bleibt erhalten, löst aber keinen unbezahlten Kauf neuer Anbauteile aus. Bestehende Spielfortschritte nicht überschreiben.

## Arbeitsschritt 2: Rammbock zuerst
Erstelle einen einzelnen transparenten Anbau passend zum Serien-Kombi. Kaufroutine, Preis, Vorschau, Montage und Speicherung anbinden. Trefferform/Frontkontakt folgt der tatsächlichen Ausdehnung. Rammbockwirkung nur für geeignete Fronttreffer anwenden, nicht pauschal für jede Schadensart. Fahrzeugbodenfreiheit und Rampenbefahrbarkeit erhalten. Zuerst funktionierende PC-Vorschau liefern und Feedback abwarten.

## Arbeitsschritt 3: Fenstergitter
Nach Freigabe eigenes Bauteil und Kauf hinzufügen. Gitter dürfen Türen/Fenster nicht in fremde Geometrie verwandeln. Rahmung und Stäbe auch im Fahrbild lesbar. Schutzwirkung nur an tatsächliche vorhandene Trefferarten anschließen. Falls passende Trefferarten fehlen, diese zuerst nachvollziehbar definieren; UI darf keine nicht implementierte Schutzwirkung versprechen. Zusammen mit und ohne Rammbock darstellen.

## Arbeitsschritt 4: Licht
Eigener Kauf mit sichtbaren ausgeschalteten Lampen am Tag und warmem Licht bei Dunkelheit. Dezenten Lichtkegel ergänzen, ohne Bedienung oder Fahrbahn zu überstrahlen. Keine willkürlichen Leistungswerte. Bestehende Tag-/Nachtbedingungen prüfen; falls es keine Dunkelheit gibt, Licht als sichtbares kosmetisches Upgrade kennzeichnen und vor funktionaler Nacht-Erweiterung Rückmeldung einholen.

## Arbeitsschritt 5: Nitro
Vorhandene Implementierung und Spielstände berücksichtigen. Flasche sichtbar, Boost-Effekt nur bei tatsächlichem Einsatz. Vorrat, Verbrauch, eventuelle Regeneration, Schub und Dauer aus denselben realen Parametern in UI und Fahrphysik ableiten. Keine mehrfachen Nitro-Systeme einführen.

## Arbeitsschritt 6: Vollausbau
Bestehende Motor-, Tank-, Panzerungs-, Reifen- und Fahrwerksstufen mit passenden Bauteilen darstellen. Das letzte Bild zeigt eine Zielkombination, keinen automatisch freigeschalteten Gesamtskin. Tankkanister und Nitroflasche haben getrennte Anbaupositionen. Zusatzlicht und Nitro brauchen voneinander getrennte Dachhalter. Grafische Überschneidungen vermeiden.

## Gemeinsame Grafikregeln
Die generierten Konzepte können in Details voneinander abweichen. Verbindlich für jedes einzelne Teil ist sein erstes Einführungsbild: Rammbock aus 01, Fenstergitter aus 02, Lampen aus 03, Nitro aus 04. Diese Teile in späteren Kombinationen unverändert wiederverwenden; abweichende Rammbockformen in späteren Konzeptbildern nicht als zusätzliche Stufe interpretieren. Für Karosserie und Radstand bleibt das Originalasset maßgeblich.
Getrennte transparente Ebenen: Karosserie, Rad hinten/vorn, Rammbock, Fenstergitter, Lampen, Nitro, Türpanzerung, Motor, Tank. Gemeinsame Bezugspunkte und native Fahrzeugkoordinaten verwenden. Unterschiedliche Bildränder der Konzepte dürfen den Radstand nicht verändern. Konzepte nicht komplett als Fahrzeugtextur einbauen: sonst würden Räder und Anbauten miteinander verschmelzen. Farben und Konturen an Originalgrafik anpassen, nicht das Fahrzeug neu erfinden.

## Abnahme je Schritt
Serienzustand und einzelnes Teil direkt vergleichen. Werkstattvorschau und tatsächliches Fahrfahrzeug müssen übereinstimmen. Kauf zieht genau einmal Münzen ab; fehlendes Geld und maximale Stufe klar behandeln. Kauf bleibt nach Neustart erhalten. Einzeln und kombiniert prüfen. Jede versprochene Wirkung im realen Spiel prüfen. Nach jedem Arbeitsschritt einen startbaren PC-Stand bereitstellen und Nutzerfeedback abwarten. Keine Store-Arbeiten, Kampagnenerweiterungen oder unaufgeforderten Änderungen an anderen Systemen.
