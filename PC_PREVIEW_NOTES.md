# PC-Vorschau: Kombi im ersten Abschnitt Amsterdam–Rotterdam

## Himmel/Wasser, Auspuff, Hindernis und Brückendurchfahrt 0.5.57 — 5. November 2026

- Das Panorama mit hohem Himmel und weit nach unten geführtem Kanal bleibt proportional und ist im Sprungbereich geprüft: In den PC-Aufnahmen bei 171 m und 420 m taucht keine obere oder untere Bildkante auf.
- Das Endrohr wurde verkürzt. Es läuft jetzt unter der Heckstoßstange in einem kurzen Bogen schräg nach außen; die sichtbare Öffnung ist leicht abgeschrägt. Rauch und Boost-Effekt verwenden weiterhin denselben Auslass.
- Ein weiterer zerstörbarer Kistenstapel ergänzt die neue, eigens gezeichnete Amsterdam-Hindernisgrafik bei 184 m. Die Hindernisgrafik enthält Absperrung, Holzkisten, rostige Fässer und Mauertrümmer und wird bereits entlang der Strecke eingesetzt.
- Die Stützen der erhöhten Brückenroute enden jetzt vor der oberen Kante der durchgehenden Straße. Im Lauf wurde bei 78,6 km/h die Unterführung gewählt; sie blieb durchgehend befahrbar. Die Brücke bleibt als erhöhte Sprungroute erhalten. Ein Lauf über die 120-km/h-Abzweigung wurde bei dieser Prüfung nicht bestätigt.
- Sichtbare PC-Prüfung mit Godot 4.7.2 und NVIDIA RTX 3050 Ti: 900,5 m in 47,85 s, 20 Kontakte, ein Sprung mit Landung, manuelle Balance, kein Überschlag; Höchstgeschwindigkeit 108,2 km/h. Isoliertes Testprofil; kein persönlicher Spielstand verändert.
- Vorschau: `tools/PC-Teststarts/Start_Amsterdam_Gameplay_Preview_PC.bat`. Bilder: `build/amsterdam_obstacle_review_0.5.57.png`, `build/amsterdam_exhaust_review_0.5.57.png` und `build/amsterdam_preview_strecke.png`.

## Hintergrund, Rampen, Hindernisse und Auspuff 0.5.56 — 5. November 2026

- Neues Amsterdam-Hintergrundbild mit mehr offenem Himmel und Kanalwasser. Die Bildgröße wird nicht beim Fahren verzerrt: Bei Sprüngen bleibt die obere Bildkante außerhalb des Sichtbereichs, während die gezeichnete Wasserfläche bis zur mitbewegten Straße reicht.
- Die Brücken- und Rampenstützen werden hinter der durchgehenden Straße gezeichnet; die Auffahrt ist länger und mit Straßenmarkierungen angekündigt. Die untere Durchfahrt bleibt offen. Bei gewählter oberer Route werden Hindernis-Trefferflächen auf dieselbe Höhe wie ihre sichtbaren Grafiken gesetzt.
- Eigene transparente Hindernisgrafiken für niederländische Absperrungen, Holzkisten, Fässer und niedrige Mauertrümmer hinzugefügt. Vier zusätzliche Trefferereignisse ergänzen den Amsterdam-Abschnitt.
- Der Endrohrstutzen ist jetzt als kurzer, gebogener Metallverlauf unter der Heckstoßstange gezeichnet. Er sitzt hinter Rad und Karosserie; Rauch und Boost-Flamme starten am schrägen Auslass.
- Godot-PC-Vorschau und beide Streckenwege müssen für 0.5.56 noch visuell geprüft werden. Der persönliche Spielstand bleibt unangetastet.

## Waffen- und Auspuffposition 0.5.55 — 5. November 2026

- Die Dachwaffe sitzt etwas weiter vorn auf der Dachhaut; ihre Montageplatte überlappt die Dachfläche leicht, damit sie befestigt statt schwebend wirkt. Mündungsblitz und Schusslinie folgen dem sichtbaren Lauf.
- Das kurze Endrohr sitzt jetzt tiefer unter der Heckstoßstange. Rauch und Boost-Flamme starten weiterhin am Auslass.
- Die vorherige Fassung 0.5.54 wurde in einer 1280×720-PC-Vorschau angesehen. Für 0.5.55 wurde Godot noch nicht erneut gestartet; die neue Platzierung ist deshalb noch nicht visuell abgenommen.
- Die PC-Vorschau lief mit einem isolierten Tuning-Testprofil. Eine echte Gas-Eingabe bewegte den Kombi bis 16 m; dabei zeigte die Anzeige 1 km/h und 90 % Karosserie. Die vollständige 45–60-Sekunden-Fahrt ist damit nicht abgenommen und bleibt offen. Der persönliche Spielstand wurde nicht verändert.

## Nitro und Auspuff 0.5.50 — 5. November 2026

- Neue transparente Nitro-Sprites: Stufe 1/2 zeigt genau eine blaue Flasche, Stufe 3 zwei übereinanderliegende Flaschen. Beide bleiben an der hinteren Seitenklappe montiert und liegen unabhängig von Motor, Tank oder Panzerung.
- Der Auspuff ist jetzt ein eigenes Sprite: nur ein dezenter kurzer, gerader Endrohrstutzen ragt waagerecht hinten unter dem Stoßfänger hervor. Er hat keine orange Manschette. Sein inneres Ende wird von der Karosserie verdeckt, damit er befestigt wirkt. Flamme und Rauch starten weiterhin am sichtbaren Auslass.
- Panzerung Stufe 1 hat eine neue, auf die Serienkarosserie abgestimmte Grafik. Der Orangeton bleibt nah an der Serie und die Gitter sitzen innerhalb der drei Seitenfenster statt als frei gezeichnete Linien darüber.
- Die importierten Bildränder werden beim Zeichnen ausgeschnitten, damit die eigentlichen Teile bei ihrer kleinen Fahrzeuggröße mehr Fläche einnehmen und klarer lesbar bleiben.
- Assets: `assets/kombi_nitro_single_0.5.50.png`, `assets/kombi_nitro_dual_0.5.50.png`, `assets/kombi_exhaust_0.5.50.png`, `assets/kombi_armor_tier1_0.5.50.png`.
- Godot 4.7.2 hat die 1280×720-Übersicht mit Serie, Panzerung 1 und Nitro 1–3 gerendert. Die Grafik ist importiert und sichtbar; die normale Fahrt wurde in diesem Schritt nicht erneut getestet. Vorschau: `build/nitro_visual_review_0.5.50.png`.

Diese spielbare Vorschau konzentriert sich auf ein Fahrzeug und einen kurzen Abschnitt. Sie ist ein visueller und spielerischer Ausschnitt, noch kein fertiges Spiel.

## Amsterdam-Referenzbild umgesetzt — 4. November 2026

- Das neue eigene Kanal-Panorama nimmt die helle, gezeichnete Amsterdam-Richtung des Referenzbildes auf: Grachtenhäuser, Bäume, Kirche und eine gemauerte Brücke liegen als zusammenhängende Stadtansicht hinter dem Wagen.
- Die Strecke hat einen durchgehenden Kopfsteinpflaster-/Steinrand und eine gemauerte Kanaleinfassung. Die Einfassung wird an der tatsächlichen Straßenlinie im Bildschirmraum ausgerichtet und füllt die ganze sichtbare Breite; so bleibt unter den Häusern kein abgeschnittener dunkler Hintergrundstreifen stehen.
- Die vorhandene Holzbarriere, Zombies und befahrbare Rampe bleiben auf der echten Fahrbahn/Kollisionslinie. Die Rampe und das Brückendeck teilen sich ihre sichtbare Höhe mit der jeweiligen Fahrfläche.
- Beim sichtbaren Fahrtest fiel auf, dass die Kopfsteinpflaster-Zeichnung wegen eines Startkamera-Ausschnitts nach dem Scrollen in eine glatte Fahrbahn überging. Die Steine werden jetzt über die komplette kurze Amsterdam-Strecke gezeichnet; die Textur bleibt damit beim Kamerawechsel durchgehend.
- Die Statuszeile hat eine dunkle Schriftkontur erhalten, damit sie sich auch vor hellem Himmel abhebt.
- Der Fahrtest hat ein Serienprofil und ein Tuningprofil (`T`). Das Tuningprofil aktiviert jetzt auch die Haubenpistole, damit ihre Montage im fahrenden Fahrzeug geprüft werden kann.
- Der separate Starter `tools/PC-Teststarts/Start_Amsterdam_Gameplay_Preview_PC.bat` setzt einen lokalen Test-Spielstandordner und startet direkt die Amsterdam-Vorschau. Der Profilordner liegt unter `build/pc_amsterdam_gameplay_preview_profile`; die normalen Spielstände werden dafür nicht überschrieben.
- Godot 4.7.2 hat das Projekt headless ohne Parserfehler geladen; anschließend startete die Vorschau sichtbar unter OpenGL 3.3 auf der NVIDIA RTX 3050 Ti. Die gemauerte Einfassung wurde im laufenden Bild nach einer sichtbaren Lücke korrigiert und erneut geprüft. Eine 45–60-Sekunden-Fahrt bis zum Ende sowie ein Android-Gerätetest sind noch nicht bestätigt.

## Aktueller Stand 0.5.49 — 3. November 2026

- Der Windows-Meilensteintest besteht: 35,87 Sekunden Fahrt, 598,1 m, Serienlimit 72 km/h und 60 FPS. Tempo 135/160 km/h, Zombies am Dach, Luft-Aufrichtung, Trefferfeedback und Soundtests bestanden.
- Android-Export: [Debug-APK 0.5.49](build/android/Zombie_Escape_Europe-debug-only-0.5.49.apk), Code 113, ARM64/x86_64, Debugsignatur geprüft und 16-KB-ausgerichtet. Das Paket wurde noch nicht auf AVD oder Telefon installiert.
- Der vorangegangene 0.5.48-Release-Touchlauf bestand Touch, Speichern und Kaltstart (25,42 m wiederhergestellt), blieb aber bei Median 2 FPS. 0.5.49 nutzt für den nächsten Versuch niedrig auflösendes Viewport-Rendering. Der Emulatorlauf scheiterte vor dem Start, weil auf Laufwerk C: nur 0,79 GB frei waren; Darstellungsqualität und Bildrate dieses Modus sind noch offen.
- Testprotokolle: `build/android/touch_milestone_road-collision-chunks-release-r2-2026-11-03_performance.txt`, `build/godot_vehicle_milestone_0.5.49-viewport-startup-regression_20261103_042328_486/`.

## Rückmeldungen geprüft – 2.–3. November 2026

- Nitro-Stufe 1/2 nutzt einen einzelnen blauen Drucktank; Stufe 3 nutzt die Doppelflaschen-Anlage. Die eigenen transparenten Assets sitzen auf dem Dachträger. Bildtafel: `build/nitro_visual_review_0.5.44.png`.
- Die Boostflamme beginnt an der neu gezeichneten Auspufföffnung am Heck und ist an den echten `boost_active`-Zustand gekoppelt.
- Normale Zombies in den ersten beiden Welten verwenden vier echte Laufposen mit wechselnden Armen und Beinen. Beim Festhalten greift eine vierteilige Hängeanimation mit beiden Händen am Dach; die Beine wechseln ihre Trittpose.
- Die übrigen bereits geprüften Rückmeldungen bleiben erhalten: langsamer Serienkombi und stärkerer Verbrauch/Schaden im einmaligen Serienversuch, Nitro erst nach Kauf, 135 km/h ohne Boost und höchstens 160 km/h mit Boost, Tacho 0–160, schadensabhängiges Ausrollen, kurze Überschlagfrist, unveränderte Serienräder unter Panzerung, befahrbare durchgehende Erasmusbrücke und eine Zombie-Begegnung je erste Welt.
- Meilensteinprotokolle: `build/godot_vehicle_milestone_0.5.44-feedback-audit-r2_20261102_230036_396/` (Stock-, Nitro-, Fahr-, Brücken-, Schadens- und Kamera-/Überschlagtests) und `build/godot_vehicle_milestone_0.5.44-feedback-audit_20261102_230152_883/` (Zombie-, Fahrzeug- und Panzerungstests).
- Der neue Hängevergleich liegt unter `build/pc_preview_zombie_latched_kombi.png` und `build/pc_preview_zombie_latched_kombi_motion.png`.
- Die vier echten Rotterdam-Laufposen sind unter `build/zombie_run_visual_review_0.5.44.png` zu sehen; `ZOMBIE_RUN_GALLERY_OK` und `ZOMBIE_VARIANTS_OK` bestanden.
- Das Serienrad hat ein eigenes transparentes Asset (`assets/kombi_wheel_stock_0.7.2.png`) und erscheint kleiner als die drei groben Reifen-Upgrades. Galerie und Laufzeit wählen für Stufe 0–3 vier verschiedene Radgrafiken; alle vier Fahrzeuge wurden mit Panzerung 3 verglichen. `KOMBI_TIRE_GALLERY_OK` und `TIRE_ARMOR_INDEPENDENCE_OK` bestanden. Bild: `build/tire_visual_review_0.7.2.png`.
- Android-Debug-APK 0.5.45 / Code 109: `build/android/Zombie_Escape_Europe-debug-only-0.5.45.apk`. Signatur und 16-KB-Ausrichtung bestanden. API-36-AVD bestätigte Appstart, 11 Touchaktionen, gehaltenes Gas mit Freigabe, Pause, Android-Zurück, gespeicherte Strecke/Musiklautstärke und Kaltstart; Serienreifen im Android-Werkstattscreenshot sichtbar. Artefakte: `build/android/touch_milestone_0.5.45_android_tire_visual*`. Der separate Rampen-QA-Lauf aus 0.5.44 bestätigte Boost-Touch, Absprung bei 66,5 km/h und die Containerpassage ohne Treffer. Ein echtes Telefon und das Play-Store-AAB wurden nicht geprüft/erstellt. PC-Vorschau: `Start_Zombie_Escape_Europe_PC_Preview.bat`; weitere Strecken und Store-Arbeiten bleiben bis zu deinem Feedback zurückgestellt.
- Android-Debug-APK 0.5.46 / Code 110: `build/android/Zombie_Escape_Europe-debug-only-0.5.46.apk`. Die Fahranzeige fasst Funk und Ereignisse jetzt in einem einzelnen schmalen Hinweisstreifen zusammen und lässt die Pausetaste frei. Export, Debugsignatur, 16-KB-Ausrichtung, API-36-Installation, 11 Touchaktionen, Gas halten/freigeben, Pause/Zurück, Speichern und Kaltstart-Wiederherstellung bestanden. Fahrbild: `build/android/touch_milestone_hud-notification-2026-11-03_run.png`. Emulator geprüft, echtes Telefon und Play-Store-AAB bleiben offen.
- Android-Debug-APK 0.5.47 / Code 111: `build/android/Zombie_Escape_Europe-debug-only-0.5.47.apk`. Die Straßenkollision wird auf die gewählte Route plus 220 m Landebahn begrenzt; aktive Amsterdam-Kollisionen enthalten 1.361 statt 2.215 Straßenpunkte, Rotterdam 1.461 statt 2.215. Die Brückenfläche und ihre Kollision bleiben durchgehend.
- Godot-Prüfung: `TERRAIN_COLLISION_BUDGET_OK` und `ROTTERDAM_SKILL_ROUTE_OK`; die 220-m-Landebahn und Brückenkollision wurden bestätigt. Der vollständige isolierte API-36-AVD-Touchlauf bestand Appstart, 11 Touchaktionen, Gas halten/freigeben, Pause/Zurück, Speichern und Kaltstart-Wiederherstellung. Fahrbild: `build/android/touch_milestone_route-collision-mobile-retry-2026-11-03_run.png`.
- **Leistungsgrenze:** Mit sichtbarem AVD-Fenster stieg die Median-Bildrate in aktiver Fahrt von 2 FPS (0.5.46) auf 4 FPS (0.5.47); mittlere Prozesszeit sank von 172,1 auf 134,1 ms und Physikzeit von 93,6 auf 47 ms. Das bleibt für ein flüssiges Spiel unzureichend. Pausierte Szenen liefen bei etwa 50–60 FPS. Ein echter Android-Telefontest fehlt, daher lässt sich noch nicht trennen, welcher Anteil vom Emulator und welcher vom Spiel stammt.
- Die APK wurde installiert und gestartet; `aapt`, `apksigner` und `zipalign` bestätigen Paket/Version, Signatur und 16-KB-Ausrichtung. Godot beendete den Exportprozess jedoch nach seiner Meldung `[ DONE ] export` mit Exitcode `-1073741819` (Windows-Zugriffsverletzung). Das APK-Artefakt ist vorhanden und auf dem AVD gelaufen; Ursache des Godot-Absturzes nach dem Export bleibt offen.

## Starten

Im Projektordner `Start_Zombie_Escape_Europe_PC_Preview.bat` doppelklicken. Das Skript startet die Hauptszene mit Godot 4.7.2.

- `W` oder `Pfeil hoch`: Gas
- `Leertaste`: Boost
- `A`/`D` oder `Pfeile links/rechts`: Fahrzeug in der Luft neigen
- `S` oder `Pfeil runter`: bremsen
- `Esc`: pausieren
- Im Garagenhinweis mit `Enter` fortfahren; in der Garage startet `Enter` die Fahrt.

## Was in dieser Vorschau enthalten ist

- Neue, eigens erzeugte Hintergrundgrafiken: Amsterdamer Grachtenhäuser und Brücke sowie Rotterdamer Hafenkräne, Skyline und Schrägseilbrücke. Zusätzlich zeigt jede Etappe früh die Architektur der Abfahrtsstadt und später ein markantes Bauwerk des nächsten Ziels. Die Stadterkennung erfolgt über Silhouetten, nicht über Ortsnamenschilder.
- Mehrere parallax bewegte Ruinen- und Industrieebenen, warmes Abendlicht und sichtbares Wasser.
- Ein gezeichneter Kombi mit sichtbaren Tuningstufen. Karosserie, Unterfahrschutz, Dachausrüstung und große profilierte Reifen verändern sich mit den Upgrades; die vollständig ausgebaute Stufe ist in den Vergleichsbildern zu sehen.
- Ein kurzer Abschnitt mit Zombies, Vorräten, Hindernissen, Kollisionseffekten und befahrbarer Sprungrampe.
- Größer dargestelltes Fahrzeug, mehr Strecke voraus und ein kompakteres HUD.
- Kombi-Abstimmung: höherer realer Topspeed, stärkerer Boost mit eigener zusätzlicher Geschwindigkeitsreserve und sichtbare Reifendrehung. Die Motorleistung beschleunigt das Auto tatsächlich; Kamera-Zoom und Streifen verstärken nur diesen Bewegungsfluss.
- Zombies rücken in der Spielwelt wirklich auf den Kombi zu (schnelle Gruppen deutlich zügiger), dazu passen Laufanimation, vorgestreckte Arme und Staub. Die Frontstoßstange löst Kollisionen und Vorräte aus, sobald sie das Objekt erreicht.
- Die handgezeichneten Zombies bewegen beim Laufen Arme und Beine im Wechsel. Nach einem Treffer können sie sich mit beiden Händen auf dem Dach festhalten; am Kombi schwingen dann Beine, Ellbogen und Kopf weiter.
- Die ersten beiden Strecken enthalten jetzt je eine Zombie-Begegnung: ein einzelner normaler Zombie in Amsterdam und eine Gruppe aus drei normalen Zombies in Rotterdam. Weitere Strecken werden erst später gestaltet.
- Auf Windows öffnet `Win+Shift+S` den Screenshot-Ausschnitt, ohne die Fahrt automatisch anzuhalten. Zum Pausieren weiter `Esc` oder die Pausentaste nutzen.

## Vergleichsbilder und Prüfung

- [Fahrtansicht mit Amsterdam-Kulisse, 105 km/h und aktivem Boost](build/pc_preview_amsterdam_tier3_in_motion_0.5.45.png)
- [Rotterdamer Hafenkulisse mit Erasmusbrug](build/pc_preview_rotterdam_port_background_0.5.45.png)
- [Echte Amsterdam-Fahrt mit Zombie am Kombi](build/pc_preview_amsterdam_zombie_contact_0.5.45.png)

Beide Ansichten wurden nach der Änderung erneut erzeugt und direkt mit den von dir angehängten Bildern verglichen: Amsterdam ist an den Giebelhäusern und der Grachtenbrücke zu erkennen, Rotterdam an Hafenkränen, Schrägseilbrücke und moderner Skyline. Das folgt der dichteren Seitenansicht des zweiten Referenzbilds. Die Szenenbilder sind eigens erstellte Spielgrafiken; die Referenzgrafiken wurden nicht übernommen. Das zweite Prüfbild ist eine ruhig gestellte späte Streckenansicht ohne HUD, damit die Hafen-Skyline klar beurteilt werden kann.

Der integrierte Godot-Lauf wurde nach dem Zusammenführen der Änderungen erfolgreich beendet. Die Vorschau lief nach dem Aufwärmen mit 60 Bildern pro Sekunde; der aktuelle gemessene Lauf zeigte 296 Draw Calls. Die Rotterdamer Ansicht ist für den Bildvergleich ruhig gestellt; das erste Bild zeigt das Auto während der tatsächlichen Fahrt.

## Noch nicht Teil dieser Vorschau

- Weitere Kampagnenwelten und Fahrzeuge sind noch nicht auf diese Grafikqualität ausgearbeitet.
- Die aktuelle Android-Debug-APK 0.5.47 hat App-Start, 11 Touchziele, gehaltenes Gas, Pause/Zurück und Kaltstart/Wiederherstellung auf dem API-36-AVD bestanden. Die aktive AVD-Fahrt erreicht nach der Kollisionsoptimierung dennoch nur 4 FPS im Median. Ein echter Telefonlauf, die Leistung auf Telefon-Hardware und ein direkter Laufzeitvergleich mit der Referenz-App stehen noch aus.
- Der Tacho ist auf 0–160 km/h programmiert; die rote 160-Endmarke ist sowohl im Android-Fahrbild als auch in der neuen PC-Fahransicht sichtbar. Der PC-Capture zeigt einen tatsächlichen Beschleunigungslauf bei 105 km/h mit aktivem Boost und Nitro-Stufe 3; nach dem Aufwärmen wurden 60 FPS gemessen.
- Die Rotterdam-Kulisse wurde in einer getrennten Aufnahme bei Streckenfortschritt 0,740 geprüft. Hafenkräne, die Erasmusbrug, Wasser und Skyline sind erkennbar. Ein veralteter 4-Pixel-pro-Meter-Wert in der Aufnahmeprobe wurde auf die aktuelle 36-Pixel-pro-Meter-Streckenskala korrigiert; die Spielstrecke selbst war davon nicht betroffen.
- Die echte Amsterdamer Begegnung wurde in der Hauptszene mit einem serienmäßigen Kombi aufgezeichnet. Die einzelne gelbe Regenjacken-Zombiefigur lief dem Auto entgegen, erreichte die Front, hielt sich am Dach fest und löste genau einen Kontakt aus. Aufnahmezustand: 34,7 m, 39,6 km/h, eine anhaftende Figur, 8,87 Zustandsverlust. Bild: `build/pc_preview_amsterdam_zombie_contact_0.5.45.png`; Protokoll: `build/pc_zombie_contact_0.5.45_20261103_012254/stdout.log`.
- **Rückmeldungs-Audit vom 3. November:** Die gebündelten Godot-Prüfungen für Serienstart, Tuning, Schaden, Ausrollen, Boost, Überschlag, Brücke, Zombieklassen und Reifen-/Panzerungsoptik bestanden. Ergebnisse und Protokolle stehen in `FEEDBACK_AUDIT_2026-11-03.md`.
- Die echte Rotterdam-Fahrt wurde auf der Brücke erneut gerendert: 1200,5 m Streckenposition, 132 km/h, angehobenes Deck (−4,20 m), Brückenobjekt sichtbar und 0 Hindernistreffer. Das Bild zeigt die Fahrt über die Fahrbahn in der Hauptszene, nicht die Brücke nur im Hintergrund: `build/pc_preview_rotterdam_erasmusbrug_drive_0.5.45_audit.png`.
- Für die aktuelle PC-Vorschau steht dein Feedback zum jüngsten kombinierten Stand noch aus. Weitere Strecken, Store-Arbeiten und das Play-Store-AAB bleiben bis zu diesem Feedback zurückgestellt; dies ist weiterhin kein fertiges Spiel.

## Neue Fahrphysik nach dem Überschlag-Feedback – 2. November 2026

- Rampensprünge sind jetzt kürzer berechnet und die Schwerkraft zieht das Fahrzeug stärker nach unten. Die Luftneigung verlangt etwas mehr Gegensteuern.
- Rotterdam hat sieben zusätzliche, abgestufte Hügelprofile, drei sichtbare Anfahrtsmarkierungen und vier zusätzliche Begegnungen mit Fässern, schneller Zombiegruppe und Wrack.
- Bleibt der Kombi auf dem Dach liegen, endet der Lauf nach 0,55 Sekunden; die kurze Frist lässt noch eine Korrektur während eines Überschlags zu.
- In der Luft und beim Aufsetzen auf nur einem Rad richtet eine sanfte Hilfe die Karosserie wieder an der Straßenneigung aus. Gegenlenken ist bei großer Schräglage verstärkt; ein Crash zählt erst bei stabilem Dachkontakt nahe der Straße.
- Der separat gezeichnete Schattenkreis unter dem Kombi wurde entfernt.
- Die Luft-Aufrichtungsprüfungen liefen erfolgreich in einer isolierten Projektkopie; der interaktive PC-Fahrabschnitt wartet weiterhin auf dein Fahrfeedback.

## Serienfahrzeug und Zombie-Haftung – 2. November 2026

- Beim ersten Start der Tuning-Probe wird der Kombi auf Serienzustand zurückgesetzt. Bestehende Kampagnenfortschritte, Münzen und Tuningstände anderer Fahrzeuge bleiben erhalten.
- In der Werkstatt bleiben die sieben Upgrade-Arten einzeln kaufbar; das kombinierte Startpaket wird während der Probe ausgeblendet. Der erste gekaufte Ausbau beendet die Serien-Zusatznachteile und wird dauerhaft gespeichert. Vor dem ersten Kauf bleibt der Kombi auch nach einem Neustart im Serien-Test.
- Der frühere Serien-Test mit gesperrten Werkstattkäufen bleibt nur als interne Balanceprüfung erhalten und wird beim normalen Spielstart nicht mehr aktiviert.
- Der Kombi hat im Serienzustand 72 km/h Höchstgeschwindigkeit. Jede Motorstufe erhöht die Grenze um 21 km/h; voll getunt sind es 135 km/h ohne Boost und maximal 160 km/h mit Boost.
- Im Serien-Test verbraucht der Wagen 45 Prozent mehr Sprit und nimmt bei Treffern 65 Prozent mehr Schaden. Ein Zombie-Kontakt kostet mindestens sechs Zustandsprozent.
- Ein Teil der Zombies wird nach einem Frontkontakt sichtbar mit genau zwei Klauenhänden am Dach hängen, das Auto abbremsen und während des Festhaltens weiter beschädigen. Andere lassen sofort los. Stärke und Haftdauer hängen von Zombieklasse und stabiler Profilziehung ab.
- Die digitale Geschwindigkeitsbox wurde durch eine analoge 0–160-km/h-Tachoscheibe ersetzt. Tank und Karosseriezustand liegen im selben Instrumentenfeld; eine rote Tanklampe blinkt bei nahezu leerem Tank.
- Kollisionen lösen weiter nur einmal Belohnung und Trefferreaktion aus; nicht festhängende Mitglieder einer Gruppe werden getrennt weggeschleudert dargestellt.
- Isolierte Godot-Prüfungen bestanden: reale Speedcaps (72 / 135 / 160 km/h), echte Boostwirkung, Upgradeeffekte, tatsächlicher Zombie-Frontkontakt mit einem haftenden Zombie, additive Geschwindigkeitsbremsung, Zustandsverlust durch Festhalten, frühes Loslassen, unterschiedliche Haftprofile, Zombies ohne Griff sowie der einmalige Serienstart mit unveränderten gespeicherten Upgrade-Stufen.
- Die automatische PC-Bildaufnahme für die visuelle HUD-Kontrolle lief in der isolierten Renderkopie 90 Sekunden ohne Ausgabe und wurde abgebrochen. Die Funktionstests waren davon nicht betroffen; die sichtbare Beurteilung der neuen Tachoscheibe steht noch aus.

## Rotterdam-Fahrprüfung und Tacho – 2. November 2026

- Die Rotterdamer Route hat vier echte, in der Fahrbahn-Höhe und damit auch in der Kollision enthaltene Rampen. Vor jeder steht eine gut sichtbare Anfahrtsmarkierung. Anfahrtstempo und Luftneigung entscheiden über Sprung und Landung.
- Die Brückenpassage ist Teil der befahrbaren Strecke: Der Kombi fährt über eine ansteigende Zufahrt auf das über dem Wasser liegende Deck und auf der anderen Seite wieder hinunter. Zeichnung und Kollisionsform beziehen ihre Höhe aus demselben Streckenprofil.
- Direkt an der Straße steht eine eigene, gezeichnete Erasmusbrug-Ansicht mit asymmetrischem „Schwanenhals“-Pylon, mehreren auffächernden Tragseilen, durchgehendem Träger, wiederholten Unterzügen und einem durchgehenden Geländer. Sie folgt den dunklen Konturen und gesetzten Material-Highlights der Fahrzeuggrafik; Orts- und Straßenschilder werden nicht ergänzt.
- Ein Fass nach der Brücke zwingt zum frühen Abbremsen und sauberen Aufsetzen.
- Der manuelle Tacho ist nun ausdrücklich auf 0–160 km/h skaliert. Die Endmarke „160“ ist größer und rot hervorgehoben; die Nadel verwendet dieselbe Obergrenze.
- Die PC-Vorschau startet über `Start_Zombie_Escape_Europe_PC_Preview.bat`. Auf dem geöffneten Streckenabschnitt Rotterdam auswählen beziehungsweise fortsetzen. Gas und Bremse steuern die Anfahrt, links/rechts gleichen den Wagen während des Sprungs aus.

## Serien-Kombi und durchgehende Erasmusbrücke – 2. November 2026

- Der nächste normale Start öffnet die Werkstatt mit einem serienmäßigen Kombi. Auf der einzelnen Werkstattseite bleiben Motor, Reifen, Tank, Panzerung und Nitro direkt kaufbar; „MEHR TEILE“ wurde entfernt. Vorhandene Speicherstände werden beibehalten.
- Die Prüfung nutzt weiter den realen Serienverbrauch und die höhere Serien-Trefferanfälligkeit. Mit dem ersten Kauf wird der Tuning-Test beendet, damit das gekaufte Upgrade sofort seine reguläre Leistung zeigt.
- Die Brücke hat jetzt mehrere Abspannseile nahe am Schwanenhals-Pylon, einen längeren durchgehenden Straßenrand und wiederholte Stahl-Unterzüge über die gesamte Flussquerung. Die zuvor einzelne, weit gespannte gerissene Abspannung wurde entfernt.
- Orts- und Zielschilder auf der Strecke sind entfernt. Versorgungspunkte werden durch einen unbeschrifteten Lichtbogen markiert; Städtenamen und Ziele bleiben in der HUD-Anzeige, die Städte selbst über ihre Hintergrundkulissen.
- Die Vorschau bleibt auf PC und Rotterdam beschränkt. Für die neuen Änderungen wird ein gebündelter Godot-Meilensteintest ausgeführt; die Android-Neuinstallation erfolgt nach erfolgreichem PC-Test.

## Kombi-Proportionen und Brückendurchfahrt – 2. November 2026

- Die Kombi-Karosserie ist etwas höher gezeichnet, ohne die Breite oder Achspositionen zu ändern. Die Serienreifen sind kleiner (16 px Radius); Reifen-Upgrades vergrößern sie weiterhin, Panzerung und andere Tunings nicht.
- Die sichtbare Nitroflasche auf dem Dach wurde entfernt. Nitro bleibt als kaufbares Upgrade und als Straßenfund im Spiel.
- Die Erasmusbrücke wurde beim Überfahren der Mitte zuvor fälschlich als Hindernis verarbeitet und danach ausgeblendet. Sie bleibt jetzt während der Durchfahrt sichtbar und verursacht dort keinen Hindernisschaden.
- Godot-Prüfungen bestanden: Panzerungsstufen mit unveränderter Serienbereifung sowie die Rotterdam-Strecke mit fortbestehendem Brückenobjekt am Mittelpunkt. Bildübersicht: `build/kombi_proportion_review_2026-11-02.png`.
- Die vorhandene PC-Vorschau startet weiterhin über `Start_Zombie_Escape_Europe_PC_Preview.bat`.

## Nitro, Reifen und Ausrollen – 2. November 2026

- Ein Kombi ohne Tuning startet mit leerem Nitro-System. Der Boost bleibt in Fahrt und HUD gesperrt, bis das Nitro-Upgrade in der Fahrzeug-Werkstatt gekauft wurde. Nitrokanister und Kontrollpunkte füllen den Vorrat erst nach dem Kauf.
- Der Nitro-Kauf schaltet Boost frei und erweitert den Vorrat; sichtbare Nitroflaschen erscheinen am Dachträger. Der manuelle Tacho ist im HUD-Code auf 0–160 km/h skaliert und hebt die rote 160-Endmarke hervor.
- Die Radposition bleibt von Panzerung und sonstigem Tuning unabhängig. Größe und Geländereifen-Grafik ändern sich nur mit dem Reifen-Upgrade; der Serienreifen sitzt etwas tiefer, damit er näher am Boden steht.
- Wenn Tank oder Karosserie leer sind, bekommt der Motor keine Kraft mehr. Der Kombi rollt mit kontrollierter Verzögerung aus; das Ergebnisfenster erscheint erst nach mindestens 2,4 Sekunden und nahezu Stillstand, spätestens nach 12 Sekunden. Ein Überschlag beendet die Fahrt weiterhin sofort.
- Zombies halten bei niedrigem Tempo länger fest. Während sie am Dach hängen, bremsen sie den Wagen, erhöhen laufenden Treibstoffverbrauch und verursachen sichtbaren Karosserieschaden. Hindernis-, Straßen- und Zombieschaden sinkt mit jeder Panzerungsstufe; Serie nimmt mehr Schaden.
- Der nächste Start führt eine einmalige Rücksetzung auf den serienmäßigen Kombi aus, auch wenn ein älterer Spielstand eine frühere Tuningprobe schon als gesehen markiert. Kampagnenfortschritt, Münzen und Ausbauten anderer Fahrzeuge bleiben gespeichert.
- Für diese PC-Fassung wurde noch kein neuer Android-APK gebaut; das neueste vorhandene Debug-APK ist 0.5.41 und enthält diese Änderungen nicht.

## Zombiebewegung und längerer Kombi – 2. November 2026

- Die Laufpose arbeitet nun mit wechselnden Schritten, Armschwung, leichter Körperneigung und Bewegungsspuren. Die Bewegung passt zum Heranstürmen, statt dass die Zombies am Platz laufen.
- Festgeklammerte Zombies zeichnen zwei greifende Hände am Dach und bewegen Ellbogen, Beine, Füße sowie den Kopf. Die Animation läuft über das normale Zeichnen des Fahrzeugs und erzeugt keine zusätzlichen Physikkörper.
- Die Kombi-Karosserie wird mit beibehaltener Bildproportion gezeichnet: 226 px Breite aus der 2:1-Vorlage statt der alten, gestauchten 202 × 150 px-Fläche. Achsen, Radkästen, Kollisionsbreite und Fahrzeugkontakt wurden auf die längere Silhouette abgestimmt; Panzerung verändert die Serienreifen weiterhin nicht.
- In Amsterdam ist nur noch die einzelne Einstiegsbegegnung bei 54 m platziert. In Rotterdam ist die eine Zombiegruppe bei 965 m; sie besteht aus drei normalen Zombies. Die übrigen Begegnungen und Dekorationen dieser beiden Strecken bleiben erhalten.
- Godot-Prüfungen bestanden: `ZOMBIE_VARIANTS_OK`, `ZOMBIE_LATCH_OK`, `ZOMBIE_COLLISION_ONCE_OK` und `KOMBI_ARMOR_VISUAL_PROGRESSION_OK`. Die Panzerungsübersicht liegt unter `build/armor_visual_review_0.5.43.png`.
- Die aktualisierte PC-Vorschau startet mit `Start_Zombie_Escape_Europe_PC_Preview.bat`. Android-APK und Store-Upload wurden für diesen Vorschau-Schritt nicht gebaut.

## Fahrgefühl und Action – Meilenstein 1 – 3. November 2026

- Neue Vorschau: `scenes/driving_test.tscn`; Direktstart über `tools/PC-Teststarts/Start_Fahrtest_PC.bat`. Der Startschalter lädt direkt in den Testabschnitt und überspringt den normalen Kampagnenstart.
- Der 900-m-Abschnitt wurde mit dem serienmäßigen Kombi und Nitro I für den Boost-Test gefahren. Ergebnisse: 45,47 s, sechs Treffer, eine Landung; Beschleunigen/Ausrollen/Bremsen und Boost reagierten getrennt messbar.
- Echte Überschneidung zwischen Fahrzeug und Gegner/Hindernis löst den Kontakt aus. Leichte und schwere Objekte kosten unterschiedlich viel Schwung; Reifen- und Panzerungsstufen wirken auf den passenden Teil der Kollision.
- Die HUD-Überlappung im ersten Bildlauf wurde korrigiert. Auf dem Vorschaubild sind der kleinere Nitrobehälter am hinteren Türbereich und die längere Kombi-Silhouette erkennbar.
- Sichtprüfung in der Godot-Vorschau bestätigt; die vollständige Fahrt wurde automatisiert über Godot-Tastenereignisse geprüft. Eine durchgehend gehaltene physische Taste ließ sich mit dem Desktop-Bedienwerkzeug nicht zuverlässig senden.
- M1 ist abgeschlossen und wartet auf Fahrfeedback. Die Amsterdam-Kulisse und die spätere Waffe samt Fahrzeug-Fortschrittswechsel bleiben ungebaut, bis dieser Abschnitt bestätigt und die nächsten Meilensteine freigegeben sind.



## Amsterdam-Kulisse, Fahrbahn und Zombie-Griff – 3. November 2026

- Die getrennte industrielle Fernbild-Leiste wurde entfernt. Die Amsterdam-, Übergangs- und Rotterdam-Panoramen schneiden jetzt ihre transparenten Ränder weg und enden an der tatsächlichen Straßenhöhe beim Fahrzeug; damit liegen sie nicht mehr als schwebende Streifen übereinander.
- Sämtliche Bewegungs- und Nitro-Geschwindigkeitsstreifen am Fahrzeug und im Hintergrund wurden entfernt. Die Auspuffflamme bleibt als direkt am Auspuff sitzendes Nitro-Feedback erhalten.
- Zombies lösen sich oberhalb von 100 km/h sofort vom Dach. Schon darunter verkürzt steigendes Tempo die Haltezeit deutlich; stärkere Varianten halten bei niedrigerem Tempo weiterhin etwas länger.
- Amsterdam hat zusätzliche, mit Straßenkollision und Fahrbahnzeichnung gekoppelte Rampen erhalten. Fahrbahnmarkierungen sind dichter, dazu kommen dezente Asphaltflicken und Risse.
- Godot wurde nach diesen Änderungen nicht gestartet; die Anpassungen sind daher noch nicht visuell oder durch eine Fahrt bestätigt.

## Sprungkamera und Amsterdam-Action – 3. November 2026

- Die Kulisse wird auch bei vertikaler Kamerabewegung und Zoomänderung neu gezeichnet. Beim Absprung bleibt das Stadtpanorama an der Fahrbahn ausgerichtet, statt einen alten Bildstand oder die darunterliegende Kulisse freizugeben.
- Die Kamera folgt dem Sprung nur teilweise nach oben. Dadurch bleibt die Landefläche länger im Bild und die Strecke voraus lesbar.
- Amsterdam nutzt jetzt eine fest gestaltete Folge über die ganze Route: Zombiegruppen, Fässer und Wracks, Belohnungen und Reparaturpausen wechseln sich mit mehreren Rampen ab. Ein später Konvoi bildet einen eigenen Streckenhöhepunkt.
- Die übrigen Welten und die gespeicherten Upgrades bleiben davon unberührt.
- Godot wurde für diese Änderungen nicht gestartet; Sprungbild, Landungen und Begegnungsabstände sind noch nicht im Spiel getestet.

## Amsterdam ohne Bildwechsel und mit Sprungschanze – 3. November 2026

- Das Amsterdam-Kanalbild bleibt nun über die ganze erste Welt aktiv; der Übergang und das Rotterdam-Bild werden dort nicht mehr eingeblendet. Für Amsterdam sind außerdem die wiederholten generischen Stadt- und Hügelstreifen abgeschaltet, damit beim Springen kein zweites unteres Hintergrundbild durchscheint.
- Die erhöhte Fahrbahn bei 1.046 m wurde zu einer deutlich höheren, gebauten Sprungschanze ausgebaut. Ihre Rampe folgt weiterhin derselben Höhenkurve wie Straßenzeichnung und Kollision.
- Vor der Schanze und in weiteren Streckenabschnitten kamen zusätzliche Fässer als kurze Hindernisfolgen hinzu. Nach dem Sprung liegt die nächste Zombiegruppe mit mehr Abstand hinter der Landung.
- Godot wurde für diesen Schritt nicht gestartet. Bildlage, Rampenfahrt und Hindernisabstände müssen nach einem Neustart der PC-Vorschau noch im Spiel geprüft werden.

## Mehr Zombiehalt, Straßenschäden und sichtbare Schanze – 3. November 2026

- Zombies bleiben bei niedriger und mittlerer Geschwindigkeit länger am Kombi und verursachen während des Festhaltens mehr Schaden. Mit zunehmendem Tempo lösen sie sich weiterhin schneller; ab 100 km/h gilt die vorhandene automatische Ablösung.
- Die Amsterdam-Fahrbahn enthält jetzt 14 flache, aber physisch modellierte Schlaglöcher. Die gleiche Höhenkurve speist Fahrbahnzeichnung und Straßenkollision; gezeichnete ausgefranste Ränder und dunkle Vertiefungen machen sie auf der Straße erkennbar.
- Fünf zusätzliche Fässer ergänzen die Folge aus Gegnern, Belohnungen und bestehenden Wracks.
- Die Sprungschanze bleibt nach dem Auslösen sichtbar, solange sie in Kameranähe ist. Kontrastkante und breitere Warnmarkierungen heben die Rampenfläche klarer von der Straße ab.
- Godot wurde für diesen Arbeitsschritt nicht gestartet. Fahrgefühl, Sichtbarkeit und Hindernisabstände müssen in der PC-Vorschau geprüft werden.

## Rotterdam-Panorama, Streckenprofil und Waffenfreigabe – 3. November 2026

- Das Rotterdam-Panorama wird am letzten sichtbaren Wasserpixel abgeschnitten. Der transparente PNG-Rand unter dem Wasser wird nicht mehr bis unter die Straße skaliert; der Hintergrund richtet sich nach der tatsächlichen Bildschirmposition der Fahrbahn.
- Die Rotterdam-Strecke erhält zusätzliche kurze Höhenzüge sowie weitere Fässer und Wracks. Straßenzeichnung und Kollision verwenden weiter dasselbe Höhenprofil.
- In der isolierten Debug-Werkstatt kann „Serienfahrzeug testen“ den Kombi vorübergehend auf Serie setzen. „Getuntes Auto zurück“ stellt den gespeicherten Test-Ausbau wieder her; der normale Spielstand bleibt durch den separaten Vorschau-Spielstand geschützt.
- Die Haubenpistole wird erst in Rotterdam nach vollem Ausbau von Motor, Reifen, Tank, Panzerung und Nitro kaufbar. Sie feuert automatisch und benötigt je nach Zombieklasse unterschiedlich viele Treffer. Der Ausbau bleibt für die drei ersten Welten aktiv; nach Antwerpen wird der Lieferwagen freigeschaltet.
- Die Werkstattansicht des laufenden alten Vorschauprozesses bestätigte den Serien-Umschalter und das Pistolenfeld. Die aktuell offene Fahrt verwendet noch den vorigen Programmstand. Der geänderte Panorama-Zuschnitt und die Pistole über drei Welten warten auf einen Neustart der Vorschau; nach den letzten Skriptänderungen wurde noch keine neue Godot-Prüfung ausgeführt.
- Ordnergröße bei der Sichtung: rund 2,67 GB und damit unter dem gewünschten 10-GB-Rahmen. In diesem Schritt wurden keine Dateien gelöscht.

## Hintergrund, Fahrzeuglage und sichtbarer Schaden – 3. November 2026

- Amsterdam zeigt jetzt den vollständigen unteren Wasserbereich des Kanalbilds. Unter dem Panorama wird das Wasser bis zur tatsächlichen Straßenkontur über die ganze Bildschirmbreite ergänzt; zurückhaltende Wellen und Lichtreflexe ersetzen die harte, einfarbige Fläche.
- In der Luft greift die automatische Lagekorrektur auch bei einer starken Schräglage, einschließlich des fast senkrechten Zustands aus dem Screenshot. Bleibt das Auto tatsächlich auf dem Dach liegen, wird die Rund weiterhin beendet.
- Karosserieschäden bauen sich früher sichtbar auf: kleine Dellen erscheinen ab etwa 16 % Schaden, weitere Verformungen an Tür, Kotflügel und Motorhaube kommen mit steigendem Schaden hinzu.
- Vergleich mit dem bereitgestellten Earn-to-Die-2-Bild: Dort füllen befahrbare Plattformen, Rampen und Hindernisse den Vordergrund, während unser Screenshot vor allem eine einzelne statische Stadtkulisse und die lange Straßenfläche zeigt. Die aktuelle Änderung verbessert die lesbare Straßenkante und das Sprungverhalten; die deutliche Dichte an befahrbaren Konstruktionen und die Vielfalt gezeichneter Umgebungsassets bleiben die größten grafischen Unterschiede.
- Godot 4.7.2 hat das Projekt nach diesen Änderungen im Headless-Editor ohne gemeldete Skriptfehler geladen. Der Godot-Editor war anschließend bereits geöffnet; deshalb wurde keine zweite Live-Fahrt gestartet. Der nächste Schritt ist eine Sichtprüfung der Rampe und Wasserlinie mit `tools/PC-Teststarts/Start_Amsterdam_Gameplay_Preview_PC.bat`.

## Spielumfang auf Amsterdam und Rotterdam begrenzt – 3. November 2026

- Im Spiel sind nur Amsterdam und Rotterdam auswählbar und startbar. Nach Rotterdam wird keine weitere Strecke freigeschaltet; die Karte zeigt zwei Etappen und nennt weitere Strecken als späteren Ausbau.
- Bereits gespeicherte Münzen, Fahrzeugausbauten, Fahrzeuge und Fortschrittsdaten bleiben erhalten. Ältere Weltdefinitionen bleiben im Projektarchiv für spätere Streckenarbeit und Save-Kompatibilität, sind aber im aktuellen Spiel nicht erreichbar.
- Funkdialoge, Story-Funkmeldungen, Funkarchiv-Schaltflächen und die zugehörigen Benachrichtigungen wurden aus dem aktuellen Spielablauf entfernt. Bereits gespeicherte Story-Daten werden nicht gelöscht.
- Godot 4.7.2 hat das Projekt nach den zusammengefassten Änderungen im Headless-Editor ohne gemeldete Skriptfehler geladen. Karte und Abschlussbildschirm wurden noch nicht in einer laufenden PC-Fahrt visuell geprüft.

## Stadtbilder, Pistole und befahrbare Bauwerke – 3. November 2026

- Vorher verwendete Amsterdam und Rotterdam je ein einziges Panorama. Die Haubenpistole war nur eine einfache Polygonzeichnung direkt im Fahrzeugcode; eine separate Pistolen-Grafik gab es nicht.
- Neu erzeugte und eingebundene Assets: `assets/amsterdam_canal_panorama_0.8.0.png`, `assets/amsterdam_canal_warehouse_panorama_0.8.0.png`, `assets/rotterdam_harbor_panorama_0.8.0.png`, `assets/rotterdam_shipyard_panorama_0.8.0.png` sowie die transparente `assets/kombi_hood_pistol_0.8.0.png`.
- Pro Stadt wechseln jetzt zwei eigens gezeichnete, thematisch passende Panoramen mit kurzem Überblenden. Beide werden an derselben Straßen-/Wasserkante ausgerichtet; beim Sprung wird dadurch keine zweite Kulissenleiste darunter freigelegt und die Stadt wechselt nicht vorzeitig.
- Amsterdam hat bei 350–472 m eine angehobene Kanalbrücke; Rotterdam bei 628–740 m eine befahrbare Container-Verladerampe. Höhenprofil, sichtbare Fahrbahn und Straßenkollision verwenden dieselbe Kurve. Unterzüge, Stützen und Deckplatten machen die Konstruktionen im Spiel erkennbar.
- Die Pistole erscheint nach dem Kauf als eigene Illustration auf der Motorhaube und als Bild in der Werkstattkategorie. Freischaltung, Preis und automatisches Schießen bleiben an die bestehende Upgrade-Logik gebunden: in Rotterdam nach Motor, Reifen, Tank, Panzerung und Nitro auf Maximalstufe.
- Beim Kombi senken nur Reifen-Upgrades die sichtbaren Räder schrittweise etwas ab; Serie und Panzerungsstufen behalten ihre bisherige Radposition. Die Federzeichnung verlängert sich passend.
- Mipmaps wurden zusätzlich für die bisher ungefilterte höchste Kombi-Karosserie und den laufenden Normalzombie aktiviert, damit stark verkleinerte Zeichnungen weniger flimmern.
- Spielstanddateien und gekaufte Ausbauten wurden nicht verändert. Godot wurde nach diesen Änderungen nicht gestartet; es gab daher noch keine Sichtprüfung der neuen Panoramen, Pistole oder Streckenbauwerke im laufenden Spiel. Beim nächsten Öffnen importiert Godot die neuen PNGs.
- HUD und Streckenzeichnung verwenden jetzt ebenfalls explizit lineare Texturfilter mit Mipmaps für Fahrzeug-, Gegner- und Vorschaubilder.

## Werkstatt- und Grafiküberarbeitung – 3. November 2026

- Die Pistole ist jetzt in der Werkstatt als sechste Kategorie am Kombi sichtbar, auch wenn sie noch gesperrt ist. Die Vorschau verwendet die vorhandene eigene Pistolenillustration; Schloss, Ort und Freischaltfortschritt sind erkennbar.
- Die Freischaltung ist unverändert: Rotterdam auswählen, den Kombi verwenden und Motor, Reifen, Tank, Panzerung sowie Nitro vollständig ausbauen. Danach kostet die Haubenpistole 650 Münzen. Käufe, Spielstände und Ausbauten wurden nicht zurückgesetzt.
- Neu erzeugte, eigene Werkstattgrafiken für Amsterdam und Rotterdam liegen unter `assets/amsterdam_workshop_background_1.0.0.png` und `assets/rotterdam_workshop_background_1.0.0.png`. Die Kulisse folgt der ausgewählten Stadt und liegt hinter Fahrzeug und Werkstattoberfläche.
- Die Werkstattkarten und Schaltflächen haben eine klarere Tiefenwirkung, kühlere Türkisakzente und besser getrennte Status-/Vorschauflächen erhalten.
- Die vier Amsterdam-/Rotterdam-Panoramen zeigen jetzt jeweils die gesamte Bildhöhe bis zum Straßenanschluss. Aktive Stadt-, Fahrzeug- und Zombiegrafiken verwenden Mipmaps, damit sie beim Verkleinern weniger flimmern und pixelig wirken.
- Keine Spiellogik außer der erklärenden Pistolen-Sperrmeldung wurde geändert; die Freischaltbedingungen bleiben gleich.
- Godot wurde für diese Änderung nicht gestartet. Die neue Werkstattansicht, die Texturimporte und der untere Panoramaanschluss brauchen deshalb noch eine Sichtprüfung beim nächsten Öffnen der PC-Vorschau.

## Rotterdam-Abschnitt mit wechselndem Spannungsbogen – 3. November 2026

- Der Einstieg bis zur Erasmusbrücke nutzt jetzt zwei abwechselnde Ereignisfolgen. Bei einem erneuten Versuch ändern sich Gegnergruppen, Wracks, Versorgung und Hindernisrhythmus; der spätere Brücken- und Hafenverlauf bleibt erhalten.
- Die erste Entscheidung ist jetzt räumlich gebaut: ab etwa 58 km/h kann der Kombi auf ein erhöhtes, einseitig befahrbares Containerdeck springen. Wer langsamer ankommt, bleibt auf der unteren Straße und muss die Sperre tatsächlich durchbrechen. Die zwei Versuchsvarianten verschieben Anlauf und Deck, damit sich der Einstieg verändert.
- Das erhöhte Deck hat eigene Physikkollision, sichtbare Stahlplatten, Leitkanten, Stützen und eine markierte Landestelle. Ein Münzversteck liegt nur auf dem oberen Weg. Der Durchbruch unten reagiert auf tatsächliche Karosserieüberlappung und zahlt eine kleinere Belohnung aus.
- Treffer mit Fässern, Wracks und Sperren verlieren je nach Gewicht und Tempo unterschiedlich viel Schwung. Zerstörbare Treffer zeigen jetzt Metall-/Holztrümmer, einen kurzen Karosseriestups, Kameraruck und den vorhandenen Aufprallsound; leichteres Material bleibt optisch und spielerisch schwächer als ein schweres Wrack.
- Die Ereignisfolge enthält kurze Zombiegruppen, leichte Fässer, schwerere Wracks, Treibstoff und Reparaturkisten, mehrere Rampen sowie Trümmer vor dem Brückenabschnitt. Ein zusätzlicher automatisch erzeugter Rotterdam-Straßensperren-Treffer wurde entfernt, damit keine doppelte Begegnung über der handgebauten Folge liegt.
- Spielstände, Münzen und Upgrades wurden nicht verändert. Die bestehende Vorschau startet über `Start_Rotterdam_Gameplay_Preview_PC.bat` mit ihrem getrennten Testprofil.
- Diese neue Streckenfassung wurde nach den Änderungen noch nicht in Godot oder mit echten Eingaben geprüft. Die vorherige Vorschau ließ sich in dieser Umgebung nur im Headless-Editor laden; ein sichtbares Spielfenster wurde dort vom Dummy-Texttreiber verhindert. Das obere Landen, das Durchbrechen unten und die Trümmerwirkung müssen deshalb noch direkt in der PC-Vorschau bestätigt werden.

## Haubenpistole montiert und Referenzvergleich – 3. November 2026

- Die Haubenpistole hatte in der Fahrzeugzeichnung einen sichtbaren Abstand zur Motorhaube. Der Bildausschnitt schnitt den unteren Teil ihres Standfußes ab; außerdem lag die Feuerlinie etwas oberhalb des sichtbaren Laufs.
- Der vollständige Montagefuß wird nun mitgezeichnet. Eine verschraubte Aufnahme liegt auf der Motorhaube, die Pistole sitzt darauf, und der sichtbare Schuss startet am Lauf. Die Werkstattkarte nutzt denselben vollständigen Bildausschnitt.
- Der Projektvergleich zeigt weiterhin die größten Ausbauchancen bei befahrbaren Ebenen/Verzweigungen, dichterer und variabler Vordergrundkulisse, klaren physischen Treffern mit stärkerer Reaktion und stärker sichtbarer Fahrzeugzerstörung. Amsterdam und Rotterdam sind die aktuell spielbaren Etappen; ein dritter Abschnitt samt neuem Basisfahrzeug fehlt noch für den geplanten 3-Etappen-Fortschritt.
- Godot 4.7.2 hat das Projekt nach der Montageänderung im Headless-Editor ohne gemeldete Skriptfehler geladen. Die sichtbare Befestigung im laufenden PC-Spiel ist noch nicht bestätigt.

## Reale Rotterdam-Wegwahl und Trefferfeedback – 3. November 2026

- Der vorherige Tempovergleich an der Rampe wurde zu einer räumlichen Wegwahl ausgebaut. Eine Sprungfahrt ab etwa 58 km/h führt auf eine eigene, einseitig kollidierende Containerplattform über der unteren Straße. Langsame Fahrten bleiben unten und treffen eine physische Sperre.
- Bei beiden wechselnden Anläufen beginnt das obere Deck 10 m vor der Rampe. Die berechnete Flugkurve zielt auf eine Landung mit genügend Plattform unter dem Kombi; das Deck bleibt danach über den Zombieabschnitt befahrbar und endet in einem klar markierten Drop zur unteren Straße.
- Die obere Route bietet einen Münzbonus und ein räumlich geprüftes Versteck. Die untere Route belohnt den tatsächlichen Durchbruch, verliert aber Schwung und Fahrzeugzustand. Bei der alternierenden Variante liegt zusätzlich eine Münz-Erholung nach dem Hindernis.
- Schwere und leichte Hindernistreffer unterscheiden sich durch Widerstand und Tempo. Treffer lassen nun gezeichnete Trümmer fliegen und geben dem Kombi einen dosierten Aufwärtsruck; Kamerabewegung und Sound werden erst bei tatsächlichem Kontakt ausgelöst.
- Für das Containerdeck wurde eine eigene transparente Seitenansicht-Illustration erstellt und als `assets/rotterdam_container_overpass_1.0.0.png` eingebunden. Die Grafik liegt hinter der unteren Fahrbahn; die Fahrfläche darüber stimmt mit der separaten Deckkollision überein.
- Spielstände und gekaufte Upgrades blieben unberührt. Godot 4.7.2 hat die Rotterdam-Werkstatt und den Start der Fahrt sichtbar geladen; im Laufzeitprotokoll gab es nach dem PNG-Ladefix keine Skriptfehler. Die Wegwahl oben/unten wurde in diesem Durchlauf nicht bis zur Rampe gefahren: Die UI-Automation kann die Gas-Taste nur kurz antippen, nicht halten. Die PC-Vorschau nutzt jetzt einen lokalen Startschalter und ein getrenntes Profil; manuell starten über `Start_Rotterdam_Gameplay_Preview_PC.bat`.

## Amsterdam-Referenzbild: Kulisse und Uferanschluss – 4. November 2026

- Die neue Amsterdam-Panoramagrafik greift die helle Tagesstimmung, Giebelhäuser, Bäume und Kanalbrücke des Nutzerbilds auf; Straße, Zombies, Rampe und Bedienoberfläche bleiben separate spielbare Bestandteile.
- Die Panoramaansicht behält ihr Seitenverhältnis und endet am Ufer neben der Fahrbahn. Ein ergänztes Kanalstück folgt dem tatsächlichen Straßenprofil bis zur gemauerten Uferkante, damit an Hügeln und Sprüngen keine gerade abgeschnittene Bildkante oder ein leerer Streifen sichtbar wird.
- Die Ufermauer begrenzt ihre Bildschirmgeometrie jetzt vor der unteren Fensterkante. Das verhindert die zuvor protokollierten ungültigen Polygon-Triangulierungen, wenn die kameraangepasste Straße außerhalb des sichtbaren Bereichs liegt.
- Die vorhandene Folge aus Holzabsperrung, Gegnern, Fässern, Rampenanlauf und befahrbarer oberer Brücke bleibt erhalten und orientiert sich in Material und Form am Referenzbild. Keine Spielstände oder gekauften Ausbauten wurden verändert.
- Die neue Kulissen-/Uferanpassung ist bislang nur am Quellcode geprüft; eine sichtbare Fahrt mit echten Eingaben und ein Screenshotvergleich nach dieser Änderung stehen noch aus.

### Bildvorlage für Straße, Bake und Rampe – 4. November 2026

- Die neue, eigenständige Tageskulisse `assets/amsterdam_gameplay_panorama_1.2.0.png` ersetzt in Amsterdam die dunklere Panorama-Fassung. Sie übernimmt die Bildrichtung der Nutzerreferenz – helle Grachtenhäuser, Bäume, blaue Wasserfläche und eine steinerne Bogenbrücke – ohne deren Bildschirmtext, Fahrzeug oder Vordergrund zu kopieren. Die Kulisse bleibt separat von Fahrbahn und Gameplay.
- Das Pflaster auf der befahrbaren Straße besteht jetzt aus vier statt drei versetzten Steinreihen und greift die grauen Ufersteine der Vorlage auf. Die Ziegel-Ufermauer bleibt darunter als eigene, sichtbare Fahrbahnstruktur.
- Die zerstörbare Holzsperre wurde höher und lesbarer gebaut: breite rot-helle Warnbohle, A-Rahmen, Querstreben, Bolzen und sichtbare Holzspuren. Ihre bestehende Kollisionsfläche und zerstörbare Logik bleiben erhalten.
- Der Anstieg zur Holzrampe ist nun deutlich steiler (92 statt 58 Pixel Höhengewinn) und folgt weiterhin derselben Straßenkurve wie die Radkollision. Die untere Strecke fällt anschließend länger und kontrollierter auf die normale Höhe zurück.
- Godot 4.7.2 hat die geänderte Amsterdam-Szene sichtbar geöffnet. Mit realen Klicks auf die Gas-Taste wurde bis etwa 500 m gefahren; dabei waren die neue Kulisse, Pflasterkante, Rampenanlauf, Brücke und eine Gegnerbegegnung sichtbar. Die neue Panoramaressource wurde geladen. Eine vollständige 45–60-Sekunden-Fahrt samt sauberer Rampenlandung und beiden Routen wurde in diesem Durchlauf nicht belegt.
- Es wurde ausschließlich das getrennte PC-Vorschauprofil verwendet; der persönliche Spielstand und bezahlte Ausbauten blieben unangetastet.
- Die vom Bildgenerator außerhalb des Projektordners abgelegte Datei wurde nach SHA-256-Abgleich mit der Projektkopie entfernt. Die verwendete Grafik liegt unter `assets/` im Spielprojekt.

### Amsterdam-Referenz: lesbarer Kicker und Taps – 4. November 2026

- Der Rampenanlauf wurde auf einen langen flachen Anstieg von 407 bis 439 m und einen klaren Holz-Kicker von 439 bis 445 m umgestellt. Die Spitze endet auf Höhe des oberen Brückendecks; sichtbare Rampenoberfläche und Straßen-/Radkollision beziehen sich weiterhin auf dasselbe `height_at`-Profil. Die Vorlaufmarkierungen liegen jetzt näher an der Rampe.
- Das Serienprofil hat in der Vorschau weiterhin ausschließlich Stufe 0, insbesondere `nitro = 0`; HUD und T-Umschalter nennen Nitro im Serienprofil jetzt korrekt gesperrt.
- Ein kurzer Mausklick/Tipp auf Gas, Bremse oder Nitro hinterlässt jetzt einen kurzen Eingabeimpuls, damit ein Tipp nicht zwischen zwei Physiktakten verloren geht. Gedrückt halten funktioniert weiterhin über dieselben Touch-Buttons.
- Sichtbare Startprüfung: Die neue helle Amsterdam-Kulisse, die Bogenbrücke, die gemauerte Fahrbahnstruktur, die HUD-Anordnung und die erste Zombie-/Barrierenbegegnung wurden im PC-Fenster geladen. In dieser Prüfung führten kurze Maus-Taps auf Gas noch nicht zu messbarer Strecke; der Eingabeimpuls wurde danach ergänzt und noch nicht durch eine neue sichtbare Fahrt bestätigt. Die volle Strecke, die Rampe im Nahbild, obere Landung und manuelle Balance bleiben offen.
- Der Headless-Editor-Ladelauf von Godot 4.7.2 endete nach den Skriptänderungen mit Exitcode 0 und ohne gemeldeten Skriptfehler. Der separate automatisierte Strecken-Probelauf wurde von diesem CLI-Aufruf nicht gestartet und zählt daher nicht als bestandener Gameplay-Test.
- Nur das isolierte PC-Vorschauprofil wurde gestartet; persönliche Speicherstände und gekaufte Upgrades wurden nicht verändert.

### Amsterdam-Referenz: breitere Brückenrampe – 4. November 2026

- Die bisherige Rampenspitze stieg auf den letzten sechs Metern um rund 86 Pixel an. Im Physiklauf richtete sich der Wagen dort stark auf und verlor vor der Weggabelung fast den gesamten Vortrieb.
- Der Holzkicker beginnt nun bei 429 m und führt mit einem breiteren, weicheren Profil bis zur Brückendeckhöhe bei 445 m. Gezeichnete Rampe, Höhenlinie und Radkollision verwenden dasselbe Profil.
- Der isolierte Godot-PC-Probelauf erreichte mit dem Tuningprofil die obere Grachtenbrücke und beendete 900 m in 45,20 s: 14 Trefferereignisse, 6 Landungen, 2 räumlich eingesammelte Münzen, 111,9 km/h Spitzengeschwindigkeit. Dafür hielt der Testlauf Gas, schaltete Tuning ein und aktivierte Nitro vor den Anlaufmarkierungen; der automatische Balancehelfer korrigierte die Sprünge. Das ist ein reproduzierbarer Systemlauf, kein menschliches Fahrfeedback.
- `build/amsterdam_preview_strecke.png` zeigt die laufende Vorschau bei 418 m mit der verlängerten Rampe, dem durchgehenden Stadtpanorama, Steinpflaster und Ufermauer. Das Bild wurde mit Godot 4.7.2 unter NVIDIA Compatibility Mode aufgenommen.
- Der interaktive Start bleibt `tools/PC-Teststarts/Start_Amsterdam_Gameplay_Preview_PC.bat` und verwendet ausschließlich das getrennte Testprofil. T schaltet zwischen Serien- und Tuningprofil um; persönliche Spielstände und gekaufte Upgrades wurden nicht verändert.

## Karosserieschaden, Zombiegriffe und Panzerungszeichnung – 5. November 2026

- Entfernt wurden die polygonalen Schadensdellen und der dunkle Motorhaubenfleck, die beim Treffer wie rechteckige Kacheln beziehungsweise ein loses Teil aussahen. Kleine Kratzspuren bleiben als sichtbarer Schaden erhalten und liegen jetzt auf den Seitenblechen; Rauch steigt klein und direkt am Motorhaubenbereich auf.
- Die separat gezeichneten Handflächen und Finger an festhaltenden Zombies wurden entfernt. Die Hände bleiben Teil der jeweiligen Zombieillustration, damit Finger und Arme zusammenpassen.
- Panzerungsstufen 1–3 verwenden jetzt denselben Karosseriefarbton wie die bestätigte Stufe 1. Bei Stufe 2 und 3 wurden Mipmaps ausgeschaltet und alle Kombi-Stufen nutzen denselben linearen Texturfilter; dadurch wird keine einzelne Stufe beim Herunterskalieren weichgezeichnet.
- Die vorhandene Dachwaffe wurde kleiner und an die vordere Dachposition gesetzt. Ihr Mündungsblitz/Schuss beginnt an der sichtbaren Mündung; das Waffenupgrade selbst und seine Freischaltung bleiben erhalten.
- Sichtprüfung mit Godot 4.7.2 im isolierten QA-Projekt: `build/armor_visual_review_0.5.51.png` zeigt Serienkarosserie mit Schaden, Panzerungsstufen 1–3, einen haltenden Zombie und die Dachwaffe. Das Godot-Debugfenster meldete 0 Fehler und 0 Warnungen. Der finale Quellstand lud zusätzlich im Headless-Editor erfolgreich (Exitcode 0).
- Diese Prüfung verglich statische Fahrzeugansichten; eine laufende Fahrt, reale Trefferfolge, Android-Gerätetest und der Einfluss auf Spielstände wurden in diesem Arbeitsschritt nicht erneut geprüft. Spielstände und gespeicherte Upgrades wurden nicht verändert.

## Dachwaffe und Endrohr – 5. November 2026

- Die Dachwaffe sitzt weiter vorn auf der Dachhaut; ihr Stahlfuß liegt nun sichtbar auf dem Dach, während das Rohr knapp über die Frontscheibe zielt. Der sichtbare Schussblitz beginnt am neuen Mündungspunkt.
- Das kurze Endrohr tritt jetzt unter der hinteren Stoßstange aus. Abgasrauch und Boost-Flamme beginnen am selben Austrittspunkt.
- Die importierten Panzerungsbilder wurden in der Fahrzeugansicht erneut verglichen: Die Fensterstäbe liegen innerhalb der jeweiligen Scheibenrahmen; die Karosserie- und Radpositionen blieben unverändert.
- Sichtprüfung im isolierten Godot-QA-Projekt mit der Dachwaffen- und Panzerungsgalerie. Keine Spiellogik, Kaufdaten oder persönlichen Spielstände wurden geändert. Eine vollständige Fahrprüfung und ein Android-Gerätetest bleiben offen.
