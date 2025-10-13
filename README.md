# Implementierung eines Roguelike-Videospiels mit adaptiven Gegnern
## Das Ziel
Das Ziel dieser Maturaarbeit ist die Schaffung eines Top-down Action-Shooter, bei dem Gegner in Wellen erscheinen und während des Spiels lernen. Jede neue Welle wird aus den erfolgreichsten Gegnern der letzten Welle gebildet (mithilfe des Reinforcement Learning Algorithmus). Der Spieler kann sich bewegen, schiessen und ausweichen. Nach einer bestimmten Anzahl von Wellen erhält der Spieler Power-ups. Das Ziel des Spiels ist es, die Gegner zu neutralisieren, Gegenstände zu sammeln und generell stark genug zu werden, um ein Tor zu zerstören und aus der „Arena“ zu entkommen.

## Das Spiel spielen
Es gibt 3 Möglichkeiten, das Spiel zu spielen:
1. **Online auf itch.io spielen**
Das Spiel ist auf itch.io veröffentlicht. Das bedeutet, dass Sie auf den folgenden Link klicken und es in Ihrem Browser spielen können: https://jokolto.itch.io/lcamp. 
Bei einigen Browsern kann es zu Lags kommen. Wenn dies bei Ihnen der Fall ist, versuchen Sie es mit der nächsten Methode.

2. **Lokal auf dem PC spielen**
Dazu müssen Sie eine ausführbare Datei herunterladen und ausführen. Windows Defender könnte diese jedoch als verdächtig einstufen, da ich kein offizieller Herausgeber bin. Aber keine Sorge, die Datei enthält keine Viren (vertrauen Sie mir!).
Die Datei steht auch auf Itch.io zum Download bereit: https://jokolto.itch.io/lcamp.

3. **Das Spiel in Godot Umgebung starten**
Die letzte Methode ist etwas schwieriger und erfordert einige Einstellungen. Sie ermöglicht es Ihnen jedoch nicht nur, das Spiel zu spielen, sondern auch den Quellcode anzuzeigen und das Spiel bei Bedarf zu ändern. Diese Methode wird weiter unten in einem separaten Abschnitt erläutert.

## Setup für das Godot-Projekt

1. **Repository klonen:**  
   Klone dieses Repository auf dein Gerät.

2. **Godot installieren:**  
   Um an Godot-Projekten arbeiten zu können, muss Godot natürlich lokal auf Ihrem PC installiert sein. Falls Sie es noch nicht haben, finden Sie hier einen Link zum Herunterladen.
   [Godot hier herunterladen](https://godotengine.org/download)

3. **Projekt öffnen:**  
   Öffne den Folder "source" dieses Repositories als Godot-Projekt.

4. **Spiel starten:**  
   Starte das Projekt mit dem **Run-Button** oder drücke `F5`.

## Durchführung von eigenen Experimenten
Zur Überprüfung der Experimente können diese auch lokal selbst durchgeführt werden. Das erfordert jedoch mehr Aufwand und Wissen. Für Godot wird das gleiche Setup wie oben beschrieben benötigt. Zusätzlich wird jedoch auch Python benötigt. Es müssen also zu den letzten Schritten noch folgende Schritte ausgeführt werden:

5. **Python-Installation**  
   Falls Python noch nicht auf dem PC installiert ist, installieren Sie es. Hier ist ein Link dazu: [Offizielle Python-Website](https://www.python.org/downloads/). Die neueste Version sollte funktionieren.

6. **Optional: Venv erstellen.**  
   Für das Projekt werden mehrere Python-Bibliotheken benötigt. Um diese zu isolieren, wäre ein Venv sinnvoll. Wie das funktioniert, können Sie in einem Guide im Internet nachlesen.

7. **Godot und Python einstellen**  
   Damit die Experimente funktionieren, müssen Godot und Python wissen, dass sie miteinander kommunizieren sollen. Dafür gibt es einen Parameter in der Godot-Globalconfig namens „EXPERIMENTIG”. Globalconfig.gd befindet sich unter dem Pfad: „source\client_scripts” verfügbar. Alle wichtigen Parameter können dort und in ai_server.py gefunden werden.

8. **Experimente starten**  
   Um Experimente zu starten, steht das spezielle Python-Controller-Skript „experiments.py” zur Verfügung. Dabei sind einige Parameter einzustellen. Um die gleichen Ergebnisse zu erhalten, müssen auch Seeds eingegeben werden. Aber auch mit einem zufälligen Seed soll das Ergebnis ungefähr gleich sein. 
   Um Zeit zu sparen, können Experimente parallel ausgeführt werden. Das ist die Standardeinstellung. Der Parameter „max_workers” entscheidet darüber, wie schnell die Experimente ausgeführt werden. Dieser sollte angemessen die PC-Leistung berücksichtigen.

9. **Die Daten visualisieren.**
   Dafür gibt es das Jupiter-Notebook, in dem es mehrere Plots gibt. Zunächst sollen die Daten in einen Dataframe geladen werden, dann können die Plots erstellt werden. Für all diese Funktionen gibt es jeweils Zellen.

## Folder Struktur
Die Hauptordner des Projekts sind nachfolgend mit Erläuterungen aufgeführt:
1. **info docs** - Dokumente mit Informationen der Gymnasium zur Maturaarbeit, während der Arbeit erstellte Planungsunterlagen und Fachliteratur.
2. **presentation** - Sowohl die schriftliche Abschlussarbeit (ohne Namen) als auch das Poster werden hier veröffentlicht. 
3. **python_ai_scripts** - Python-Code für KI-Experimente, resultierende Daten und ein Jupiter-Notebook zur Visualisierung. Das Spiel selbst verwendet dies nicht zur Laufzeit, aber es kann Sockets verwenden, um die KI für das Spiel zu berechnen und weiterzugeben, wie es derzeit in Godot der Fall ist.                     
4. **report** - Dieser Ordner enthält drei Dateien: den Bericht, den grammatisch fehlerfreien Bericht und die Rohfassung mit Feedback. Somit kann der Fortschritt der Spielentwicklung verfolgt werden. Durch den Commit-Verlauf kann der Fortschritt noch genauer verfolgt werden.
5. **source** - Dieser Ordner enthält das Godot-Projekt, das mit dem oben beschriebenen Setup lokal installiert werden kann. Dieser Ordner enthält den gesamten Quellcode (GdScript), Assets (Musik, Sound, Sprites), Ressourcen (.tres-Dateien) und alle Godot-spezifischen Dateien (Szenen, Konfigurationsdateien).   
