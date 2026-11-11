# Projektsicherung

Die ZIP-Datei sichert den Projektstand vor der Änderung am Serienfahrzeug-Menü. Sie enthält beide Strecken, Grafiken, PC-Startprogramm, Android-Pakete und Signierung. Vor dem Löschen der alten Archive wurde jede Datei in der neuen ZIP per SHA-256 mit der Originaldatei verglichen.

Zum Wiederherstellen die ZIP vollständig in einen leeren Ordner entpacken. Dort zuerst „project.godot“ in Godot öffnen und den Import abschließen lassen. Anschließend lässt sich die PC-Vorschau über „Start_Zombie_Escape_Europe_PC_Preview.bat“ starten.

Testausgaben, wiederherstellbare Zwischendateien und persönliche Spielstände außerhalb des Projektordners gehören nicht zur Sicherung.
