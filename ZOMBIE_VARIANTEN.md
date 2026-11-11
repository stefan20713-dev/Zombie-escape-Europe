# Zombie-Varianten

Die Gegnerprofile sind in `scripts/zombie_data.gd` gebündelt. Die fünf gezeichneten PNGs liegen unter `assets/` und werden in der Fahrt, bei Zusammenstößen und beim Wegschleudern verwendet.

| Stufe | Figur | Verhalten am Fahrzeug |
| --- | --- | --- |
| 1 | Gelbe Regenjacke | Normales Tempo, mittlerer Aufprallschaden, hält sich gelegentlich kurz fest. Das ist der einzige Zombie-Typ auf der Rotterdam-Strecke. |
| 2 | Roter Läufer | Rennt am schnellsten, ist leicht zu überfahren, bremst und beschädigt den Kombi nur wenig und hält sich selten fest. |
| 3 | Bauarbeiter | Schwerer Aufprall; bremst das Auto kräftig und hält sich länger fest. |
| 4 | Riot-Polizist | Schwerer Aufprall und längeres Festhalten als der Bauarbeiter. |
| 5 | Kettenbrute | Schwerster Treffer; bringt das Auto für eine Sekunde zum Stillstand und kann anschließend noch am Dach hängen. |

Amsterdam hat eine einzelne gestaltete Begegnung mit Stufe 1; Rotterdam hat eine gestaltete Gruppe aus drei Figuren desselben Typs. Die fünf Profile und Grafiken sind vorbereitet. Auf späteren Routen bleiben vorhandene prozedurale Zombiebegegnungen und Horde-Ziele des Kampagnen-Prototyps erhalten; ihre individuellen Streckenmotive werden erst gestaltet, wenn diese Routen an der Reihe sind. Alle Profile haben eigene Laufgeschwindigkeit, sichtbare Größe, Trefferwirkung und Festhaltewerte. Festhalten verbraucht Treibstoff und verursacht über die Zeit Fahrzeugschaden. Langsameres Fahren verlängert die tatsächliche Haltezeit.

## Projektgrafiken

- `assets/zombie_normal_0.7.0.png`
- `assets/zombie_runner_0.7.0.png`
- `assets/zombie_worker_0.7.0.png`
- `assets/zombie_riot_0.7.0.png`
- `assets/zombie_brute_0.7.0.png`
