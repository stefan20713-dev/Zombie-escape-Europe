# Zombie Escape Europe

Ein eigenständiges 2D-Fahrspiel für Godot 4.7.2 mit PC-Vorschau und Android-Ziel.

**Das Hauptprojekt ist dieser Ordner.** Starte am PC über [Werkstatt und Amsterdam](Start_Zombie_Escape_Europe_PC_Preview.bat). **Losfahren** führt mit dem gewählten Fahrzeug und seinen Upgrades zur aktuellen Strecke über 1.175 m. Im Pause- und Ergebnismenü führt **Zur Werkstatt** zurück. Die PC-Vorschau speichert Werkstattkäufe und läuft ohne Kampagnenfortschritt.

Die technischen Direktstarts liegen gesammelt unter `tools/PC-Teststarts`. Der Godot-Projekteditor öffnet `project.godot`. Die Android-Exportdateien im Unterordner `android` gehören zu diesem Projekt.

## Aktueller Projektumfang

- **Kampagne:** Amsterdam ist die einzige aktive Strecke. Rotterdam und die frühere 30-Städte-Struktur sind aus dem laufenden Spiel entfernt; weitere Städte werden später neu geplant.
- **Spielstand:** Beim nächsten Spielstart werden die alte Routenauswahl und Kampagnenfortschritte einmalig zurückgesetzt. Münzen und gekaufte Fahrzeug-Upgrades bleiben erhalten.
- **Projektdateien:** Die Amsterdam-Strecke, Fahrzeug, Werkstatt, Upgrades, Bedienung und vorhandene Spielsysteme bleiben Teil des Projekts.
- **PC-Vorschau:** [Start_Zombie_Escape_Europe_PC_Preview.bat](Start_Zombie_Escape_Europe_PC_Preview.bat)
- **Spiel starten:** Für die spielbare PC-Version diese Vorschau-Datei öffnen. Ein Doppelklick auf `Godot_v4.7.2-stable_win64.exe` allein öffnet nur den Godot-Projektmanager; dort das Projekt wählen und auf **Ausführen** klicken.
- **Aktuelle Startprüfung (5. November 2026):** Godot 4.7.2 lädt die Hauptszene bis zur Werkstatt; die frische Prüfung meldete `game_ready_ms=2270` ohne Skriptfehler. Ein Kartenfehler durch einen veralteten Herausforderungs-Zähler wurde behoben. Amsterdam-Karte, Kurzvorschau, Upgrade-Vorschau, Fahrwerte und Zombie-Anhaften wurden mit isolierten QA-Spielständen geprüft; dein persönlicher Spielstand wurde dabei nicht geöffnet oder verändert.
- **Amsterdam-Archiv:** Ein einziger Fluchtplan-Eintrag ist über Werkstatt und Karte erreichbar und wird auf der Amsterdam-Strecke einmalig geborgen. Während der Fahrt gibt es keine Funkansagen; der kurze Texteintrag bleibt optional.
- **Brückenwahl:** Die 120-km/h-Wahl mit niedriger Durchfahrt und erhöhter Sprungroute ist in der separaten Kurzvorschau `tools/PC-Teststarts/Start_Amsterdam_Gameplay_Preview_PC.bat` umgesetzt. Sie ist noch nicht in die 1.800-m-Hauptkampagnenstrecke übertragen.
- **Startreparatur (4. November 2026):** Fehlerhafte Hintergrund- und Terrain-Skripte sowie ein fehlender Story-Datenzugriff wurden repariert. Drei Windows-Starter übergeben den Projektpfad nun korrekt an Godot. Keine persönliche Speicherdatei wurde für diese Prüfung verwendet.
- **Hinweise:** [aktueller Kampagnenentwurf](CAMPAIGN_DESIGN.md). Die Abschnitte darunter sind historische Entwicklungsnotizen und beschreiben teilweise Inhalte, die nicht mehr aktiv sind.
- **Wichtig:** 30-Welten-Zahlen und Stadtnamen in den folgenden alten Prüfberichten sind historische Protokolle. Sie sind weder im aktuellen Spiel enthalten noch Teil der aktiven Kampagnenstruktur.
## Meilenstein 0.5.37 (historisch) – Startpaket für den ersten Hügel

- Die Garage bietet auf einem frischen Kombi-Profil einen gemeinsamen Ein-Tipp-Kauf: Motor und Tank kosten weiterhin zusammen 95 Münzen. Der Kauf zieht beide Preise atomar ab, aktualisiert echte Fahrzeugwerte und den profilspezifischen Spielstand und verschwindet nach einem Einzel- oder Paketkauf. Bei fehlenden Münzen bleibt das Profil unverändert und zeigt den Fehlbetrag an.
- Das Paket erscheint nur im frühen Garagenabschnitt, solange nur der Kombi freigeschaltet ist. So bleibt die Fahrzeugwahl sichtbar, sobald ein zweites Fahrzeug verfügbar wird.
- **Godot 4.7.2:** **21/21 Prüfblöcke bestanden.** Der neue Pakettest deckt Preis, HUD-Schaltfläche, Motor-/Tankwirkung, Unterdeckung, Einzelkauf, Doppelkauf und Fahrzeugwahl ab. Die erste-Fünf-Welten-Balancefahrt bestand mit Motor 1/Tank 1; der Rotterdam-Sprung erfolgte bei 47,1 km/h ohne Hindernistreffer. Der Gesamtsweep schloss 30/30 Welten und die Messina-Rettung ab. Protokoll: `build/godot_vehicle_milestone_0.5.37-start-package-full-r1_20261102_123548_000/`.
- **Android:** Der Debug-APK-Export 0.5.37 wurde gestartet, stoppte aber beim Gradle-Daemon-Verbindungsaufbau; deshalb gibt es noch keinen neuen 0.5.37-APK. Letzte vorhandene Android-Version bleibt der erfolgreich exportierte Debug-APK 0.5.36. ADB konnte den isolierten Server beim erneuten Screenshotlauf nicht starten; neue 0.5.37-Storebilder sind daher noch nicht aufgenommen. Der Screenshot-Aufnahmeablauf ist auf Europa-Karte und längere Fahransicht umgestellt, aber noch nicht auf dem AVD bestätigt.
- Exportpresets sind auf Version 0.5.37 / Code 101 angehoben. Das AAB wurde nicht erstellt; das Store-AAB bleibt für deinen privaten Upload-Keystore zurückgestellt.
- **Noch offen:** neuen Android-Export und AVD-Lauf mit funktionierendem Gradle-/ADB-Dienst wiederholen, 0.5.37-Storebilder aufnehmen, echte Telefonabnahme, manuelles Balancing und Art-Politur, Produktions-AdMob-/Datenschutzkonfiguration und Play-Console-Angaben.

## Entwicklungsstand: 0.5.36 – abgesicherte Spielstände

- `scripts/game.gd` schreibt Fortschritt zuerst in eine temporäre Datei, prüft Vollständigkeitsmarke und Generation und übernimmt sie erst danach als Hauptstand. Der letzte gültige Stand bleibt als Backup erhalten; abgebrochene Schreibvorgänge werden aus der neuesten vollständigen Generation wiederhergestellt. Ein unlesbarer Hauptstand wird beim Laden nicht überschrieben und vor dem nächsten Speichern als `.corrupt` gesichert.
- Das Kampagnenspeicherschema ist auf 10 gestiegen. Vorhandene Schema-9-Spielstände werden beim Laden migriert und bleiben zusätzlich als Backup bestehen.
- **Godot 4.7.2:** Die bisherigen 19 Meilensteinblöcke bestanden, einschließlich 30/30 Städte, Messina-Rettung und Rotterdam-Rampe bei 47,1 km/h ohne Hindernistreffer. Der neue Recovery-Test bestand anschließend separat mit Hauptstand-Priorität, Temp-/Backup-Wiederherstellung, Schema-9-Migration, Generationswechsel und Sicherung beschädigter Daten. Protokolle: `build/godot_vehicle_milestone_0.5.36-progress-save-final_20261102_115421_483/` und `build/godot_vehicle_milestone_0.5.36-progress-save-final_20261102_120141_643/20_progress_save_recovery.stdout.log`.
- **Android-Debug-APK:** `build/android/Zombie_Escape_Europe-debug-0.5.36-save-recovery-isolated.apk` — Version 0.5.36 / Code 100, Paket `com.zombieescapeeurope.game`, API 28–36, arm64-v8a und x86_64, Debugsignatur geprüft und 16-KB-ausgerichtet; 201.302.058 Byte, SHA-256 `1D23A5DB293056044AE606208331CD4DC170D6FFFD5096E022DE16152FBDDB3C`. Debug-Build, kein Play-Store-APK oder AAB.
- **Android-16-AVD:** Archiv, Gas, Bremse, Boost, Neigen links/rechts, Pause/Fortsetzen, Musikregler und System-Zurück bestanden. 7/7 Bedienflächen lagen in der gemeldeten sicheren Fläche. Nach App-Unterbrechung und Kaltstart wurden 50,77 m und 51 % Musiklautstärke wiederhergestellt. Kein Spielabsturz, Spiel-ANR oder GDScript-Fehler in den geprüften Logs. Protokoll: `build/android/touch_milestone_0.5.36-save-recovery-isolated.logcat.txt`.
- **Noch offen:** echte Telefonabnahme, manuelles Kampagnen-Balancing und Art-Politur, Produktions-AdMob-/Datenschutzkonfiguration und finale Play-Console-Angaben. Das AAB wird wie vereinbart nach Fertigstellung mit deinem Upload-Keystore erstellt.

## Entwicklungsstand: 0.5.35 – Regionale Wetterstimmungen

- Alle 30 Kampagnenstädte haben ein geprüftes Atmosphärenprofil. Acht Typen kommen vor: klar, Dunst, Regen, Staub, Meeresdunst, Hitze, Rauch und Sturm. Himmels- und Horizontfarben unterscheiden Nordsee, trockene Ebenen, Mittelmeer und den Messina-Endabschnitt.
- Die Effekte liegen ausschließlich im Hintergrund: Dunstbänder, Regentropfen, Staubpartikel, Meeresnebel, Hitzeschimmer, Rauchfahnen und der stärkere Sturm der finalen Rettung. Fahrbahn, Gefahren-Sichtbarkeit, Traktion und Fahrzeugphysik bleiben unverändert.
- **Godot-Gesamttest:** **19/19 Prüfblöcke bestanden.** Der Profiltest prüfte alle 30 Städte und acht Effektarten; die Kampagnenfahrt schloss 30/30 Welten und die Messina-Rettung ab. Rotterdam-Rampe: 47,1 km/h, Rampe überwunden, kein Hindernistreffer. Protokoll: `build/godot_vehicle_milestone_0.5.35-atmosphere_20261102_093121_430/`.
- **Bildprüfung:** Die beschriftete 8-Felder-Vergleichstafel liegt unter `build/godot_vehicle_milestone_0.5.35-atmosphere_20261102_093121_430/19_atmosphere_system/atmosphere_gallery.png`.
- **Android-Spiel-APK:** `build/android/Zombie_Escape_Europe-qa-release-security-check-elevated.apk` — Version 0.5.35 / Code 99, API 28–36, arm64-v8a, nicht debuggable, V2-signiert und 16-KB-ausgerichtet; 110.302.674 Byte, SHA-256 `E4E075C67F3052B770B7469D694BDA531A791BE7E1655F5A1FF5C1A802563C2A`. Interne QA-Signatur, kein Play-Store-Build.
- **Android-16-AVD:** Die normale Spielszene bestand den Touch- und Kaltstartlauf: Archiv, Gas, Bremse, Boost, Neigen links/rechts, Pause/Fortsetzen, Lautstärkeregler, Zurück-Taste, Fahrtspeicherung und Wiederherstellung (61,89 m); Musiklautstärke 51 % blieb erhalten. UMP-/AdMob-Testinitialisierung und Audiostart/Crossfade bestanden. Kein Spielabsturz, ANR oder Shaderfehler im geprüften Lauf. Protokolle und Bilder: `build/android/touch_milestone_0.5.35-full-touch-r1*`.
- **Rotterdam-Hügel auf Android:** Die separate Rampen-QA-Szene erkannte den echten Boost-Touch am Berg (Steigung −0,111), sprang bei 46,4 km/h ab und passierte das Hindernis ohne Treffer. 7/7 aktive Touchflächen lagen innerhalb der Sicherheitsfläche. Bilder/Protokoll: `build/android/touch_milestone_0.5.35-ramp-qa-scene*`.
- **Play-Store-Listing-Entwurf:** `store_listing/de/` enthält ein geprüftes 512×512-Icon, eine 1024×500-Feature-Grafik, drei echte 1920×1080-Gameplay-Screenshots und deutschen Store-Text innerhalb der Zeichenlimits. Das ist ein lokaler Entwurf; die echte Telefonabnahme und Play-Console-Angaben fehlen.
- **Noch offen:** Fahrt auf einem echten Android-Telefon und manuelles Balancing/Politur, echte AdMob-/Datenschutzkonfiguration und Store-Angaben fertigstellen; das Play-Store-AAB später mit deinem Upload-Keystore signieren. Die AVD-Prüfung ersetzt keine menschliche Telefonabnahme.

## Entwicklungsstand: 0.5.34 – Fahrwerks- und Fahrzeug-Upgrades

- Die Werkstatt bietet sieben einzeln kaufbare Upgrade-Arten. Zusätzlich zu Motor, Reifen, Tank und Panzerung gibt es jetzt Federung, Kraftstoffeffizienz und Bremsen. Alle Werte werden pro Fahrzeug gespeichert und wirken auf die laufende Fahrphysik.
- Reifen erhöhen die Traktion bergauf und verringern den Tempoverlust an Straßenhindernissen. Federung verbessert Federkraft und Dämpfung, Effizienz senkt den Verbrauch um 8 % je Stufe (bis zu 24 %) und jede Bremsstufe erhöht die Bremskraft um 15 %.
- Die Werkstatt zeigt die vier Fahrzeugteile und die drei Fahrwerksteile auf zwei Touch-Seiten. Das Speicherschema 9 ergänzt die neuen Teile ohne Verlust vorhandener Fahrzeugstände; die Erstfahrt-Einstellung bleibt bei der Migration erhalten.
- **Godot-Gesamttest:** 18/18 Prüfblöcke bestanden. Die Vorschau aller 84 Kombinationen aus sieben Upgrades, drei Fahrzeugen und vier Stufen war korrekt; Physikwirkung, Speicher-/Fahrzeugwechsel, Balance, Rotterdam-Rampe, 30 Städte und Messina-Rettung bestanden. Protokoll: `build/godot_vehicle_milestone_0.5.34-upgrades_20261102_080432_082/`.
- **Installierbare QA-APK:** `build/android/Zombie_Escape_Europe-qa-release-0.5.34.apk` — Code 98, Android API 28–36, arm64-v8a, nicht debuggable, V2-signiert und 16-KB-ausgerichtet; 110.288.313 Byte, SHA-256 `8D9A629E51E66A91C725A7EC5C0AB6DDC297EF298723892D7A8AE0C0E1920738`. Mit lokalem QA-Schlüssel signiert, kein Play-Store-Build.
- **Android-16-AVD:** Debug-APK installiert und gestartet. Touch für Archiv, Gas, Bremse, Boost, Neigen, Pause, Musikregler und Zurück wurde erkannt; Speicher- und Musikregler-Logs waren vorhanden, der sichere Touchbereich meldete 7/7. Kein Spielabsturz, Spiel-ANR oder Shaderfehler im Log. Der ADB-Server brach beim abschließenden Kaltstart-/Fortschrittscheck ab; daher ist dieser letzte Teil nicht als bestanden gewertet. Screenshots und Logcat: `build/android/touch_milestone_0.5.34-upgrades*`.
- Das editierbare Projektpaket heißt `Zombie_Escape_Europe_Godot_0.5.34_30-Welten.zip`; APK/AAB, Keystores und Godot-Caches sind darin nicht enthalten. Die QA-APK verwendet den lokalen Testschlüssel. Das Store-AAB bleibt gemäß Vereinbarung für deinen Upload-Keystore zurückgestellt.
- **Play-Store-Export:** `tools/export_play_store_aab.ps1` stellt vorherige Keystore-Umgebungswerte wieder her und prüft ein erzeugtes AAB auf Bundle-Konfiguration, Android-Manifest und gültige JAR-Signatur. Die Profilvorprüfung besteht; der vollständige Store-Build wurde mit deinem privaten Keystore noch nicht ausgeführt.
- **Noch offen:** echte Telefonabnahme, manuelles Balancing und Politur, Produktions-AdMob-/Datenschutzkonfiguration sowie Play-Store-Angaben und das später von dir signierte AAB.

## Entwicklungsstand: 0.5.33 – Android-Anzeigen- und Einwilligungssystem

- Das Projekt bindet Poing Studios AdMob Plugin 5.1.0 samt Godot-4.7.2-Android-AARs ein. Es bleibt bei Android/Gradle; die Projekt- und Exportversionen sind 0.5.33 / Code 97.
- `scripts/ads_service.gd` startet UMP bei jedem Android-Appstart vor AdMob, lädt freiwillige Rewarded Ads und seltene Interstitials, behandelt Fehler ohne den Spielfluss zu sperren und vergibt 500 Münzen nur beim bestätigten Google-Reward-Callback. Schutz: höchstens ein Reward pro Fehlversuch, fünf pro 24 Stunden; Interstitial höchstens nach jedem dritten beendeten Fehlversuch, mit 90 Sekunden Abstand und maximal zwei pro Tag.
- Während der Entwicklung sind ausschließlich Googles offizielle Test-App-/Anzeigen-IDs hinterlegt. Debug- und QA-Builds verwenden für den registrierten Emulator die UMP-Testgeografie außerhalb des EWR; das Play-Store-Profil enthält dieses QA-Merkmal nicht und verwendet später die echte Nutzergeografie. Live-Anzeigen bleiben in Release-Builds ausgeschaltet, bis echte AdMob-IDs und Consent-Nachrichten eingerichtet sind. Es werden keine Anzeigen simuliert.
- **Godot-Gesamttest:** 18/18 Prüfblöcke bestanden. Die Kampagnenfahrt schloss 30/30 Städte und die Messina-Rettung ab; die Rotterdam-Rampe wurde bei 47,1 km/h ohne Hindernistreffer passiert. Protokoll: [Meilenstein 0.5.33](build/godot_vehicle_milestone_0.5.33-admob-r2_20261102_070430_539/).
- **Android-16-AVD:** UMP meldete im QA-Testprofil „nicht erforderlich“, Mobile Ads wurde initialisiert und Rewarded- sowie Interstitial-Testanzeigen wurden geladen. Archiv, Gas, Bremse, Boost, Neigen, Pause/Fortsetzen und System-Zurück bestanden. 18,8 m Fahrstrecke und Musiklautstärke 51 % wurden nach einem neuen App-Prozess wiederhergestellt. Vollständiges Prüfprotokoll: [Android-Gesamttest](build/android/touch_milestone_0.5.33-admob-final-r5.logcat.txt).
- **Rewarded-Video-Gesamttest:** Die Android-16-AVD zeigte die offizielle Google-Testanzeige und erhielt den nativen Reward-Callback; die Produktionslogik schrieb genau 500 Münzen gut (100 → 600), speicherte sie und schloss die Anzeige. [Prüfprotokoll](build/android/touch_milestone_0.5.33-reward-native-r2.logcat.txt) · [Ergebnisbild](build/android/touch_milestone_0.5.33-reward-native-r2_rewarded_ad_result.png). Der Emulator meldete daneben Hintergrund-ANRs für Google Play Store und Google Play Services, aber keinen Absturz oder ANR im Spielprozess.
- [Reward-Test-APK](build/android/Zombie_Escape_Europe-qa-reward-0.5.33.apk) — separat exportiertes QA-Paket, das direkt die automatisierte Anzeigen-Prüfszene startet. Nicht als Spiel-/Store-APK installieren oder veröffentlichen.
- **Installierbare QA-APK:** [Zombie_Escape_Europe-qa-release-0.5.33.apk](build/android/Zombie_Escape_Europe-qa-release-0.5.33.apk) — Version 0.5.33, Code 97, Android API 28–36, **arm64-v8a**, nicht debuggable, V2-signiert und 16-KB-ausgerichtet; 110.285.997 Byte, SHA-256 `105BA1DEAB1F827BE8605091A186CF4057BCE90969FE7C6F6C2095EAF75DC7F5`. Die Telefon-APK ist durch Weglassen der x86_64-Engine rund 40 % kleiner. Sie ist lokal mit dem QA-Testschlüssel signiert und nicht für den Play Store.
- **Godot-Quellpaket:** [Zombie_Escape_Europe_Godot_0.5.33_30-Welten.zip](Zombie_Escape_Europe_Godot_0.5.33_30-Welten.zip) — Godot-Projekt, Add-on samt Android-Bibliotheken und QA-Skripte; erzeugte Gradle-Dateien, APK/AAB, Keystores und Caches sind ausgeschlossen.
- `tools/export_play_store_aab.ps1 -ValidateOnly` **bestanden**: Version 0.5.33, Code 97, API 36, AAB-Format und keine QA-Merkmale. Das AAB wird wie vereinbart später von dir mit deinem privaten Upload-Keystore erstellt.
- **Vor der Veröffentlichung offen:** Rewarded-Angebot und Bedienung auf einem echten Telefon ansehen; echtes Telefon für Fahrbalance, Touch, Audio, Displayaussparungen und Leistung prüfen; 30 Welten final visuell/balancetechnisch abnehmen; echte AdMob-IDs und eine veröffentlichte UMP-Consent-Nachricht eintragen; öffentliche Datenschutzerklärung und Play-Console-Datensicherheit vervollständigen. Der Emulator ersetzt keinen Test auf dem Zieltelefon.
- Add-on-Quellen und MIT-Lizenz: [Poing Studios AdMob Plugin](https://github.com/poingstudios/godot-admob-plugin). Google beschreibt die automatischen SDK-Datenflüsse in seiner [Google-Play-Datenschutzhilfe](https://developers.google.com/admob/android/privacy/play-data-disclosure); die tatsächliche Play-Console-Erklärung muss zur endgültigen Konfiguration passen.

## Entwicklungsstand: 0.5.32 – Bergauf-Boost auf Android geprüft

- `scripts/qa_ramp_test.gd` startet in der produktiven Fahrtszene vor dem Rotterdam-Hügel, verlangt den echten Bergauf-Hinweis, protokolliert Boost, Rampenabsprung und Hindernistreffer. `tools/android_touch_milestone.ps1 -RampQaSmoke` hält auf Android die produktive BOOST-Touchfläche, sobald der Hinweis erscheint.
- **Godot-Gesamttest:** 18/18 Abschnitte bestanden. Die automatisierte Kampagne beendete 30/30 Städte und die Messina-Rettung (950,3 m). Der Rampentest erreichte 47,1 km/h und überwand das Hindernis ohne Treffer. Protokoll: [Meilenstein 0.5.32](build/godot_vehicle_milestone_0.5.32-hill-touch_20261102_054935_229/).
- **Android-16-AVD:** Produktionsszene, sichere Touchflächen (7/7), Soundtrack/Crossfade und echter Touch auf BOOST bestanden. Der Hinweis erschien bergauf bei Neigung `-0,111`; die Rampe wurde bei 47,1 km/h übersprungen, `hazard_hits=0`. [Steigungsbild](build/android/touch_milestone_0.5.32-ramp-hill-touch-r2_hill_boost_hint.png) · [Absprungbild](build/android/touch_milestone_0.5.32-ramp-hill-touch-r2_ramp_launch.png) · [Ergebnisbild](build/android/touch_milestone_0.5.32-ramp-hill-touch-r2_ramp_result.png) · [Emulatorprotokoll](build/android/touch_milestone_0.5.32-ramp-hill-touch-r2.logcat.txt).
- **Installierbare QA-APK:** [Zombie_Escape_Europe-qa-release-0.5.32.apk](build/android/Zombie_Escape_Europe-qa-release-0.5.32.apk) — Version 0.5.32, Code 96, Android API 28–36, nicht debuggable, V2-signiert und 16-KB-ausgerichtet; 167.873.038 Byte, SHA-256 `6E537F1B1DE9B25C11FB583BF2ED73A296DF282C1C63FDBE6B04A2599C829192`. Mit lokalem QA-Testschlüssel signiert, nicht für den Play Store.
- **Godot-Quellpaket:** [Zombie_Escape_Europe_Godot_0.5.32_30-Welten.zip](Zombie_Escape_Europe_Godot_0.5.32_30-Welten.zip) — editierbares Projekt samt Steigungs- und Android-Rampentest; APK, AAB, Keystore und Godot-Cache bleiben ausgeschlossen.
- `tools/export_play_store_aab.ps1 -ValidateOnly` prüft Version 0.5.32, Code 96, Ziel-API 36 und ein QA-freies AAB-Profil. Das AAB wurde wie vereinbart nicht erstellt; du baust es später mit deinem Upload-Keystore.
- **Bis zum Release offen:** menschliche Fahr- und Balanceprüfung auf einem echten Android-Telefon, abschließende Art-/Levelpolitur und Anbieter-, Datenschutz- und Storeangaben. Der Emulator ersetzt keine Geräteabnahme.

## Entwicklungsstand: 0.5.31 – Bergauf-Boost und Fahrbarkeitsprüfung

- `scripts/hud.gd` wertet die Straßenneigung jetzt richtig aus: In Bildschirmkoordinaten ist ein negativer Winkel eine Steigung nach rechts. Die Anzeige empfiehlt den Boost daher beim Beschleunigen bergauf, bei niedrigem Tempo und verfügbarem Nitro/Kraftstoff; bergab erscheint der Hinweis nicht.
- Die automatisierten Fahrer in den Balance- und Kampagnensweeps verwenden nun dieselbe Bergauf-Regel. Die Physik- und Upgradewerte bleiben unverändert.
- `build/hill_assist_smoke_0.5.31.gd` prüft die tatsächliche Straßenhöhe bergauf/bergab, den Neigungsgrenzwert und die Zustände für Gas, Tempo, Nitro und Kraftstoff.
- **Godot-Gesamttest:** 17/17 Abschnitte bestanden. Die frische Einstiegsfahrt schloss Amsterdam bis Luxemburg mit dem empfohlenen Motor-1-/Tank-1-Paket ab; der korrigierte Fahr-Sweep schloss anschließend 30/30 Städte und die Messina-Rettungsmission bei 950,3 m ab. Protokoll: [Meilenstein 0.5.31](build/godot_vehicle_milestone_0.5.31-hill-hint_20261102_053455_090/).
- **Android-16-AVD:** Installiert und gestartet. Archiv, Gas, Bremse, Boost, Neigen, Pause/Fortsetzen, Musikregler und Android-System-Zurück funktionierten. 18,34 m und 51 % Musiklautstärke wurden nach einem neuen App-Prozess wiederhergestellt. Im Spielprozess wurden keine Absturz- oder ANR-Marker gefunden; der Emulator protokollierte zwei unabhängige ANRs von Google Play Services. [Fahrbild](build/android/touch_milestone_0.5.31-hill-assist_run_ready.png) · [Prüfprotokoll](build/android/touch_milestone_0.5.31-hill-assist.logcat.txt).
- **Installierbare QA-APK:** [Zombie_Escape_Europe-qa-release-0.5.31.apk](build/android/Zombie_Escape_Europe-qa-release-0.5.31.apk) — Version 0.5.31, Code 95, Android API 28–36, nicht debuggable, V2-signiert und 16-KB-ausgerichtet; 167.871.850 Byte, SHA-256 `7D3F402217E0819185A0D0E3EBB475BBD5484FD6974E5CB6CD211597503C0A90`. Mit lokalem QA-Testschlüssel signiert, nicht für den Play Store.
- **Godot-Quellpaket:** [Zombie_Escape_Europe_Godot_0.5.31_30-Welten.zip](Zombie_Escape_Europe_Godot_0.5.31_30-Welten.zip) — editierbares Projekt mit Bergauf-Regressionstest, ohne APK, AAB, Keystore oder Godot-Cache.
- `tools/export_play_store_aab.ps1 -ValidateOnly` besteht mit Version 0.5.31, Code 95, Ziel-API 36 und QA-freiem AAB-Profil. Das AAB wurde wie vereinbart nicht erstellt; du baust es später mit deinem Upload-Keystore.
- **Bis zum Release offen:** menschliche Fahr- und Balanceprüfung auf einem echten Android-Telefon, abschließende Art-/Levelpolitur und Anbieter-, Datenschutz- und Storeangaben. Der Emulator ersetzt keine Geräteabnahme.

## Entwicklungsstand: 0.5.30 – Fahrzeugfeedback und Android-QA

- `scripts/wagon.gd` ergänzt sichtbare Rückmeldung beim Fahren: Auspuffwolken bei Gas, aufgewirbelten Straßenabrieb beim Beschleunigen und nach Trefferstärke abgestufte Funken. Alle drei Fahrzeugklassen zeigen die Effekte; Lufttreffer lösen keine Bodenkollisionseffekte aus.
- `scenes/qa_setpiece_gallery.tscn` und `scripts/qa_setpiece_gallery.gd` erweitern die Sichtprüfung auf intakte, beschädigte und kritische Fahrzeuge. [Fahrzeug- und Effektgalerie](build/setpiece_visual_review/setpieces_page_04.png).
- **Godot-Gesamttest:** 16/16 Abschnitte bestanden. Die automatisierte Kampagnenfahrt schloss 30/30 Städte und die Messina-Rettungsmission bei 950,3 m ab. Protokoll: [Meilenstein 0.5.30](build/godot_vehicle_milestone_0.5.30-vehicle-feedback-r1_20261102_051947_172/).
- **Android-16-AVD:** Die Release-QA-APK installierte und startete. Archiv, Gas, Bremse, Boost, Neigen, Pause/Fortsetzen, Musikregler und System-Zurück wurden per Touch geprüft. Der Spielstand stellte nach Prozessneustart 24,36 m wieder her; der Musikpegel von 51 % blieb erhalten. [Fahrbild](build/android/touch_milestone_0.5.30-vehicle-feedback-final_run_ready.png) · [Prüfprotokoll](build/android/touch_milestone_0.5.30-vehicle-feedback-final.logcat.txt).
- **Installierbare QA-APK:** [Zombie_Escape_Europe-qa-release-0.5.30.apk](build/android/Zombie_Escape_Europe-qa-release-0.5.30.apk) — Version 0.5.30, Code 94, Android API 28–36, nicht debuggable, V2-signiert und 16-KB-ausgerichtet; 167.871.922 Byte, SHA-256 `5773C45278D2D6A389C6A50CF6ECA316AAF4D301B79A466D8D7DAA965AE4B7C0`. Mit lokalem QA-Testschlüssel signiert, nicht für den Play Store.
- `tools/export_play_store_aab.ps1 -ValidateOnly` bestätigt den späteren AAB-Export mit Version 0.5.30, Code 94, Ziel-API 36 und QA-freiem AAB-Profil. Das AAB wurde wie vereinbart nicht erzeugt; du erstellst es bei Fertigstellung mit deinem privaten Upload-Keystore. Google Play verlangt derzeit [API 36 oder höher](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en) für neue Apps und Updates.
- **Bis zum Release offen:** auf einem echten Android-Telefon fahren und Balance, Touchgefühl, Audio und Leistung prüfen; Art und Level polieren; Anbieter-, Datenschutz- und Storeangaben abschließen. Der Emulator ersetzt die Geräteabnahme nicht.

## Entwicklungsstand: 0.5.29 – Fahrbahn und Android-QA

- `scripts/terrain.gd` zeichnet eine sichtbare Asphaltfahrbahn mit thematischen Farben, Straßenkante, Abrieb, Rissen und Fahrbahnmarkierungen. Der Straßenverlauf bleibt für Zeichnung und Physik derselbe.
- `scripts/backdrop.gd` zeichnet einen glatten 1×256-Pixel-Himmelverlauf statt grober Farbstreifen und versieht die Wolken mit weichen Schattenkanten.
- **Godot-Gesamttest:** 15/15 Abschnitte bestanden. Die automatische Fahrt beendete 30/30 Städte und die Rettungsmission bei 950,3 m. Protokoll: [Meilenstein 0.5.29](build/godot_vehicle_milestone_0.5.29-road-art-r1_20261102_045446_376/).
- **Android-16-AVD:** Installiert und gestartet; Archiv, Gas, Bremse, Boost, Neigen, Pause, Musikregler, Fortsetzen und Android-Zurück erkannt. Der Spielstand wurde mit 75,45 m in einem neuen Prozess wiederhergestellt; 51-%-Musikpegel blieb erhalten. [Fahrbild](build/android/touch_milestone_0.5.29-road-art_run_ready.png) · [Prüfprotokoll](build/android/touch_milestone_0.5.29-road-art.logcat.txt).
- **Installierbare QA-APK:** [Zombie_Escape_Europe-qa-release-0.5.29.apk](build/android/Zombie_Escape_Europe-qa-release-0.5.29.apk) — Version 0.5.29, Code 93, Android API 28–36, nicht debuggable, V2-signiert und 16-KB-ausgerichtet; 167.868.298 Byte, SHA-256 `80A657BE09F6966AC1E9E1E1D5B8B4DCDE001D679442E23FBC701CAF48621536`. Mit lokalem QA-Testschlüssel signiert, nicht für den Play Store.
- `tools/export_play_store_aab.ps1 -ValidateOnly` prüft den AAB-Export ohne Keystore-Abfrage. Das AAB wird wie vereinbart erst bei Fertigstellung mit deinem Upload-Keystore erstellt. Google Play verlangt derzeit [API 36 oder höher](https://support.google.com/googleplay/android-developer/answer/11926878?hl=en) für neue Apps und Updates.
- **Bis zum Release offen:** menschliche Fahr- und Balanceprüfung auf einem echten Android-Telefon, weitere Art-/Levelpolitur sowie Anbieter- und Storeangaben. Der Emulator ersetzt die Prüfung auf echter Hardware nicht.

## Entwicklungsstand: 0.5.28 – Grundspielintegration

- Beschädigte Fahrzeuge zeigen zunehmend Kratzer und Dellen; bei kritischem Zustand kommt animierter Motorrauch hinzu. Die Darstellung greift für alle drei Fahrzeugklassen.
- Jede Stadtstrecke markiert zwei Versorgungsdepots am Straßenrand. Beim Durchfahren erhält der Spieler die bereits integrierte Münzbelohnung und Nachschub für Benzin, Nitro und Fahrzeugzustand. Die Rettungsmission hat passende Sperrzonen und eine Hafenmole.
- Ein tragbares Funkgerät sammelt je eine Geschichte pro Stadt und eine zusätzliche Aufnahme an Bord des Rettungsschiffs. Das Archiv enthält 31 deutschsprachige, erst nach Fund lesbare Einträge. Jeder Fund zahlt einmalig 20 Münzen und wird auch dann dauerhaft gespeichert, wenn die Fahrt unterbrochen wird.
- Garage und Europakarte führen ins Archiv; die Rückkehr geht auf den Ausgangsbildschirm. Android-System-Zurück schließt das Archiv ebenfalls. Die Archivansicht bietet eine auswählbare Liste aller 31 Etappen.
- Das Speicherschema wird von 7 auf 8 migriert und übernimmt vorhandene Münzen, Kampagne und Einstellungen.
- **Godot-Gesamttest:** 14/14 Abschnitte bestanden. Die automatische Kampagnenfahrt schloss 30/30 Welten und die Messina-Rettungsmission ab. Das Funkarchiv, alle Stadt-Funkgeräte, Checkpoint-Nachschub, einmalige Belohnungen und Speichermigration wurden geprüft. Protokoll: [Godot-Meilenstein 0.5.28](build/godot_vehicle_milestone_0.5.28-final_20261102_043041_081/).
- **Android-16-AVD:** Die QA-Release-APK installierte und startete. Archivöffnung per Touch und System-Zurück, Gas, Bremse, Boost, Neigen, Pause, Musikregler und Fortsetzen wurden erkannt. Die Fahrt wurde von 9,36 m auf 9,49 m gespeichert und mit 9,49 m in einem neuen Android-Prozess wiederhergestellt. [Prüfprotokoll](build/android/touch_milestone_0.5.28-final-r1.logcat.txt) · [Archivbild](build/android/touch_milestone_0.5.28-final-r1_archive.png).
- **Installierbare QA-APK:** [Zombie_Escape_Europe-qa-release-0.5.28.apk](build/android/Zombie_Escape_Europe-qa-release-0.5.28.apk) — Version 0.5.28, Code 92, Android API 28–36, nicht debuggable, V2-signiert, 16-KB-ausgerichtet; 167.865.770 Byte, SHA-256 `988D9C55D4BF9CE0D974CE610BD8DDE68C38A6FC2ED8FF7344DF264F99CA6161`. Mit lokalem QA-Testschlüssel signiert, nicht für den Play Store.
- **Godot-Quellpaket:** [Zombie_Escape_Europe_Godot_0.5.28_30-Welten.zip](Zombie_Escape_Europe_Godot_0.5.28_30-Welten.zip) enthält das bearbeitbare Godot-Projekt, Assets, Skripte, Prüfszenen und Entwicklungsunterlagen.
- **Noch nötig bis zum Release:** menschliche Fahr- und Balanceprüfung auf einem echten Android-Telefon, weitere Art-/Levelpolitur, Storekontakt und Datenschutzangaben finalisieren. Das AAB erstellst du wie zuvor vereinbart selbst, wenn du das Spiel als fertig einstufst.

## Stand: 0.5.27 – Zombieklassen und Laufanimationen

- `scripts/terrain.gd` zeichnet langsame, schnelle und robuste Zombies mit unterscheidbaren Körperformen, Haltungen, Kleidungsfarben und Laufbewegungen. Jede Klasse hat drei Farb-/Ausrüstungsvarianten. Die Darstellung wird vollständig aus eigenem Godot-Zeichencode erzeugt.
- `scenes/qa_setpiece_gallery.tscn` zeigt alle 21 Straßenmotive sowie neun Zombie-Beispiele in drei Klassen. Die Zombie-Karten verwenden dieselbe Zeichenroutine wie die Fahrt.
- **Godot-Meilenstein:** Alle 12/12 Abschnitte bestanden; die abschließende gezielte Sichtprüfung bestand mit 21 Motiven, 3 Klassen, 3 Varianten und 3 Galerieseiten. Protokolle: `build/godot_vehicle_milestone_0.5.27-zombie-visuals_20261102_040055_237/` und `build/godot_vehicle_milestone_0.5.27-zombie-final_20261102_040256_821/`.
- **Android-16-AVD:** Die Produktionsszene startete mit dem 80-s-Soundtrack. Sieben aktive Fahr-/Pauseflächen lagen in der sicheren Anzeigefläche. Die Rotterdam-Prüffahrt sprang bei 47,2 km/h ab und passierte das Hindernis ohne Treffer (`hazard_hits=0`). Protokoll: `build/android/touch_milestone_0.5.27-zombie-visual.logcat.txt`.
- **QA-Release-APK:** [Zombie_Escape_Europe-qa-release-0.5.27.apk](build/android/Zombie_Escape_Europe-qa-release-0.5.27.apk) — Code 91, Mindest-API 28, Ziel-API 36, nicht debuggable, V2-signiert und 16-KB-ausgerichtet; 167.851.335 Byte, SHA-256 `4EDE3F46B43838E49C7DC609A142AEB181F983B594AC47031BAF7F3C86C07578`. Lokal mit QA-Testschlüssel signiert, kein Play-Store-Build.
- Die Android-Prüfbilder zeigen [den Rampenabsprung](build/android/touch_milestone_0.5.27-zombie-visual_ramp_launch.png) und [die bestandene Hindernispassage](build/android/touch_milestone_0.5.27-zombie-visual_ramp_result.png).
- Menschliche Fahr- und Balanceprüfung auf einem echten Android-Telefon ist weiter offen. Die Figuren sind prozedurale Prototypgrafik; für die Veröffentlichung brauchen sie noch einen vollständigen visuellen und spielerischen Feinschliff.
- Das AAB wird wie vereinbart erst erstellt, wenn das Spiel fertig ist.

## Stand: 0.5.26 – getrennte Musiklautstärke und Pause-Touch

- Das Pausemenü hat jetzt getrennte Regler für Gesamtlautstärke und Musik sowie einen eigenen Musik-Stummschalter. Die Regler reagieren auf Touch-Drag; die Musiklautstärke ändert den Score unabhängig von Motor- und Spieleffekten.
- Musikpegel und Stummschaltung werden im bestehenden Spielstand gespeichert und nach einem App-Kaltstart geladen. Pause löscht weiter gehaltene Fahrknöpfe, lässt aber Touch-Drags auf Einstellungsreglern weiterlaufen.
- **Godot-Meilenstein:** Der gebündelte Lauf bestand mit 12/12 Abschnitten. Nach der gezielten Korrektur der Pause-Touchverwaltung bestand auch der Audio-/Options-Regressionstest. Protokolle: `build/godot_vehicle_milestone_0.5.26-settings_20261102_033603_457/` und `build/godot_vehicle_milestone_0.5.26_20261102_034401_945/`.
- **Android-16-AVD:** Der 80-s-Soundtrack startete. Gas, Bremse, Boost, Neigen, Pause/Fortsetzen, Musikregler und System-Zurück wurden erkannt. Der Regler speicherte 51 %; nach einem neuen App-Prozess wurde derselbe Wert geladen. Die Fahrstrecke wurde von 54,45 m auf 65,4 m gespeichert und nach Kaltstart wiederhergestellt. Protokoll: `build/android/touch_milestone_0.5.26-audio-options-final.logcat.txt`.
- **QA-Release-APK:** [Zombie_Escape_Europe-qa-release-0.5.26.apk](build/android/Zombie_Escape_Europe-qa-release-0.5.26.apk) — Code 90, Mindest-API 28, Ziel-API 36, nicht debuggable, V2-signiert und 16-KB-ausgerichtet; 167.851.883 Byte, SHA-256 `3043E64FAAD79A10235F1C0EFA11A6A9402DA4B52E064CB7EE521E4A9A5A3B0D`. Es verwendet den lokalen QA-Schlüssel und ist kein Play-Store-Build.
- **Pausemenü-Prüfbild:** [Android-AVD mit 51-%-Musikpegel](build/android/touch_milestone_0.5.26-audio-options-final_pause_music_volume.png).
- **Godot-Quellpaket:** [Zombie_Escape_Europe_Godot_0.5.26_30-Welten.zip](Zombie_Escape_Europe_Godot_0.5.26_30-Welten.zip) — enthält Projekt, Soundtrack, Generator, QA-Skripte und Dokumentation; APKs, AABs, Caches und Keystore-Dateien sind ausgeschlossen.
- Der AVD bestätigt Bedienung und Speicherung, aber nicht den Klangeindruck auf einem echten Telefon. Eine Hör- und Notchprüfung an Zielhardware bleibt offen.

## Stand: 0.5.25 – Originalmusik und adaptiver Crossfade

- `assets/audio/road_theme.wav` ist ein neu komponiertes, 80 Sekunden langes Instrumentalstück. `tools/generate_road_score.js` erzeugt die WAV-Datei reproduzierbar aus eigener Synthese; es verwendet keine Musikdateien des Referenzspiels.
- `scripts/audio_manager.gd` startet die Musik in der Produktionsszene. Garage, Karte, Fahrt, Pause, Ergebnis und Finale erhalten eigene Lautstärken; Funk und Boost senken die Musik bei Bedarf ab.
- Zwei Audiodecks überblenden das Ende der Musik jeweils vier Sekunden lang und wechseln sich bei der Wiederholung ab. Vorhandene Motor-, Boost-, Treffer-, Münz- und UI-Sounds bleiben eingebunden.
- **Godot-Audiomeilenstein:** Laufzeitprüfung bestanden: 80-s-Track lädt und startet; Zustandsmischung für Garage/Fahrt/Pause/Funk/Finale und beide abwechselnden Crossfades funktionieren. Die elf vorherigen Abschnitte hatten bereits bestanden; der Audioblock bestand danach im gezielten Nachlauf. Protokolle: `build/godot_vehicle_milestone_0.5.25_20261102_032024_572/` und `build/godot_vehicle_milestone_0.5.25_20261102_032403_483/`.
- **Android-16-AVD:** Die Produktionsszene meldete `music_started=true`, `duration_s=80.00` und `crossfade_s=4.00`. Die Rotterdam-Prüffahrt sprang bei 47,2 km/h ab und passierte den Container ohne Treffer (`hazard_hits=0`). Alle sieben aktiven Fahr-/Pause-Hitboxen lagen innerhalb der vom AVD gemeldeten freien Fläche. Prüfprotokoll: `build/android/touch_milestone_0.5.25-audio.logcat.txt`.
- **QA-Release-APK:** [Zombie_Escape_Europe-qa-release-0.5.25.apk](build/android/Zombie_Escape_Europe-qa-release-0.5.25.apk) — Code 89, Mindest-API 28, Ziel-API 36, nicht debuggable, V2-signiert und 16-KB-ausgerichtet; 167.850.079 Byte, SHA-256 `864522C9B4B903A05BFA0BD30B8679C8524C7E25CE9023D1C9582F7C7BAAE466`.
- **Rampen-QA-APK:** [Zombie_Escape_Europe-qa-ramp-0.5.25.apk](build/android/Zombie_Escape_Europe-qa-ramp-0.5.25.apk) — gleicher Versions- und Signaturcheck; startet zusätzlich die automatisierte Rotterdam-Prüfszene. Beide APKs verwenden den lokalen QA-Testschlüssel und sind keine Play-Store-Builds.
- AVD-Bilder: [Rampe](build/android/touch_milestone_0.5.25-audio_ramp_launch.png) und [Rampenprüfung bestanden](build/android/touch_milestone_0.5.25-audio_ramp_result.png).
- **Godot-Quellpaket:** [Zombie_Escape_Europe_Godot_0.5.25_30-Welten.zip](Zombie_Escape_Europe_Godot_0.5.25_30-Welten.zip) — enthält das Projekt, den WAV-Soundtrack, den Generator, Dokumentation und QA-Skripte; APKs, AABs, Caches und Keystore-Dateien bleiben ausgeschlossen.
- Die AVD-Prüfung bestätigt Start und Einbindung, aber keine menschliche Hörbeurteilung auf einem Telefon. Lautstärke, Mischung und Wiederholung sollen später auf echter Android-Hardware angehört werden. Das Play-Store-AAB wird wie vereinbart erst nach Fertigstellung erstellt.

## Stand: 0.5.24 – sichere Android-Bildschirmränder

- Die HUD-Anordnung liest auf Android und iOS die vom Betriebssystem gemeldete freie Displayfläche aus und wandelt sie über Godots Viewport- und Canvas-Transformation in die Spielkoordinaten um.
- Fahrknöpfe, Pausefläche, Live-Fahranzeigen, Hinweise, Werkstatt-Eckaktionen, Kartenabschluss, Tutorial und Rettungssequenz halten Abstand zu Aussparungen und Systemleisten. Maus-/Desktop-Layout bleibt unverändert.
- Die Android-Rampenprüfung protokolliert die ermittelten Ränder und zählt alle aktiven Fahr-/Pause-Hitboxen gegen die freie Fläche. Ein Lauf schlägt fehl, wenn eine dieser Flächen außerhalb liegt.
- **Godot-Meilenstein:** 11/11 Abschnitte bestanden. Protokoll: `build/godot_vehicle_milestone_0.5.24_20261102_030438_183/`.
- **Android-16-AVD:** Die echte Produktionsszene meldete `SAFE_AREA_QA PASS`, 7 interaktive Fahr-/Pause-Hitboxen innerhalb der Fläche und 0 außerhalb. Das AVD meldete 1600×720 logische Pixel ohne Aussparungs-Inset. Der Kombi sprang in Rotterdam mit Motor 1/Tank 1 bei 47,2 km/h ab und passierte den Container ohne Treffer (`hazard_hits=0`).
- **QA-Release-APK zum Installieren:** [Zombie_Escape_Europe-qa-release-0.5.24.apk](build/android/Zombie_Escape_Europe-qa-release-0.5.24.apk) — Code 88, Mindest-API 28, Ziel-API 36, nicht debuggable, V2-signiert und 16-KB-ausgerichtet; 166.568.441 Byte, SHA-256 `03DF8A09B3139A3FFC1306710BB9755F8B291B11C207F62E1EC0A9C35D43EE0A`. Internes QA-Build mit lokalem Godot-Testschlüssel, nicht das Play-Store-Paket.
- **Rampen-QA-APK:** [Zombie_Escape_Europe-qa-ramp-0.5.24.apk](build/android/Zombie_Escape_Europe-qa-ramp-0.5.24.apk) — dieselbe Build-/Signaturprüfung; startet absichtlich die automatisierte Rotterdam-Prüfszene und ist nur für QA bestimmt.
- AVD-Prüfbilder: [Absprung](build/android/touch_milestone_0.5.24-safe-area_ramp_launch.png) und [Hindernis bestanden](build/android/touch_milestone_0.5.24-safe-area_ramp_result.png). Prüfprotokoll: `build/android/touch_milestone_0.5.24-safe-area.logcat.txt`.
- **Godot-Quellpaket:** [Zombie_Escape_Europe_Godot_0.5.24_30-Welten.zip](Zombie_Escape_Europe_Godot_0.5.24_30-Welten.zip) — enthält Projekt, Assets, Dokumentation und QA-Skripte; APKs, AABs, Caches und Keystore-Dateien sind ausgeschlossen.
- Ein echtes Telefon mit Aussparung muss die vom Gerät gelieferten Insets und menschliche Erreichbarkeit noch bestätigen. Die AVD meldet keine Aussparung. Das Play-Store-AAB wird wie vereinbart erst nach Fertigstellung erstellt.

## Stand: 0.5.23 – fahrbare Sprunghindernisse und Kampagnenziele

- Die fünf Etappen mit dem optionalen „Hindernis sauber überspringen“-Ziel haben nun vor dem Hindernis einen echten Hügel. Seine Höhe wird von Geländezeichnung und Fahrbahn-Kollision gemeinsam verwendet; die Rampe gibt dem Fahrzeug bei ausreichender Geschwindigkeit einen tatsächlichen Aufwärtsimpuls. Das Ziel zählt weiterhin nur, wenn die Landung ohne Treffer gelingt. Die separate Rettungsmission nutzt dasselbe Rampensystem.
- Die optionalen Münz- und Zustandsziele wurden für die Startausrüstung nachjustiert. Reggio Calabria hat zusätzlich einen Reparaturkasten nahe dem Ende der Etappe.
- Alle elf Godot-Meilensteinblöcke bestanden. Die automatisierte Vollkampagnenprüfung schloss alle 30 Welten mit 30/30 Etappenzielen und zusätzlich die Rettungsmedaille ab. Das ist ein reproduzierbarer Physiksimulationslauf; echte menschliche Balance ist damit noch nicht bestätigt.
- **Optimiertes QA-Release-APK (intern, nicht für Play Store):** [Zombie_Escape_Europe-qa-release-0.5.23.apk](build/android/Zombie_Escape_Europe-qa-release-0.5.23.apk) — Code 87, Mindest-API 28, Ziel-API 36, nicht debuggable, V2-signiert und 16-KB-ausgerichtet; 166.558.452 Byte, SHA-256 `A1064394EE8817C87921D1BB7E0A4134BF853C34092602010A7D02D396F1A4F6`. Es verwendet den lokalen Godot-Testschlüssel.
- **Debug-APK:** [Zombie_Escape_Europe-debug-0.5.23.apk](build/android/Zombie_Escape_Europe-debug-0.5.23.apk) — 179.705.937 Byte, SHA-256 `133FCDB9614BE92A1FA973F9DC7C0F13BD9E447AE807C17D69D0E9C7F7AAA0BA`.
- Der Android-16-AVD installierte und startete das optimierte QA-Release. Gas, Bremse, Boost, Neigen links/rechts, Pause/Fortsetzen und System-Zurück wurden erkannt. Der Spielstand stieg von 47,85 m auf 56,73 m und wurde nach einem Kaltstart in einem neuen Prozess als 56,73 m wiederhergestellt.
- Ein rampenspezifischer Android-QA-Lauf verwendet die Produktionsszene in einer separaten Testszene. Auf Rotterdam mit der empfohlenen Anfangsausrüstung Motor 1/Tank 1 bildete die Straße eine 36,79-Pixel-Rampe. Der Kombi löste bei 47,2 km/h den Absprung aus, war in der Luft und passierte das Hindernis ohne Treffer. Ein weiterer Lauf in Lyon mit stärkerer Ausstattung bestand ebenfalls. Im geprüften Spielprozess-Log fanden sich keine Absturz- oder ANR-Marker. Diese automatisierten Emulatorläufe ersetzen keine menschliche Fahrt auf einem echten Telefon.
- `scenes/qa_ramp_test.tscn`, `scripts/qa_ramp_test.gd` und `-RampQaSmoke` in `tools/android_touch_milestone.ps1` prüfen die Rampe gezielt. `tools/export_android_qa_release.ps1` kann dafür eine separate QA-Hauptszene exportieren. Der Exporthelfer übernimmt eine stabile Gradle-Ausgabe, wenn Godot nach dem erfolgreichen APK-Build nicht beendet wird, und validiert danach Paketdaten, Testsignatur und 16-KB-Ausrichtung.
- **Godot-Quellpaket:** [Zombie_Escape_Europe_Godot_0.5.23_30-Welten.zip](Zombie_Escape_Europe_Godot_0.5.23_30-Welten.zip) — enthält Projekt, Assets, Dokumentation und QA-Skripte; APKs, AABs, Caches und Keystore-Dateien sind ausgeschlossen.
- Das Play-Store-AAB wird wie vereinbart erst nach Fertigstellung mit dem privaten Upload-Keystore erstellt.

## Vorheriger Stand: 0.5.22 – lesbare Straßenbegegnungen

## Stand: 0.5.22 – lesbare Straßenbegegnungen

- `scripts/terrain.gd` hebt alle 21 Begegnungsmotive mit klareren Silhouetten, hellen Kanten, Bodenschatten und besser getrennten Formen hervor. Tunnelsturz, Straßenblockade, Altstadtsperre, Brückenschutt, Säulentrümmer und Flugzeugtrümmer sind visuell eigenständiger. Fahrphysik, Position und Schadenwerte wurden dabei nicht geändert.
- Die QA-Szene `scenes/qa_setpiece_gallery.tscn` rendert alle 21 Motive über dieselbe Zeichenroutine wie das Spiel. Sie speichert zwei geprüfte 1280×720-Galerieseiten in `build/setpiece_visual_review/`.
- Alle elf Godot-Meilensteinblöcke bestanden, darunter Kampagne, Tutorial, Fahrzeuge, Upgrades, Schlusssequenz, Einstiegsbalance, 30 Ereignisprofile und der echte Bildlauf für alle Motive. Protokoll: `build/godot_vehicle_milestone_0.5.22-visual-pass_20261102_011359_368/`.
- Ein zusätzlicher Langtest mit frischem, isoliertem Spielstand schloss alle 30 Stadtwelten und die 950-m-Rettungsfahrt in 202,2 s beim ersten Versuch pro Welt ab. Die automatisierte Steuerung nutzte das Motor-1-/Tank-1-Startpaket, kaufte im Verlauf weitere Upgrades und lenkte Sprünge regelbasiert aus. Messina endete mit 13,5 % Fahrzeugzustand; menschliche Android-Balance ist damit nicht nachgewiesen. Reproduzierbar über `tools/godot_campaign_completion_audit.ps1`; Protokoll: `build/campaign_completion_audit_0.5.22-30-welten_20261102_014135_845/`.
- Der Kampagnentest beendet Godot mit Exitcode 0 und dem Erfolgsmarker. Beim Testprozess-Abbau erschienen zusätzlich Godot-Meldungen zu zwei verbliebenen ObjectDB-Instanzen und einer Ressource; das erfordert eine spätere Bereinigung des QA-Lebenszyklus, ist kein Spielabsturz und änderte den erfolgreichen Kampagnenlauf nicht.
- **QA-Release-APK (intern, nicht für Play Store):** [Zombie_Escape_Europe-qa-release-0.5.22.apk](build/android/Zombie_Escape_Europe-qa-release-0.5.22.apk) — Version 0.5.22 / Code 86, Android API 28–36, nicht debuggable, V2-signiert, 16-KB-ausgerichtet; 166.555.920 Byte, SHA-256 `2A7F1FA4F1A91C88124041E9B8828FB2DEDC32F0A6D6A6105E42DB7B8C66A825`. Es verwendet den lokalen Godot-Testschlüssel.
- **Debug-APK:** [Zombie_Escape_Europe-debug-0.5.22.apk](build/android/Zombie_Escape_Europe-debug-0.5.22.apk) — 179.703.417 Byte, SHA-256 `F6EDF1743657D3A2DC54405912E8A1F023285DEC3288A9700A4D7405260BAE2A`.
- Der Android-16-AVD installierte und startete 0.5.22. Er erkannte Gas, Bremse, Boost, Neigen links/rechts, Pause und Fortsetzen; Android-Zurück pausierte, führte zurück zur Garage und beendete die App. Fortschritt von 41,96 m wurde beim Kaltstart mit einer neuen Prozess-ID als 47,65 m geladen. Im durchsuchten Logcat kein Spielabsturz, ANR oder Shaderfehler. Das Emulatorbild prüft keine echte Telefonleistung und fuhr nicht bis zu den Hauptbegegnungen.
- **Godot-Quellpaket:** [Zombie_Escape_Europe_Godot_0.5.22_30-Welten.zip](Zombie_Escape_Europe_Godot_0.5.22_30-Welten.zip) — 79 Dateien einschließlich des Langtests und Exporthelfers. CRC- und Inhaltsprüfung umfasst Projekt und QA-Skripte, keine APKs, Android-Builds, Godot-Caches oder Schlüssel im Archiv.
- Bericht und Screenshots des Touchlaufs: `build/android/touch_milestone_0.5.22-visual-pass*`. Das Play-Store-AAB wird wie vereinbart erst nach Fertigstellung mit dem privaten Upload-Keystore erstellt.

## Vorheriger Stand: 0.5.21 – 30 gestaltete Straßenbegegnungen

- Jede der 30 Städte hat ein eigenes, datengetriebenes Straßenereignis mit passendem Namen, Bildmotiv und abgestuften Fahrfolgen. Die Motive reichen von Containerpassagen, Kanal- und Brückenschutt über Tunnelstürze und Straßenbahnwracks bis zum Evakuierungskorridor in Messina.
- Die Begegnung bleibt an der bestehenden Streckenposition bei 64 Prozent. So bleiben Etappenlänge, einmaliges Sauber-Hindernis-Ziel und Fahrbalance unverändert; die Warnanzeige übernimmt nun die stadtbezogenen Namen.
- `scripts/campaign_data.gd` enthält 30 vollständige Profile; `scripts/terrain.gd` zeichnet die Motive im bestehenden Godot-Stil und wertet sie in der bestehenden Hindernisphysik aus.
- Alle zehn Godot-Meilensteinblöcke bestanden. Die neue Prüfung fand 30 vollständige Laufzeitprofile, 21 Bildmotive, genau eine Haupthindernis-Begegnung je Stadt und passende 140-Meter-Warnungen.
- Die früher geprüfte automatisierte Fahrstrategie schloss weiterhin Amsterdam bis Luxemburg ab; das ist ein Physiksimulationslauf und ersetzt keine menschliche Android-Touchfahrt.
- Das Android-16-AVD installierte 0.5.21 und erkannte Gas, Bremse, Boost, beide Neigerichtungen, Pause/Fortsetzen und Android-Zurück. Nach App-Wechsel/Kaltstart wurden 50,57 m geladen; vor der Unterbrechung waren 47,84 m erfasst. Kein ANR, Absturz oder Shaderfehler im geprüften Log. Emulatorleistung ist kein Telefon-Leistungsnachweis.
- **QA-Release-APK (intern, nicht für Play Store):** [Zombie_Escape_Europe-qa-release-0.5.21.apk](build/android/Zombie_Escape_Europe-qa-release-0.5.21.apk) — Code 85, Android API 28–36, nicht debuggable, V2-signiert, 16-KB-ausgerichtet; 166.545.207 Byte, SHA-256 `6B9C3655EC35CFD705B1F4A07CF49C6551D468D60D2C691E9184647F970C4973`.
- **Debug-APK:** [Zombie_Escape_Europe-debug-0.5.21.apk](build/android/Zombie_Escape_Europe-debug-0.5.21.apk) — 179.692.660 Byte, SHA-256 `7B4BE696B01BCA237D4A0813447DDC7982F94F9E6663B71C4F1595127E7C0834`.
- **Aktuelles Godot-Quellpaket:** [Zombie_Escape_Europe_Godot_0.5.21_30-Welten.zip](Zombie_Escape_Europe_Godot_0.5.21_30-Welten.zip) — 74 Dateien. Es enthält Projekt, Grafiken, Skripte, Meilensteinprüfungen und Exportskripte; Android-Builds, Cache und Schlüsselmaterial sind ausgeschlossen.
- Godot-Protokoll: [Meilensteinlauf 0.5.21](build/godot_vehicle_milestone_0.5.21-authored_setpieces-r1_20261102_005307_073/10_campaign_setpiece_system.log). Der vollständige Touchbericht und Screenshots liegen unter `build/android/touch_milestone_0.5.21-setpieces*`. Das Play-Store-AAB wird wie vereinbart erst bei Fertigstellung mit dem Upload-Keystore erstellt.

**Vorheriger Stand: 0.5.20 – Messina-Schlusssequenz und Einstiegsbalance**

## Stand: 0.5.20 – Messina-Schlusssequenz und Einstiegsbalance

- Nach der letzten Hafenfahrt folgt jetzt eine 12-sekündige, überspringbare Schlusssequenz: Abendhafen, Rettungsschiff mit Lichtsignal, wartender Kombi und Überlebende, die an Bord gehen. Drei Textkapitel führen vom Südpiersignal über die Evakuierung zum Abschluss der Europaflucht.
- `scripts/hud.gd` zeichnet Szene und Animation direkt in Godot; der sichtbare WEITER-Knopf, ESC/Leertaste/Enter und Android-Zurück überspringen sie. Nach dem Abschluss erscheint der Kampagnensieg.
- Speicherschema 7 merkt sich, ob das Finale gesehen oder übersprungen wurde. Ein älterer v6-Spielstand mit erreichter Rettung bekommt die Szene genau einmal; ein gespeichertes Finale startet danach direkt im Siegbildschirm.
- Godot-Meilenstein: alle neun Prüfblöcke bestanden, darunter der HUD-Zeichenlauf, Finalkapitel, Touchknopf, Android-Zurück, Speichern, v6-Migration und erste Fünf-Welten-Balance.
- Ein frisches Profil schloss die Welten Amsterdam bis Luxemburg mit Motor 1 und Tank 1 ab. Im automatischen Fahrphysiklauf blieben in Luxemburg 28,7/92 Kraftstoff und 55 % Zustand; niedrigste gemessene Fahrtgeschwindigkeit in den fünf Welten lag bei 44,6 km/h. Der Lauf hält Gas, setzt Boost am Berg und korrigiert Sprünge automatisch – menschliches Touch-Feedback bleibt offen.
- Der Android-16-AVD-Lauf erkannte Gas, Bremse, Boost, beide Neigerichtungen, Pause und Fortsetzen. 37,62 m wurden beim Unterbrechen zu 40,43 m gespeichert und nach Kaltstart mit 40,43 m geladen; im geprüften Lauf kein Spiel-ANR oder App-Absturz.
- Version 0.5.20 / Android-Code 84. Das QA-Release ist ein internes Test-APK mit lokalem Godot-Testschlüssel, nicht das Play-Store-Paket. AAB und privater Upload-Schlüssel wurden wie vereinbart nicht verwendet.

**Optimiertes QA-Release-APK (intern, nicht für Play Store):** [`build/android/Zombie_Escape_Europe-qa-release-0.5.20.apk`](build/android/Zombie_Escape_Europe-qa-release-0.5.20.apk) — Paket `com.zombieescapeeurope.game`, Mindest-API 28, Ziel-API 36, nicht debuggable, V2-signiert und 16-KB-ausgerichtet; 166.536.307 Byte, SHA-256 `D9CB151A28095339C46CF0E786B5418E4F002AAE0378B6F96A1C5D37BF32A261`.

**Android-Debug-APK:** [`build/android/Zombie_Escape_Europe-debug-0.5.20.apk`](build/android/Zombie_Escape_Europe-debug-0.5.20.apk) — 179.683.756 Byte, SHA-256 `C6D85757F611A5BA65462593521BC5B81447FA6ED66537D895008B23DFF71806`.

**Godot-Quellpaket:** [`Zombie_Escape_Europe_Godot_0.5.20_30-Welten.zip`](Zombie_Escape_Europe_Godot_0.5.20_30-Welten.zip), 73 Dateien. Frisch entpackt und mit Godot 4.7.2 importiert. Es enthält Projekt, Assets, Dokumentation, Tests und Exportskripte; APKs, AABs, temporäre Android-Builds, Godot-Cache und Keystores sind ausgeschlossen.

## Stand: 0.5.18 – Android-System-Zurück-Taste

- Android-Zurück pausiert eine laufende Fahrt; ein neuer Tastendruck führt aus der Pause in die Garage. Karte und Ergebnisbildschirme kehren in die Garage zurück, während Zurück in der Garage das Spiel beendet.
- Datenschutzfenster schließen sich zuerst. Im Erstfahrt-Tutorial führt Zurück eine Seite zurück. Verzögerte Doppelereignisse der Android-Taste werden eine Sekunde entprellt, damit eine einzelne Betätigung nicht zwei Menüzustände überspringt.
- Der Godot-Meilenstein bestand: Fahrzeugauswahl und Fahrphysik, Tutorial, 30 Etappenziele, Speichermigration, 192 Fahrzeug-/Upgradeprofile und die neuen Zurück-Tasten-Übergänge.
- Der vollständige Android-16-AVD-Touchlauf erkannte Gas, Bremse, Boost, Neigen links/rechts, Pause und Fortsetzen. Android-Zurück pausierte die Fahrt; das verzögerte Doppelereignis wurde abgefangen; der nächste Tastendruck öffnete die Garage. Eine neue Fahrt ließ sich starten. Android-Home speicherte 39,33 m (vor der Unterbrechung: 34,57 m); ein neuer Prozess lud 39,33 m. Zurück in der Garage beendete den Prozess.
- Im geprüften Android-Log gibt es keinen ANR, App-Absturz oder Shaderfehler. Der AVD ist sehr langsam und kein Leistungsnachweis für ein echtes Telefon.

**Optimiertes QA-Release-APK (intern, nicht für Play Store):** [`build/android/Zombie_Escape_Europe-qa-release-0.5.18.apk`](build/android/Zombie_Escape_Europe-qa-release-0.5.18.apk) — Version 0.5.18 / Code 82, Paket `com.zombieescapeeurope.game`, Mindest-API 28, Ziel-API 36, nicht debuggable, V2-Signatur, 16-KB-ausgerichtet; 166.526.679 Byte, SHA-256 `D0E112E5976F8ECAA80F34F9734657AF43E8AA0C6487687A18B936ED7CA4B596`. Es ist mit dem lokalen Godot-Testschlüssel signiert.

**Android-Debug-APK:** [`build/android/Zombie_Escape_Europe-debug-0.5.18.apk`](build/android/Zombie_Escape_Europe-debug-0.5.18.apk) — 179.674.140 Byte, SHA-256 `6280EB32ECB76B7BECD1DF9A197D5A38C13937C2119DB2755B42F820DE6227FD`.

**Godot-Quellpaket:** [`Zombie_Escape_Europe_Godot_0.5.18_30-Welten.zip`](Zombie_Escape_Europe_Godot_0.5.18_30-Welten.zip), 70 Dateien. Es enthält Projekt, Assets, QA-Diagnose, Android-Tests, Exportskripte und ein Packskript; Build-Ausgaben, APKs, Godot-Cache und Keystores sind ausgeschlossen.

## Vorheriger Stand: 0.5.17 – wiederverwendete Straßen-Zeichenpuffer

- `scripts/terrain.gd` verwendet für Straßenfüllung, Straßenkante und Bankette wiederverwendete `PackedVector2Array`-Puffer statt bei jeder Neuzeichnung neue Punktlisten und Kopien zu erzeugen. Straßenhöhen, Kollisionskörper, Fahrphysik und Streckenlayout bleiben gleich.
- Der Godot-Meilenstein bestand mit Fahrzeugauswahl und Physikfahrt, Erstfahrt-Tutorial, 30 Etappenzielen, Speichermigration sowie 192 Fahrzeug-/Upgradeprofilen.
- Der Android-16-AVD-Lauf erkannte alle sieben Touchaktionen. Nach Android-Home bestätigte die Telemetrie mindestens 22,93 m gespeicherten Fortschritt; der neue Prozess lud 26,71 m. Der höhere geladene Wert blieb erhalten. Kein App-ANR, Absturz oder Shaderfehler im Log.
- Der AVD lieferte in diesem Lauf 15 Proben mit Median 1 FPS (Spanne 1–13), median 625 ms Prozesszeit und 148 ms Physikzeit. Das ist langsamer als der vorherige 0.5.16-Lauf und belegt keinen Leistungsgewinn. Die virtuelle GPU und Emulatorlast schwanken stark; ein Telefonvergleich ist offen.
- Der QA-Exporthelfer baut jetzt Debug-APK und optimiertes Release-APK gemeinsam, prüft Versionsdaten und bestätigt denselben lokalen Tests Schlüssel. Das Release bleibt nicht debuggable; die Play-Store-Vorlage enthält keine QA-Diagnosefunktion.

**Optimiertes QA-Release-APK (intern, nicht für Play Store):** [`build/android/Zombie_Escape_Europe-qa-release-0.5.17.apk`](build/android/Zombie_Escape_Europe-qa-release-0.5.17.apk) — Version 0.5.17 / Code 81, Paket `com.zombieescapeeurope.game`, Mindest-API 28, Ziel-API 36, nicht debuggable, V2-Signatur, 16-KB-ausgerichtet; 166.525.643 Byte, SHA-256 `507FC32E3DBD77E70F16FA86DE06F202BFD963818EF0F5AC22EA784072EAD6FA`. Es ist mit dem lokalen Godot-Testschlüssel signiert.

**Android-Debug-APK:** [`build/android/Zombie_Escape_Europe-debug-0.5.17.apk`](build/android/Zombie_Escape_Europe-debug-0.5.17.apk) — 179.673.088 Byte, SHA-256 `6673C5235412E59B88F1EDE0B06662224E6192C3C34109EB96C2B085FAA4EDAB`.

**Godot-Quellpaket:** [`Zombie_Escape_Europe_Godot_0.5.17_30-Welten.zip`](Zombie_Escape_Europe_Godot_0.5.17_30-Welten.zip). Es enthält Projekt, Assets, QA-Diagnose und Skripte; Build-Ausgaben, APKs, Godot-Cache und Keystores sind ausgeschlossen.

## Vorheriger Stand: 0.5.16 – Fahrzeugphysik und Android-QA-Release

- Wirksame Motor- und Boostkraft, Höchstgeschwindigkeit, Federung, Drehmomente und Hindernisschaden werden beim Fahrzeugwechsel beziehungsweise bei Upgrade-Käufen berechnet und zwischengespeichert. Der Physikschritt fragt diese Werte nicht mehr pro Tick aus den Fahrzeug-Dictionaries ab.
- Ein Godot-Meilenstein prüfte 192 Kombinationen über drei Fahrzeuge sowie Motor-, Reifen- und Panzerungsstufen. Die gecachten Werte und Hindernisschäden stimmen mit den ursprünglichen Fahrzeugdaten überein; Fahrzeug-, Tutorial- und 30-Ziele-Regressionen bestanden.
- Der vollständige Android-16-AVD-Lauf mit dem optimierten QA-Release erkannte Fahrtstart, Gas halten/loslassen, Bremse, Boost, Neigen links/rechts, Pause und Fortsetzen. Nach Android-Home wurden 45,06 m gespeichert und nach einem Kaltstart in einem neuen Prozess exakt mit 45,06 m wieder geladen.
- Im Android-Log stehen keine App-ANR-, Absturz- oder Shaderfehler. Der virtuelle Emulator bleibt sehr langsam und schwankend: 19 Laufzeitproben, Median 2 FPS (Spanne 1–20), 413 ms mediane Prozesszeit und 136 ms mediane Physikzeit. Das ist keine Leistungsfreigabe für ein echtes Telefon.
- Ein neues Exportskript erstellt ein optimiertes, **nicht debuggable** QA-Release und prüft Paketkennung, Version, Android-API, Signatur und 16-KB-Ausrichtung. Es wird nur mit dem lokalen Godot-Testschlüssel signiert; das separate Play-Store-Profil enthält keine QA-Diagnosefunktion.
- Das Play-Store-AAB ist nicht erstellt. Wie vereinbart wird es erst nach Fertigstellung mit dem privaten Upload-Keystore erzeugt.

**Optimiertes QA-Release-APK (separates Build-Artefakt, nicht im Quell-ZIP):** [`build/android/Zombie_Escape_Europe-qa-release-0.5.16.apk`](build/android/Zombie_Escape_Europe-qa-release-0.5.16.apk) — Version 0.5.16 / Code 80, Paket `com.zombieescapeeurope.game`, Mindest-API 28, Ziel-API 36, nicht debuggable, V2-Signatur, 16-KB-ausgerichtet; 166.525.375 Byte, SHA-256 `EB93054B85DE6BCB976A4CD0C3C101DA04C9B91920016070E5123429537E22EE`. Es ist ein internes Testpaket, kein Play-Store-Build.

**Android-Debug-APK:** [`build/android/Zombie_Escape_Europe-debug-0.5.16.apk`](build/android/Zombie_Escape_Europe-debug-0.5.16.apk) — 179.671.413 Byte, SHA-256 `F64715E0594770964B1AB766A2DC09D0D1AE33D437D25CDD643EF3FB2C1B8D6F`.

**Godot-Quellpaket:** [`Zombie_Escape_Europe_Godot_0.5.16_30-Welten.zip`](Zombie_Escape_Europe_Godot_0.5.16_30-Welten.zip). Es enthält das Projekt, QA-Diagnose und Export-/Testskripte, ohne Build-Ausgaben, Godot-Cache, APK oder Keystore.

## Stand: 0.5.15 – HUD-Korrektur und Android-Meilenstein

- Im Fahr-HUD stehen jetzt Routenname, nächstes Versorgungsziel und Reststrecke in getrennten Zeilen. So überlappen die Texte auf der 1600×720-Spielansicht nicht mehr.
- Der vollständige Android-Touchlauf bestand auf einem isolierten Android-16-AVD: Start, Gas halten/loslassen, Bremse, Boost, Neigen links/rechts, Pause und Fortsetzen.
- Android-Home unterbrach die Fahrt; der gespeicherte Kilometerstand stieg von 21,18 m auf 25,09 m. Ein Kaltstart in einer neuen Android-Prozess-ID lud anschließend die Garage.
- Im erfassten Log stehen keine App-ANR-, Absturz- oder Shaderfehler. Die AVD bleibt sehr langsam und schwankend; ihre Bildrate ist kein Nachweis für ein echtes Telefon. Ein Telefon-Leistungstest bleibt offen.
- Das Debug-APK ist mit dem Godot-Debugschlüssel signiert. Es ist kein Play-Store-Build; das AAB wird wie vereinbart erst nach Fertigstellung erstellt.

**Android-Test-APK 0.5.15:** [`build/android/Zombie_Escape_Europe-debug-0.5.15.apk`](build/android/Zombie_Escape_Europe-debug-0.5.15.apk) — 179.671.237 Byte, SHA-256 `72D30707C0291CCAD1B14449E3BD6414FDF8D79189EF76B65F94FF1B47DF9B29`.

**Godot-Quellpaket 0.5.15:** [`Zombie_Escape_Europe_Godot_0.5.15_30-Welten.zip`](Zombie_Escape_Europe_Godot_0.5.15_30-Welten.zip). Es enthält Assets, Szenen, Skripte, Exportprofile und Dokumentation, ohne Build-Ausgaben, Cache, APK oder Keystore.

## Stand: 0.5.14 – Streckenberechnung für Android

- Die Zeichenwerte aus 0.5.13 bleiben zwischengespeichert: Geländepunkte, Straßenrand-Höhen, Streckenobjekte, Schilder und die Welt-Farbprofile werden pro Weltwechsel vorbereitet.
- `height_at()` löst Schwierigkeitsgrad, Welt-Seed, Themenfaktor und Höhenprofil jetzt einmal beim Weltwechsel auf. Physik und Kollision fragen weiterhin dieselbe Höhenformel für ihre tatsächlichen Positionen ab.
- Über 18.631 Höhenproben aus allen 30 Welten und der 950-m-Rettungsroute stimmen die neuen Werte exakt mit der bisherigen Formel überein (`max_error=0`).
- Das Android-API-36-Testprofil bestand Installation, Kaltstart, alle fünf Fahraktionen, Pause/Weiterfahrt, App-Unterbrechung, Speichern und erneuten Kaltstart; Details zum späteren vollständigen Lauf stehen im 0.5.15-Abschnitt.
- Die AVD-Messung bleibt unbrauchbar für eine Telefonfreigabe: 16 Laufzeitproben, median 1 FPS, Prozesszeit 605 ms und Physikzeit 103 ms; die Streuung ist sehr groß. Ein echter Android-Gerätevergleich bleibt nötig.
- Das damalige Test-APK ist intern und mit einem Debugschlüssel signiert. Das Play-Store-AAB wird wie vereinbart erst nach Fertigstellung erstellt.

## Stand: 0.5.13 – vorberechnete Streckenzeichnung

- Gelände-Höhen an den festen Zeichenpunkten, Straßenrand-Pfosten, Objektpositionen und Routenschilder werden beim Laden einer Welt vorberechnet. Die Fahrt zeichnet diese Daten aus einem Cache.
- Physik und Straßenkollision verwenden weiter `height_at()` und dieselben Höhenprofile. Die Optimierung ändert keine Fahrwerte oder Streckenform.
- Die statischen Farbprofile der Hintergrundkulissen werden ebenfalls nur beim Weltwechsel ermittelt.
- Android-Touch-, Pause- und Speichertest bestanden; Details und Bildzeitvergleich stehen im 0.5.14-Abschnitt dieses Berichts.

## Stand: 0.5.12 – dritte Fahrzeugklasse

- Der Gelände-Pickup wird nach Alicante (Welt 15) freigeschaltet. Seine eigene Karosserie, größeren Räder, breitere Achsen, verstärkte Karosserie-Kollision, höhere Federkraft, anderes Gewicht, mehr Zug und separate Upgrades sind in die Fahrt und Werkstatt eingebunden.
- Der Werkstattwechsel läuft durch alle freigeschalteten Fahrzeuge. Eine Fortschrittszeile nennt weiterhin das nächste Fahrzeug und den Freischaltort.
- Spielstände aus Schema 5 werden auf Schema 6 migriert; Strecke, Münzen, gewähltes Fahrzeug und vorhandene Upgrades bleiben erhalten. Alte Profile jenseits von Alicante erhalten den Pickup automatisch.
- Godot 4.7.2 importierte das neue Sprite. Fahrzeug-, Tutorial- und Kampagnenziel-Regressionsläufe bestehen; der Pickup fährt in der echten Physikszene.
- Debug-APK 0.5.12 ist auf einer isolierten Android-16-AVD installiert. Ein vollständiger Touch-Meilenstein bestätigte Fahrtstart, Gas halten/loslassen, Bremse, Boost, Neigen links/rechts, Pause und Weiterfahren.
- Android-Home pausierte die Fahrt und speicherte den Fortschritt. Der Stand stieg beim Unterbrechen von 54,7 m auf 56,4 m; nach `force-stop` und Kaltstart lud die Garage rund 0,1 km erneut. Der bestehende AVD-Spielstand blieb unangetastet; keine ANR-, Absturz- oder Shaderfehler im Testlog.
- Die AVD zeigte während der Debugfahrt niedrige und stark schwankende Bildraten. Das ist keine Leistungsfreigabe: ein echtes Android-Telefon, Displaygrößen, Wärme und längere Fahrten müssen noch geprüft werden. Das Android-System blendet beim ersten Vollbildstart einmalig eine Bestätigung ein; der Testablauf bestätigt sie vor dem Pausentouch.
- Für Wiederholungen gibt es `tools/android_touch_milestone.ps1`; der Kaltstartlauf erforderte einmal eine zweite explizite Aktivitätsstart-Anforderung. Das Hilfsskript enthält dafür jetzt eine automatische Startwiederholung.
- Versionsdaten, V2-Signatur und 16-KB-Ausrichtung sind geprüft; kein AAB wurde erstellt.

**Historisches Test-APK 0.5.14:** `build/android/Zombie_Escape_Europe-debug-0.5.14.apk` — 179.671.257 Byte, SHA-256 `AD69143D94DD2A91F8ADD82D2660FAE0918A195BC176F13AE3ED41D0517F8376`. Es ist mit einem Android-Debugschlüssel signiert und nicht der Play-Store-Build.


## Stand: 0.5.11 – Lieferwagen-Fahrzeuggrafik

- Der Lieferwagen erhält eine eigene transparente Karosserie-Grafik im Stil des Kombis: kantiger Laderaum, orangefarbene Schutzleiste und sichtbare Gebrauchsspuren.
- Räder, Radkästen, Boost und Werkstatt-Upgrades bleiben getrennte Ebenen. Das Fahrprofil und die Fahrzeugwerte ändern sich nicht.
- Tutorial- und Etappenzieltests sowie die Godot-Sichtprüfung bestehen. Das Android-Debug-APK startet auf dem isolierten API-36-AVD mit NVIDIA-Host-GPU; die Garage erscheint im Querformat ohne ANR oder Shaderfehler. Touch-Fahrt und echte Telefone bleiben offen.

## Stand: 0.5.10 – Kombi-Fahrzeuggrafik

- Der Kombi erhält eine neue eigenständige transparente Karosserie-Grafik mit Dachgepäck, Frontschutz und sichtbaren Gebrauchsspuren.
- Die freigestellten Radkästen lassen Räder und Felgen weiterhin dynamisch drehen. Werkstatt-Upgrades, Fahrzeugbewegung und Physik bleiben mit der Grafik verbunden.
- Die Lieferwagen-Grafik bleibt vorerst prozedural. Das Debug-APK ist nach dem Godot-Meilensteintest exportiert und statisch geprüft; Android-Geräte-QA folgt separat.
- Tutorial- und Etappenziel-Smoke-Tests bestehen; die Godot-Sichtprüfung bestätigt die lesbare Fahrzeuggröße und passende Radpositionen.
- Das Android-Debug-APK ist exportiert und statisch geprüft. Der APK-Start auf einem Android-Gerät steht noch aus.

## Stand: 0.5.9 – Erstfahrt-Tutorial

- Neue Spielstände erhalten vor der ersten Fahrt vier kurze Seiten zu Gas/Bremse, Sprüngen, Treibstoff/Boost und Werkstatt-Upgrades.
- Die Hinweise wechseln zwischen Android-Touchflächen und PC-Tasten. Das Tutorial blockiert Fehlstarts hinter dem Dialog und kann übersprungen werden.
- Beim Abschluss wird der Status gespeichert. Vorhandene Spielstände werden auf das neue Speicherformat migriert und direkt in die Werkstatt übernommen.
- Der Godot-Smoke-Test prüft neue und vorhandene Profile, Überspringen, Losfahren aus dem letzten Schritt, Eingabesperre und Migration. Die isolierte Godot-Sichtprüfung zeigt alle vier Seiten ohne abgeschnittene Texte oder Bedienelemente.
- Die Regressionen für Etappenziele und ein isolierter 30-Welten-Lauf bestehen weiter; alle Etappen und die Messina-Rettungsfahrt sind abschließbar.
- Version 0.5.9: Das Android-Debug-APK / Code 73 wurde exportiert und statisch geprüft. Es wurde noch nicht auf einem Telefon installiert.

## Stand: 0.5.8 – Kampagnenziel-Balance

- Der vollständige Godot-Lauf mit einem frischen Profil hat alle 30 Welten und die separate Messina-Rettungsfahrt abgeschlossen.
- Das Marseille-Tempoziel wurde von 78 auf 74 km/h gesenkt. So liegt es unter der 75,96-km/h-Grenze des Lieferwagens mit Motorstufe 2, die auf dem vorgesehenen Kampagnenpfad in Welt 10 verfügbar ist.
- Verona erhält eine zweite, fest platzierte Reparaturkiste; ein Regressionstest prüft Anzahl und Einsammeln beider Kisten.
- Im automatischen Gesamtlauf wurden alle 30 Welten sowie die 950-m-Rettungsfahrt abgeschlossen. Der einfache Fahr-Autopilot holte 21/30 Medaillen; neun weitere Weltziele und das saubere Rettungsziel bleiben für menschliche Fahrversuche offen.
- Der Lauf ist ein automatisierter Fahrtest. Menschliche Spielbalance und Prüfung auf Android-Geräten sind weiterhin offen.

## Stand: 0.5.7 – Etappenziele und Medaillen

- Jede Stadt hat ein eigenes Bonusziel, das bestehende Fahraktionen nutzt: Münzen und Werkzeug finden, Horden durchbrechen, Treibstoff oder Fahrzeugzustand bewahren, Tempo erreichen oder ein großes Hindernis ohne Treffer überspringen.
- Das Fahr-HUD zeigt Ziel und Fortschritt während der Fahrt. Werkstatt, Karte und Ergebnisbildschirm zeigen den Medaillenstatus.
- Ein erfolgreiches Etappenziel bringt einmalig 35–93 Münzen. Die separate Rettungsfahrt hat ein eigenes Ziel und einen einmaligen 100-Münzen-Bonus.
- Medaillen werden im Kampagnenspielstand gespeichert. Ältere Spielstände bleiben erhalten und werden auf das neue Speicherformat migriert.
- Der Godot-Runtime-Smoke-Test prüft alle Zielarten, die Kampagnenziele, die Rettungsmedaille, Speichern/Neuladen und den Schutz vor doppelten Boni.

## Stand: 0.5.6 – stadtbezogene Text-Funksprüche

- Jede der 30 Welten hat eine eigene Funkmeldung beim Fahrtstart und am ersten Versorgungskontrollpunkt. Die Aussagen verbinden die Orte zu einer Route von Amsterdam bis Messina.
- Die separate Rettungsmission hat drei eigene Meldungen bis zum Schiff. Während einer Meldung kann pausiert werden; die Lesezeit läuft erst beim Weiterfahren ab.
- Die Texte erscheinen als klar markierte Funkkarte im HUD und verdrängen weder Sammelmeldungen noch Checkpoint-Belohnungen. Es sind Untertitel, keine vertonten Sprachaufnahmen.
- Der Runtime-Smoke-Test deckt vollständige Meldungsdaten, eindeutige Einstiege, den Kontrollpunkt-Auslöser und die Schlussmission ab.

## Grundlage aus 0.5.5

- Das HUD kündigt das nächste Stadtsetpiece 140 Meter vorher mit Distanz und Hindernistyp an.
- Der Hinweis erklärt, dass ein Luftsprung den Treffer vermeidet. Er verschwindet nach dem Hindernis und wird im Pausenmenü nicht eingeblendet.
- Die Warnung nutzt den freien unteren Bereich des Statusfelds und bleibt bei Touchsteuerung sowie Tastatur sichtbar.
- Der Runtime-Smoke-Test prüft Erscheinen, Distanzgrenze, Stadtprofil und Ausblenden nach dem Passieren in allen 30 Welten.

## Grundlage aus 0.5.4

- Die Stadtsetpieces sind jetzt spielwirksame, visuell erkennbare Gefahren: überflutete Fahrbahn, Geröll, Steinschlag, Straßentrümmer oder Sperre.
- Die Folgen passen zum Hindernis: Wasser bremst leicht, Geröll und Trümmer kosten zunehmend Tempo und Fahrzeugzustand. Ein Sprung über das Hindernis vermeidet den Aufprall.
- Die ersten fünf Städte verursachen durch Stadtsetpieces keinen Fahrzeugschaden. Der Schaden steigt danach bis Valencia an; Panzerung reduziert den Treffer.
- Das frühere harte Einheitsverhalten ist ersetzt. Kampagnenprüfungen decken die Profile aller 30 Städte und Aufprall beziehungsweise Überspringen ab.
- In Godot 4.7.2 bestanden der Runtime-Smoke-Test und der vollständige Kampagnenlauf: 30/30 Etappen je im ersten Versuch; die Rettungsfahrt gewann bei 950,3 m. Der Lauf endete in Messina mit 14,5/166 Zustandspunkten und auf Reggio Calabria mit bis zu 0,192 rad Steigung. Das ist ein automatisierter Simulationslauf, keine menschliche Balancefreigabe.

## Grundlage aus 0.5.3

- Europakarte mit 30 nummerierten Städten; nur die nächste Welt wird nach Abschluss freigeschaltet, fertige Welten bleiben wiederholbar.
- Pro Welt eigener Distanzfortschritt und Bestwert. Münzen, Fahrzeuge, Upgrades und Einstellungen bleiben im versionierten Spielstand erhalten; ältere Einzelstreckenstände werden übernommen.
- Jede Stadt hat jetzt ein eigenes, weich interpoliertes Höhenprofil mit neun Kontrollpunkten. Frühe Routen bleiben flacher; südliche Etappen bekommen längere Anstiege und Abfahrten. Sichtbare Straße, Fahrzeugkontakt und Kollision verwenden dieselbe Höhenfunktion.
- Die ersten fünf Welten geben jetzt 30 Kraftstoffpunkte pro Kanister; ab Metz bleibt die spätere Standardmenge 18. So haben neue Spieler mehr Spielraum, ohne die südlichen Langstrecken zu vereinfachen.
- Gelände und Fahrbahn-Kollision wechseln gemeinsam mit der Stadt. Die Kulisse erhält regionale Farb- und Szenenvarianten sowie Wahrzeichen für alle 30 Orte.
- Gegnergruppen steigen von einzelnen langsamen Zombies zu schnellen und robusten Infizierten an. Spätere Treffer beschädigen den Wagen; frühe Gegner sollen den Start nicht blockieren.
- Messina schaltet eine eigene 950-m-Hafenmission mit Rettungsschiff und Kampagnenabschluss frei.
- Godot-Headless-Prüfung: alle 30 Profile laden mit passender Streckenlänge und kollisionsgeprüfter Straße; Altspielstand-Migration, Amsterdam→Rotterdam-Freischaltung, Speichern/Neuladen und die Schlussmission laufen durch.
- Automatischer Durchlauf in der echten Hauptszene: alle 30 Welten wurden mit der vorgesehenen Kombi-/Lieferwagen-Upgradefolge jeweils im ersten Versuch abgeschlossen; die zusätzliche 950-m-Rettungsfahrt endete bei 950,2 m mit `WIN`. Die ersten fünf Etappen endeten im Test mit 24–48/92 Kraftstoff. Der vorherige Triangulierungsfehler beim Vulkan von Neapel trat nicht erneut auf. Das belegt Systemabläufe, keine menschliche Schwierigkeitsfreigabe.
- Fahr-/Touch-Prüfung in der echten Hauptszene: Die Werkstatt hebt das 95-Münzen-Paket aus Motorstufe 1 und Tankstufe 1 hervor; mit diesem Kauf fährt der Kombi Amsterdam bei 1.800 m mit 15,4/92 Kraftstoff zu Ende. Gas plus Neigen und das unabhängige Loslassen zweier Finger wurden über Godots Touch-Ereignisse geprüft.

**Noch kein fertiges Release:** Die 30 Level brauchen menschliche Spielbalance und eine Sichtkontrolle auf Telefonen. Weitere Grafik, vertonte Audioinhalte, Store-Angaben und echte Geräte-QA bleiben weitere Arbeit. Version 0.5.12 ist ein interner Entwicklungsstand. Auf der AVD erschien die Garage nach einem längeren Warmstart; ein echter Telefon- und Touchlauf des aktuellen Kampagnenstands sind offen. Das Play-Store-AAB wird wie vereinbart erst nach Fertigstellung erstellt.

Die Gasfahrt ohne Upgrades kam in dieser Simulation bis 1.548 m und endete mit leerem Tank. Mit dem empfohlenen Startpaket wurde Amsterdam ohne Boost vollständig abgeschlossen. Das ist ein isolierter Godot-Testlauf, keine Android-Geräte- oder menschliche Spielbalance-Freigabe.

## Verlauf: 0.4.50

Bei Android-App-Wechsel oder Fokusverlust pausiert ein laufender Versuch jetzt sofort und speichert den erreichten Streckenstand. Auch die manuelle Pause schreibt einen Spielstand-Checkpoint.

In 0.4.48: Bei einem frischen Spielstand werden Motor und Tank als gemeinsames Startpaket hervorgehoben, wenn beide mit den 100 Startmünzen bezahlbar sind. Der Hinweis nennt Preis und Nutzen; nach dem Kauf verschwinden die Paketmarkierungen. So ist der erste Hügel samt Reichweiten-Upgrade verständlicher.

Die Strecke wechselt jetzt sichtbar zwischen Stadt, See, Wald und Feldern: Neusiedler See ab 900 m, Wald ab 1.800 m, Bratislava ab 2.800 m, Felder ab 4.300 m und Budapest am Ziel bei 6.000 m. Die Landschaftsfarben und Kulissen gehen weich ineinander über. Godots Zeichenlauf hat alle Übergänge von Wien bis Budapest geprüft.

Der Android-Test von 0.4.45 kam mit Motorstufe 1 und ohne Tank-Upgrade bei 883 m mit leerem Tank zum Stillstand. In 0.4.46 hat der Kombi fünf zusätzliche Start-Kraftstoffpunkte (70 statt 65); die Werkstatt empfiehlt vor Neusiedl gezielt das Tank-Upgrade und nach einer Fahrt mit leerem Tank ebenfalls zuerst den Tank. Ein isolierter Lauf der echten Hauptszene mit Motorstufe 1 und ohne Tank-Upgrade erreicht den 900-m-Checkpoint bei 900,1 m mit 31,7/70 Kraftstoff nach der Checkpoint-Versorgung. Im anschließenden Android-16-AVD-Lauf mit Motorstufe 1 und Basistank wurde Neusiedl bei 900 m erreicht; die Fahrt ging bis 1.131 m bei 70 km/h und etwa 14 Kraftstoffpunkten weiter. Der ursprüngliche AVD-Spielstand wurde bytegenau wiederhergestellt. Ein Test auf einem echten Telefon steht noch aus.

Bei Bratislava (2.800 m) wird der zweite Wagen freigeschaltet: ein schwererer Lieferwagen mit größerem Tank und eigener Upgrade-Reihe. So kann er noch auf der zweiten Hälfte der Wien–Budapest-Strecke gefahren werden. Beide Fahrzeuge lassen sich in der Werkstatt wechseln; ihre Upgrades bleiben getrennt gespeichert.

An Neusiedl, der Grenze, Bratislava und Győr erhält der Kombi beim Erreichen des Checkpoints bis zu 12 Kraftstoff, 25 Nitro und 15 Fahrzeugzustand zurück. Jeder Ort wird nur einmal versorgt; am Ziel gibt es keinen zusätzlichen Nachschub.

Auf steilen Anstiegen hebt 0.4.42 den BOOST-Knopf hervor und zeigt einen passenden Fahrhinweis, sobald der Fahrer Gas gibt, das Tempo unter 50 km/h liegt und noch Nitro verfügbar ist. Auf dem PC erscheint derselbe Hinweis für die Leertaste.

Ein kompletter Godot-Kampagnenlauf erreicht Budapest nach vier Fahrten. Die Freischaltung bei Bratislava, der anschließende Garagenwechsel, getrennte Upgrades und alte Spielstände wurden geprüft. Der kombinierte Kampagnenlauf fährt nach dem dritten Abschnitt mit dem Lieferwagen weiter.

Das Android-Debug-APK 0.4.48 hatte Versionscode 61, Mindest-API 28, Ziel-API 36 und ARM64/x86_64. Paket, V2-Debugsignatur, APK-Ausrichtung und 16-KB-Ausrichtung der nativen Bibliotheken sind geprüft. Auf dem isolierten Android-16-AVD wurde das APK installiert und die Garage gerendert. Die neue Startempfehlung und die Hervorhebung von Motor und Tank sind sichtbar. Im Vergleichstest der Vorgängerversion 0.4.47 endete ein Lauf ohne Upgrades nach 582 m mit leerem Tank. In 0.4.48 erreichte der Kombi mit dem empfohlenen Motor-/Tankpaket (95 von 100 Startmünzen) den Neusiedl-Checkpoint und fuhr bis etwa 1.048 m bei 72 km/h. Die Touch-Käufe funktionierten. In 0.4.49 zeigt das HUD den verbleibenden Treibstoff zusätzlich als Prozentwert; die Zahl färbt sich bei niedrigem Tank rot. Der erste Screenshot nach frischer Installation war nach fünf Sekunden noch schwarz; nach zusätzlicher Wartezeit erschien die Garage. Beim folgenden Start wurde sie innerhalb von acht Sekunden angezeigt. Das muss auf echten Telefonen nochmals geprüft werden. Danach wurde das Testprofil bytegenau auf 883,3297 m, 158 Münzen und Kombi zurückgesetzt (SHA-256 `a12366d3f8caf6f44fc9e135af2323e96a01952d3d6eaed130a39bdc036777cf`). APK-SHA-256: `4DCDC9CF8DF12B022B44F345E7BA5F20B623F51C5EADD2DF2ABEB4C647EE5C6A`. Ein vollständiger AVD-Kampagnenlauf bis Budapest ist für 0.4.47 belegt; 0.4.48 hat den Einstieg und den ersten Checkpoint bestätigt. Ein echter Telefonlauf steht noch aus. Das Play-Store-AAB wird wie gewünscht erst beim fertigen Spiel erstellt.



In 0.4.50 wird der Hinweis bei höchstens 25 % Treibstoff zu einer Warnung: Er nennt zusätzlich die Entfernung zum nächsten noch nicht eingesammelten Ersatzkanister. Bei höchstens 10 % erscheint „TANK KRITISCH“. Der Warnhinweis hat Vorrang vor dem allgemeinen Fahrhinweis und wird auch angezeigt, wenn der Spieler schon weiter als 900 m ist.

Das Android-Debug-APK 0.4.49 hat Versionscode 62, Mindest-API 28, Ziel-API 36 und ARM64/x86_64. Es wurde mit Godot 4.7.2 exportiert, im isolierten Android-16-AVD installiert und gestartet. Im Fahr-HUD zeigt die neue Kraftstoffanzeige bei 883 m den Resttank in Prozent (im aufgenommenen Bild 95 %); bei höchstens 25 % färbt sich der Wert rot. Die gespeicherte AVD-Kampagne wurde anschließend bytegenau auf SHA-256 `a12366d3f8caf6f44fc9e135af2323e96a01952d3d6eaed130a39bdc036777cf` zurückgesetzt. `apksigner` bestätigt die V2-Debugsignatur; `zipalign` besteht die 16-KB-Prüfung und alle vier nativen Bibliotheken haben `PT_LOAD`-Ausrichtung `0x4000`. APK-SHA-256: `C33E117C09AF095A5BA5DDE02C7A30A92FA22AA96401BCD56DF4115510BD906C`. Das APK bleibt ein Testbuild; das Play-Store-AAB ist noch nicht erstellt.

Die Builds 0.4.25 und 0.4.26 wurden auf Android-Emulator 5556 installiert. Beim Kaltstart brach der erste Versuch jeweils ab; der zweite zeigte Godots Garage nach rund 119 Sekunden und später das HUD. Auf 0.4.25 wurden „Fahrt starten“, 13 Sekunden Gas und Pause erkannt; das Gas erhöhte die Geschwindigkeit, Pause fror die Physik ein. Auf 0.4.26 wurden Start, Pause und ein Tipp auf die Mitte der Pausenkarte geprüft: Er setzte die Fahrt fort, ohne den Vibrationsregler zu treffen. Die AVD lief nur mit 1–3 Bildern pro Sekunde und einzelne Bildschritte dauerten 1 bis 16 Sekunden. Das ist kein verlässlicher Leistungstest für ein echtes Telefon. Bremse, Boost, Neigen, Mehrfingereingabe und Hintergrundwechsel sind noch nicht vollständig auf Android bestätigt. Nach den Tests wurde der vorherige Spielstand bytegenau auf 1.128,8 m und 267 Münzen zurückgestellt.

Version 0.4.27 ergänzt ein eigens erstelltes Querformat-Landschaftsbild als Godot-Boot-Splash sowie das Kombi-Symbol und den dunkelgrünen Grund für den Android-System-Splash. Das APK wurde auf Emulator 5556 aktualisiert; die SHA-256-Prüfsumme von `progress.cfg` blieb dabei unverändert. Bei der Sichtprüfung zeigte die langsame AVD noch den nativen System-Splash. Das Querformat-Bootbild nach dem Start der Godot-Hauptschleife ist auf diesem Emulator noch nicht sichtbar bestätigt.

Version 0.4.28 rückt Gas, Neigen, Bremse und Boost vom Bildschirmrand ab, um Konflikte mit Android-Wischgesten zu verringern. Ein Godot-Testlauf bestätigte Mehrfingereingabe und erreichte mit dem unaufgerüsteten Kombi vom Hügel bei 899 m nach 20 Spielsekunden 1.239 m bei 54 km/h. Das Debug-APK wurde auf Emulator 5556 installiert. Zunächst fehlten dort Android-Paket- und Activity-Dienst; nach einem normalen Emulator-Neustart erschienen Garage und Fahrt. Android-Touchtests bestätigten Start, Gas (3 auf 49 km/h), Boost-Verbrauch, Bremse (bis 0 km/h), linkes und rechtes Neigen sowie Pause. Nach Wechsel zum Android-Startbildschirm kehrte das Spiel pausiert zurück. Der vorherige Spielstand wurde nach den Tests bytegenau wiederhergestellt. Ein echter Telefontest für Leistung, Displaygrößen, Mehrfingereingabe und längere Fahrten steht noch aus.

Version 0.4.29 wurde als 177,5-MB-Debug-APK gebaut und auf Emulator 5556 installiert. Manifestprüfung bestätigt Paket `com.zombieescapeeurope.game`, Version 0.4.29 / Code 42, Mindest-API 28, Ziel-API 36 und nur die VIBRATE-Berechtigung. Die Debug-Signatur wurde verifiziert. Der Datenschutzdialog lädt seinen Text jetzt ausdrücklich über den Android-Exportfilter und funktioniert per Touch aus Garage und Pause. Der gespeicherte Kampagnenstand wurde danach bytegenau auf den Ausgangs-Hash zurückgesetzt. Diese AVD-Prüfung ersetzt keinen Lauf auf einem echten Telefon.

Version 0.4.30 ergänzt eine sichtbare Grenzstation mit „SLOVAKIA“-Schild und offenem Schlagbaum bei 1.800 m. Das APK wurde als Version 0.4.30 / Code 43 exportiert, auf Emulator 5556 installiert und bei 1920×1080 geprüft. Der Landschaftspunkt war bei 1.128 m sichtbar; der Datenschutzdialog öffnete und schloss weiterhin per Touch. Die Spielstand-Prüfsumme blieb unverändert. Die AVD wurde anschließend auf 1080×2400 zurückgesetzt.

Version 0.4.31 ergänzt sammelbare Werkzeugkisten, die den Fahrzeugzustand während der Fahrt um bis zu 30 Prozentpunkte reparieren. Sie sind als helle Kisten mit rotem Kreuz gezeichnet und liegen verteilt auf der Strecke.

Das Debug-APK 0.4.31 / Versionscode 44 wurde exportiert, auf Emulator 5556 installiert und bis zur sichtbaren Werkstatt gestartet. Eine isolierte Godot-Simulation bestätigt Werkzeugkisten am Boden, den Maximalzustand von 100 Punkten, das Verfehlen in der Luft und den Kampagnensieg nach vier Fahrten. Ein echter Telefontest steht noch aus.

Version 0.4.32 zeigt während der Fahrt das nächste Etappenziel samt verbleibender Entfernung dauerhaft im HUD. So ist jederzeit klar, wie weit es bis zum nächsten Münzbonus ist.

Das Android-Debug-APK 0.4.32 / Code 45 wurde installiert. Im Emulator zeigte die Fahrt „ZIEL GRENZE · 670 M“; der Pausenknopf funktionierte. Der kurze Test-Spielstand wurde danach bytegenau auf den vorherigen Stand zurückgesetzt. Ein Test auf echter Android-Hardware steht aus.

Version 0.4.33 hält Fahrmeldungen im 16:9-Querformat links vom Pausenknopf. Ein Android-Debug-Build wurde auf dem Emulator bei 1920×1080 geprüft: Die Meldung verdeckte den Pauseknopf nicht, Pause und Weiterfahren funktionierten; die Testfahrt zeigte 69 km/h und 658 m bis zur Grenze. Die zuvor gesicherte Spielstanddatei wurde zurückgeschrieben. Beim abschließenden ADB-Neustart meldete sich der AVD nicht mehr; ein letzter Hash-Lesecheck war dadurch nicht möglich. Ein Test auf einem echten Telefon steht aus.

Version 0.4.34 erklärt die Steuerung schon in der Garage: Gas halten, Boost am Berg einsetzen und das Auto in der Luft neigen. Version 0.4.35 macht Budapest im Sieg-Bildschirm sichtbar und setzt den Zieltext deutlicher ab. Ein echter Android-Spielerdurchlauf steht noch aus.

Version 0.4.36 verschiebt den Boost höher, damit seine Touchfläche nicht mit der Bremse kollidiert. Godot-Tests bei 1280×720, 1600×720 und 1920×1080 bestätigten fünf berührbare Fahrflächen innerhalb des 48-Pixel-Rands und ohne Überschneidungen. Ein weiterer Lauf bestätigte gleichzeitiges Gas und Neigen, Mehrfingereingabe, Pause und Weiterfahren. Ein echter Android-Touchtest steht noch aus.

Version 0.4.37 ergänzt einen prozeduralen Laufzyklus für die Zombies. Arme und Beine bewegen sich mit versetzter Phase, während das Fahrzeug vorbeifährt. Der Godot-Lauf lud die geänderte Strecke und zeichnete sie während der Fahrt; der APK-Export wurde anschließend geprüft. Ein Lauf auf Android-Hardware steht noch aus.

Eine aktuelle, isolierte Godot-Kampagnensimulation mit frischem Spielstand erreichte Budapest nach vier Fahrten. Die Etappen endeten bei 965 m, 2.697 m und 5.284 m; danach gewann der Kombi bei 6.000 m. Dazwischen wurden verdiente Münzen in Motor, Reifen, Tank und Panzerung investiert. Der Lauf bestätigt Kampagne, Belohnungen, Werkstatt und gespeicherten Sieg im Godot-Physiklauf, ersetzt aber keinen vollständigen Spielertest auf einem Telefon. Leichte Kamerastöße bei harten Landungen, Treffern und Funden wurden ebenfalls in einer isolierten Simulation ausgelöst.

Ein separater Lauf ohne Upgrades, Boost oder Neigen erreichte mit gehaltenem Gas 965,8 m und passierte damit den ersten Checkpoint bei 900 m. Der Lauf endete mit leerem Tank; reale Spielbarkeit und Balance müssen trotzdem auf einem Telefon geprüft werden.

In 0.4.25 zeigen die gekauften Upgrades nun sichtbare Änderungen am Kombi: Motorhaubenansaugung, grobere Reifen, zusätzliche Dachkanister und verstärkte Ramme beziehungsweise Seitenschutz. 0.4.26 verkleinert die Trefferzone des Vibrationsreglers, damit ein Tipp auf die Pausenkarte nicht versehentlich den Regler verschiebt. 0.4.27 ergänzt den eigenen Godot-Boot-Splash und Android-Startfarben. 0.4.28 rückt die Bildschirm-Steuerung vom Rand weg. 0.4.29 ergänzt einen Datenschutzbildschirm in Werkstatt und Pause.

## Projekt in Godot öffnen

1. ZIP in einen eigenen Ordner entpacken.
2. Godot 4.7.2 starten und den Ordner über **Importieren** auswählen.
3. project.godot öffnen und mit **F6** die Hauptszene oder mit **F5** das ganze Projekt starten.

Es werden keine externen Add-ons benötigt. Der lokale Spielstand liegt in user://progress.cfg.

## Steuerung

- **Android:** Bildschirmtasten für Gas, Bremse, Boost und Neigen.
- **PC:** W/Pfeil hoch für Gas, S/Pfeil runter für Bremse, Leertaste für Boost, A/D oder Pfeiltasten links/rechts zum Neigen.
- **Pause:** Pausenknopf im Spiel; im Editor zusätzlich Escape.

## Android-Builds

Aktuelles installierbares Telefonpaket: [Zombie_Escape_Europe-qa-release-0.5.33.apk](build/android/Zombie_Escape_Europe-qa-release-0.5.33.apk), exportiert mit Godot 4.7.2. Paket `com.zombieescapeeurope.game`, Version 0.5.33 / Code 97, Mindest-API 28, Ziel-API 36, ARM64. `apksigner` bestätigt die V2-Signatur; `zipalign` und die 16-KB-Ausrichtung sind bestanden. Größe 110.285.997 Byte; SHA-256 `105BA1DEAB1F827BE8605091A186CF4057BCE90969FE7C6F6C2095EAF75DC7F5`. Das Paket ist ein internes QA-Build mit lokalem Testschlüssel, kein Play-Store-Upload. Die x86_64-fähige Debug-APK für den Emulator ist [Zombie_Escape_Europe-debug-0.5.33.apk](build/android/Zombie_Escape_Europe-debug-0.5.33.apk). Das aktuelle bearbeitbare Godot-Projekt liegt als [Zombie_Escape_Europe_Godot_0.5.33_30-Welten.zip](Zombie_Escape_Europe_Godot_0.5.33_30-Welten.zip) bei.

Build 0.4.47 wurde auf einem isolierten Android-16-AVD installiert. Dort wurden Garage, vier Fahrten bis Budapest, Kombi- und Lieferwagen-Upgrades, Gas, Boost, Bremse, beide Neigerichtungen, Pause/Fortsetzen, App-Wechsel und gespeicherter Fortschritt geprüft. Der ursprüngliche QA-Spielstand wurde nach den Fahrtests bytegenau wiederhergestellt. Diese frühere Prüfung bestätigt nicht die Kampagnenziele in 0.5.7 und ersetzt keinen Test auf einem echten Android-Telefon.

Neue Apps auf Google Play werden als Android App Bundle (AAB) veröffentlicht ([AAB-Dokumentation](https://developer.android.com/guide/app-bundle)). Wie besprochen erstelle ich das signierte Bundle, sobald das Spiel fertig ist. Das Projekt hat dafür das Profil **Android Play Store AAB** und das Hilfsskript `tools/export_play_store_aab.ps1`. Dann werden Keystore-Pfad und Key-Alias lokal abgefragt; das Passwort wird verdeckt eingelesen. Keystore und Passwort gehören nicht in das Projekt-ZIP oder in einen Chat.

    .\tools\export_play_store_aab.ps1

Das Skript fragt lokal nach dem Godot-Pfad, falls die Projektkopie keine Godot-Installation enthält, und gibt den erzeugten AAB-Pfad am Ende des Laufs aus.

Für den Export müssen Godot-Android-Exportvorlagen, Android SDK und Java in Godot eingerichtet sein. Seit 31. August 2026 müssen neue Google-Play-Apps und Updates auf Android 16 / API 36 oder höher zielen ([Google Play API-Anforderungen](https://support.google.com/googleplay/android-developer/answer/11926878?hl=de)). Androids 16-KB-Seitengrößen-Vorgabe gilt für diese Apps ab 1. Februar 2027; das aktuelle APK besteht die Native- und ZIP-Ausrichtungsprüfung bereits ([16-KB-Leitfaden](https://developer.android.com/guide/practices/page-sizes)). Das finale AAB muss nach Fertigstellung zusätzlich geprüft und in einem Play-internen Test auf echten Geräten installiert werden. Store-Eintrag und Play-Console-Angaben sind ebenfalls noch abzuschließen.

Der AAB-Export für 0.4.28 wurde mit einem eigens erzeugten Wegwerf-Schlüssel vorgeprüft: Das Bundle enthielt ein Basis-Manifest und bestand die Signaturprüfung. Testbundle und Wegwerf-Schlüssel wurden anschließend gelöscht. Dieser Vorbau bestätigt den Exportweg, ist aber nicht mit dem privaten Upload-Keystore signiert und nicht für Google Play bestimmt.

Für 0.4.46 wurde zusätzlich eine Release-Modus-QA-APK mit dem Projekt-Debugschlüssel gebaut. Paket, Version, SDK-Ziel und Signatur stimmen mit dem Debug-APK überein; auf dem AVD startete sie und fuhr bis 1.112 m bei 72 km/h. Danach wurde das Debug-APK zurückinstalliert und der vorherige Spielstand bytegenau wiederhergestellt. Die AVD liefert keine belastbare Frame-Zeitmessung für Godots native Oberfläche; die Leistung auf einem echten Telefon bleibt offen. Das AAB-Hilfsskript verwendet Godots Benutzerdaten während des Exports jetzt in `build/android/godot_export_userdata` und stellt anschließend den vorherigen `APPDATA`-Wert wieder her. Der private Upload-Keystore wird nicht kopiert.

## Nächste Entwicklungsschritte

Deutscher Store-Text, Store-Symbol, Feature-Grafik und drei Handy-Screenshots liegen im Begleitarchiv `Zombie_Escape_Europe_Play_Store_Assets_0.4.35.zip`; der zusätzliche Sieg-Bildschirm darin ist eine Godot-QA-Aufnahme und kein Telefon-Screenshot. Offen sind Tests auf einem echten Android-Telefon, Android-Mehrfingereingabe, Tablet-Screenshots, Betreiber-Kontaktangaben und eine öffentliche Datenschutzrichtlinie. Der aktuelle QA-Stand und die weiteren Arbeitspunkte stehen in `ROADMAP.md`.












Ein frischer Kampagnenlauf der Version 0.4.49 erreichte im isolierten Godot-Lauf nach fünf Fahrten Budapest und speicherte den Siegstand bei 6.000 m. Die Spielphysik lief in der Simulation mit effektiven 60 Hz; der Lauf ersetzt keinen Telefontest. Für 0.4.50 wurde die neue Niedrig-Tank-Warnung headless geprüft: Bei 883 m zeigt sie den nächsten Kanister in 293 m an und zählt nach Einsammeln zum nächsten Fund weiter.

## Android-QA 0.4.50

Das universelle Android-Debug-APK 0.4.50 / Code 63 wurde exportiert: `build/android/Zombie_Escape_Europe-debug-0.4.50.apk`, 177.570.203 Bytes, SHA-256 `C85BB6A25789032E2D323112FF7416F41E8CD6952232D8ED052E01106CFA6CFB`. Paket `com.zombieescapeeurope.game`, Mindest-API 28, Ziel-API 36, ARM64 und x86_64. V2-Signatur, `zipalign` und 16-KB-Ausrichtung der nativen Bibliotheken wurden geprüft.

Der isolierte Android-16-AVD hatte zu wenig freien Speicher für das universelle APK. Ein x86_64-only-QA-APK derselben Version wurde zusätzlich erstellt und installiert; Garage und Fahr-HUD wurden aufgenommen. Das ist ein Testpaket, nicht das universelle Liefer-APK. Der AVD-Spielstand wurde bytegenau auf SHA-256 `a12366d3f8caf6f44fc9e135af2323e96a01952d3d6eaed130a39bdc036777cf` zurückgesetzt; andere AVD-Apps wurden nicht gelöscht. Ein Test auf echtem Telefon sowie die visuelle Niedrig-Tank-Abnahme dort stehen noch aus. Das Play-Store-AAB wurde wie vereinbart noch nicht erstellt.

