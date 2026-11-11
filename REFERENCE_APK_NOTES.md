# Notizen zur bereitgestellten Referenz-APK

Stand: 2. November 2026

## Statisch festgestellte Fakten

- Paketname: `com.notdoppler.earntodie2`, Version 1.4.58, Versionscode 1004058.
- Android-Mindestversion: API 23; Zielversion: API 36.
- Die APK enthält native Bibliotheken für ARM64 und ARMv7, darunter `libEarnToDie2.so`. Sie ist kein Godot-Projekt und lässt sich nicht als Szenen oder Quellcode in dieses Projekt übernehmen.
- Die APK enthält umfangreiche eigene Grafik- und Audiodateien sowie lokalisierte Texte. Es wurde daraus nichts in die Godot-Spielordner übernommen.
- Android-Berechtigungen umfassen unter anderem Internetzugriff, Abrechnung und Werbe-/Attributionsdienste. Das aktuelle Godot-Projekt benötigt davon nichts; sein APK fordert nur Vibration an.

Die Prüfung erfolgte lesend mit Androids APK-Metadaten- und Dateilistenwerkzeugen. Die vom Spieler bereitgestellte APK blieb unverändert.

## Was wir als Designreferenz verwenden

Wir vergleichen später nur das beobachtbare Spielgefühl und den allgemeinen Ablauf: wie schnell das Auto auf Gas und Bremse reagiert, wie Hänge die Geschwindigkeit beeinflussen, wann Neigen oder Boost hilft, wie Kraftstoff und Schaden Druck erzeugen und wie Strecke, Hindernisse, Belohnung und Werkstattkäufe zusammenwirken. Die 30 europäischen Welten behalten eigene Streckenfolgen, Wahrzeichen, Kulissen und Fahrzeugdarstellung.

Grafiken, Musik, Namen, Texte, Leveldaten und Programmcode der Referenz werden nicht in Zombie Escape Europe kopiert. Die Godot-Version bleibt ein eigenes Spiel.

## Laufzeitvergleich: noch offen

- Eine frische Referenz-AVD wurde ausschließlich unter `build/reference_android` eingerichtet und gestartet; die vorhandene persönliche AVD blieb unberührt.
- ADB konnte trotz separatem Workspace-Benutzerordner keinen lokalen Dienst auf Port 5038 aufbauen. Daher konnte ich die APK in dieser Sitzung nicht installieren oder ihre Fahrwerte zur Laufzeit messen.
- Es wurden keine Dateien, Grafiken, Audiodaten, Leveldaten oder Programmteile aus der Referenz-APK in das Godot-Projekt kopiert.

Für einen belastbaren Vergleich messen wir später auf einer isolierten Emulatorinstanz oder einem separaten Android-Gerät: Anfahrzeit und Höchstgeschwindigkeit, Tempoverlust an definierten Steigungen, Reaktion in der Luft, Kraftstoffverbrauch pro Strecke, Treffer-/Schadenseffekt, Zeit bis zum ersten Kontrollpunkt und Anzahl der Hindernisse. Diese Beobachtungen werden zum Abstimmen eigener Werte genutzt, nicht zum Nachbauen einzelner Level.
