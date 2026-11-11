# Werkstatt – Umsetzungsvorgabe

Aktuelle Bildvorlage: `werkstatt-konzept-v2-nitro.png`. Enthält alle fünf Kategorien. Angezeigte Preise und Boni sind Layoutbeispiele.

Status: Designentwurf, keine Änderung am laufenden Spiel. Das Konzeptbild ist eine visuelle Vorlage, kein fertiges UI oder Spriteatlas. Verbindlich ist diese Vorgabe einschließlich NITRO; ein gegebenenfalls älteres Konzeptbild mit vier Kategorien zeigt nur die Grundgestaltung.

## Ziel
Eine gezeichnete postapokalyptische Werkstatt als europäischer Unterschlupf. Der orange Kombi steht groß und seitlich auf einer Hebebühne. Warme Arbeitslampen, dunkler Stahl, Backstein, Werkzeug und kühles Hafenlicht geben Atmosphäre. Fahrzeug und Bedienung bleiben deutlich vom Hintergrund getrennt. Kein Fahrbild als Menü-Hintergrund.

## Anordnung bei 1280 × 720
Alle Koordinaten sind logische Pixel. UI mit Godot-Control-Ankern und Containern skalieren, keine rein absoluten Positionen verwenden.

| Bereich | Rechteck x, y, Breite, Höhe | Inhalt |
| --- | --- | --- |
| Kopf | 24, 16, 1232, 56 | WERKSTATT, Ort, tatsächlicher Münzstand, Einstellungen |
| Fahrzeugbühne | 24, 88, 856, 388 | Großes ausgewähltes Fahrzeug, Fahrzeugwechsel, dezente Anbau-Markierungen |
| Upgrade-Details | 904, 88, 352, 388 | Kategorie, aktuelle/nächste Stufe, reale Werte, Preis, Kaufen |
| Kategorien | 24, 496, 1232, 112 | Fünf gleichwertige Karten: MOTOR, REIFEN, TANK, PANZERUNG, NITRO |
| Fuß | 24, 632, 1232, 64 | Fahrzeug/Fahrwerk, Europakarte, primär LOSFAHREN |

Fünf Karten mit je ungefähr 234 Pixel Breite und 15 Pixel Abstand; Details ausschließlich im rechten Panel. Keine langen Texte in Karten. Touchflächen mindestens 48 × 48 logische Pixel. Alle Texte müssen bei 1280 × 720 ohne Überlagerung lesbar sein. Einstellungen, Datenschutz und Funkarchiv über Nebenmenüs erreichen.

## Stil
- Hintergrund #172326, Panel #202D2C, heller Text #F3E5C5, Nebeninformation #B6C0AF.
- Ausgewählt #E9B75B, Hauptaktion #BE6333. Kontrast und Lesbarkeit im tatsächlichen Spiel prüfen.
- Gezeichnete Metallrahmen und kleine Nieten sparsam einsetzen. Keine Texturen hinter kleinem Text.
- Überschriften 26–30 px, Kategorien/Buttons 20–22 px, Details mindestens 18 px.
- Fahrzeug ungefähr 580–650 px breit; Bühnenfläche enthält keine Textblöcke über dem Auto.

## NITRO – zusätzliche Tuning-Kategorie
NITRO ist ein eigenständiges Upgrade, nicht nur ein dekorativer Button oder ein anderer Name für TANK.

- TANK bezeichnet ausschließlich Treibstoff. NITRO beeinflusst den Boost.
- Stufen 0–5. Noch nicht installiert, installiert, nächste Stufe und Maximum klar unterscheiden.
- Sichtbarer Anbau: befestigte Nitroflasche, Halterung und Leitungen; höhere Stufen erhalten größere beziehungsweise zusätzliche Flaschen und passende Düsen.
- Detailpanel zeigt Schub, nutzbare Boost-Dauer und Vorrat mit aktuellen und nächsten Werten. Zahlen aus tatsächlichen Spielparametern berechnen; keine erfundenen Boni anzeigen.
- Vor Implementierung bestehende Boost-Regeneration prüfen. Vorrat, Verbrauch und Nachladen müssen einheitlich funktionieren; Änderungen am bisherigen Verhalten dokumentieren.
- Kauf verändert tatsächlich die Fahrzeugabstimmung, zieht einmalig Münzen ab, speichert die Stufe und aktualisiert Vorschau und HUD.
- Alte Spielstände ohne Nitro-Stufe mit einem klar definierten kompatiblen Standard laden; vorhandene Boost-Funktion nicht unbeabsichtigt entfernen.
- Beispieltexte nur als Layoutvorlage: NITRO / STUFE 1 → 2 / SCHUB / BOOST-DAUER / VORRAT. Preise und Werte an bestehende Balance anschließen.

## Verhalten aller Upgrades
Karte auswählen öffnet Details und zeigt das nächste Teil am Fahrzeug als Vorschau. Vorschau eindeutig als solche kennzeichnen; ohne Kauf keine gespeicherten Änderungen. Kaufen führt zu kurzer Montageanimation und sichtbarer Fahrzeugänderung. Kaufzustände: verfügbar, zu teuer, gesperrt, Maximum. Neben Farbe auch Text oder Symbol nutzen. Nach erfolgreichem Kauf Fokus halten und Doppelkäufe durch schnelle Eingaben verhindern. Keine Werbe- oder Bezahlfunktionen ergänzen.

## Technische Umsetzung
Bestehende Wirtschaft, Fahrzeuge, Speicherdaten und Navigation wiederverwenden. Werkstatt als eigene Control-Szene beziehungsweise klar gekapselte UI aufbauen; keine neuen Abhängigkeiten in die Fahrphysik einführen. Fahrzeugvorschau aus denselben Upgrade-Daten wie das Fahrfahrzeug rendern. Bestehende Kaufroutinen anbinden statt ein zweites Upgrade-System einzuführen. Hintergrund, Fahrzeug und Bedienelemente als getrennte Ebenen/Assets erstellen; das Konzeptbild nicht als komplette klickbare Oberfläche einsetzen. Deutsche Texte als echten UI-Text rendern.

## Benötigte eigene Grafiken
1. Werkstatthintergrund ohne Schrift, Fahrzeug oder UI, 1920 × 1080.
2. Freigestellte Hebebühne und passende Vordergrunddekoration.
3. Transparente Icons für Motor, Reifen, Tank, Panzerung und Nitro.
4. Sichtbare Fahrzeuganbauten pro Upgrade einschließlich Nitroflaschen, passend zum Fahrzeugstil.
5. Zurückhaltende Panel-/Buttonrahmen mit normalem, ausgewähltem und deaktiviertem Zustand.

## Abnahme
Zuerst eine funktionierende Werkstatt am PC liefern. Alle fünf Kategorien bedienen, Kauf und Münzabzug prüfen, Spiel neu laden und gespeicherte Stufen kontrollieren. Nitro vor/nach Kauf im Fahrbetrieb vergleichen. Screenshot bei 1280 × 720 und breitem Mobilformat auf abgeschnittene Inhalte prüfen. Keine Kampagne, Strecke oder Store-Materialien nebenbei überarbeiten. Danach Nutzerfeedback abwarten.
