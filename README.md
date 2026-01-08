
---

# Firmware Stratum 0 (RP2040)

**[English](#english-version) | [Français](#version-française)**

---

## English Version

### 📋 Description

This folder contains the source code and deployment tools for the RP2040 microcontroller firmware used in the **Time Reference NMEA** project.

This firmware transforms an RP2040 (Waveshare RP2040-Zero or Raspberry Pi Pico) into a high-precision hardware synchronization interface (Stratum 0). It reads the NMEA stream from a GPS module and aligns the data transmission to the PC with the PPS (Pulse Per Second) signal.

### 🚀 Features

* **PPS Synchronization:** Ensures the PC receives the time at the exact start of the second.
* **"Time Adder" Algorithm:** Adds 1 second to the received NMEA sentence to compensate for GPS transmission latency and align with the next PPS pulse.
* **USB CDC:** Communication via a native virtual serial port.

### 💡 Diagnostic LED (RP2040-Zero)
The internal RGB LED indicates the status of the GPS:
* **Blue:** No data received from GPS (check wiring).
* **Red:** GPS data received, but no satellite fix yet.
* **Green:** GPS Fix acquired, but PPS signal missing (> 5s).
* **White Flash:** PPS signal detected (LED turns off between flashes when PPS is active).

### �️ Installation

1. Download the `Stratum0_vX.Y.Z.uf2` file from the Releases.
2. Unplug your RP2040.
3. Hold the **BOOT** button and plug the module into the PC.
4. Copy the `.uf2` file into the `RPI-RP2` drive.

### 📝 Changelog

#### v1.0.0

* **Initial Version**
* Support for GPS Serial communication at 9600 baud (GP0/GP1).
* PPS interrupt detection on pin GP2.
* Automatic date and time correction (Time Adder).
* Version display at startup.

---

*To compile this project, use PlatformIO.*
*Use the `DeployFirmware.bat` script to generate and publish a new version.*

---

## Version Française

### 📋 Description

Ce dossier contient le code source et les outils de déploiement pour le firmware du microcontrôleur RP2040 utilisé dans le projet **Time Reference NMEA**.

Ce firmware transforme un RP2040 (Waveshare RP2040-Zero ou Raspberry Pi Pico) en une interface de synchronisation matérielle de haute précision (Stratum 0). Il lit le flux NMEA d'un module GPS et aligne l'envoi des données vers le PC sur le signal PPS (Pulse Per Second).

### 🚀 Fonctionnalités

* **Synchronisation PPS :** Garantit que le PC reçoit l'heure au début exact de la seconde.
* **Algorithme "Time Adder" :** Ajoute 1 seconde à la trame NMEA reçue pour compenser la latence de transmission du GPS et s'aligner sur le prochain top PPS.
* **USB CDC :** Communication via port série virtuel natif.

### 💡 LED de Diagnostic (RP2040-Zero)
La LED RGB interne indique l'état du GPS :
* **Bleu :** Aucune donnée reçue du GPS (vérifier le câblage).
* **Rouge :** Données GPS reçues, mais pas de fix satellite.
* **Vert :** Fix GPS acquis, mais signal PPS absent (> 5s).
* **Flash Blanc :** Signal PPS détecté (La LED s'éteint entre les flashs quand le PPS est actif).

### 🛠️ Installation

1. Récupérez le fichier `Stratum0_vX.Y.Z.uf2` dans les Releases.
2. Débranchez votre RP2040.
3. Maintenez le bouton **BOOT** enfoncé et branchez le module au PC.
4. Copiez le fichier `.uf2` dans le lecteur `RPI-RP2`.

### 📝 Notes de Version (Changelog)

#### v1.0.0

* **Version Initiale**
* Support de la communication Série GPS à 9600 bauds (GP0/GP1).
* Détection d'interruption PPS sur la broche GP2.
* Correction automatique de la date et de l'heure (Time Adder).
* Affichage de la version au démarrage.

---

*Pour compiler ce projet, utilisez PlatformIO.*
*Utilisez le script `DeployFirmware.bat` pour générer et publier une nouvelle version.*

---
