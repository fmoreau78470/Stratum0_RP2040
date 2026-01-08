/*
* Ce firmware transforme le RP2040 en une horloge de référence (Stratum 0).
* Il lit le flux NMEA du GPS et synchronise l'envoi de la trame `$GPRMC` avec le signal PPS (Pulse Per Second) pour garantir que l'heure reçue par le PC correspond exactement au début de la seconde.
 */

#include <Arduino.h>
#include "Adafruit_TinyUSB.h"
#include "version.h"
#include <Adafruit_NeoPixel.h>
 
// --- CONFIGURATION ---
const String FIRMWARE_VERSION = VERSION;
const int PPS_PIN = 2;       // Le fil PPS du GPS va sur GP2 (Pin 3)
const int LED_PIN = 16;      // LED RGB interne du RP2040-Zero

// Objet USB CDC standard
Adafruit_USBD_CDC GpsUSB;
// Objet NeoPixel
Adafruit_NeoPixel pixels(1, LED_PIN, NEO_GRB + NEO_KHZ800);

// --- VARIABLES GLOBALES ---
volatile bool pps_detected = false;

String inputBuffer = "";
String lastRmc = "";

bool gps_fix = false;           // État du Fix GPS (A=OK, V=Ko)
unsigned long last_rx_time = 0; // Dernier moment où on a reçu des données
unsigned long pps_flash_time = 0; // Pour gérer le flash de la LED

// --- INTERRUPTIONS ---
void on_pps_signal() {
    pps_detected = true;
}

// --- LOGIQUE TIME ADDER (+1s) ---
String adjustRmc(String rmc) {
    // Trouve les virgules pour extraire Heure (1) et Date (9)
    // $GPRMC,HHMMSS.ss,A,lat,N,lon,E,spd,cog,DDMMYY,...
    int commas[10];
    int p = 0;
    for(int i=0; i<10; i++) {
        p = rmc.indexOf(',', p);
        if(p == -1) return rmc; 
        commas[i] = p;
        p++;
    }
    
    // Diagnostic : Vérification du statut (Champ 2, après la 2ème virgule)
    // $GPRMC,HHMMSS.ss,A,...
    if (rmc.charAt(commas[1] + 1) == 'A') gps_fix = true; else gps_fix = false;

    String sTime = rmc.substring(commas[0]+1, commas[1]);
    String sDate = rmc.substring(commas[8]+1, commas[9]);
    if (sTime.length() < 6 || sDate.length() < 6) return rmc;

    long t = sTime.substring(0, 6).toInt();
    long d = sDate.toInt();
    int h=t/10000, m=(t%10000)/100, s=t%100;
    int D=d/10000, M=(d%10000)/100, Y=d%100;

    // Ajout 1 seconde
    if (++s >= 60) { s=0; m++; }
    if (m >= 60) { m=0; h++; }
    if (h >= 24) { 
        h=0; D++;
        int dim = 31;
        if(M==4||M==6||M==9||M==11) dim=30;
        if(M==2) dim = (Y%4==0) ? 29 : 28;
        if(D > dim) { D=1; M++; }
        if(M > 12) { M=1; Y++; }
    }

    char buf[10];
    sprintf(buf, "%02d%02d%02d", h, m, s);
    String newTime = String(buf) + sTime.substring(6); // Garde .ss
    sprintf(buf, "%02d%02d%02d", D, M, Y);
    String newDate = String(buf);

    // Reconstruction corps (entre $ et *)
    String body = "GPRMC," + newTime + rmc.substring(commas[1], commas[8]+1) + newDate + rmc.substring(commas[9], rmc.indexOf('*'));
    
    // Checksum
    int sum = 0;
    for(unsigned int i=0; i<body.length(); i++) sum ^= body[i];
    String hex = String(sum, HEX);
    hex.toUpperCase();
    if (hex.length() < 2) hex = "0" + hex;
    
    return "$" + body + "*" + hex + "\r\n";
}

void setup() {
    // Initialisation du port USB
    GpsUSB.begin(115200);
    
    // Initialisation du GPS sur le port série matériel (UART0)
    Serial1.begin(9600);
    
    // Init PPS
    pinMode(PPS_PIN, INPUT);
    attachInterrupt(digitalPinToInterrupt(PPS_PIN), on_pps_signal, RISING);

    // Init LED Diagnostic
    pixels.begin();
    pixels.setBrightness(30); // Luminosité modérée (max 255)

    // Message de démarrage (comme dans main.py)
    // Attente optionnelle du port série
    if (GpsUSB) GpsUSB.println("RP2040 Stratum 0 v" + FIRMWARE_VERSION + " : Mode PPS Aligned (+1s fix)");
}

void loop() {
    // 1. Lecture et Buffering du GPS
    while (Serial1.available()) {
        char c = Serial1.read();
        last_rx_time = millis(); // On a reçu quelque chose
        inputBuffer += c;
        if (c == '\n') {
            // Fin de ligne détectée
            if (inputBuffer.startsWith("$GPRMC")) {
                // On stocke la trame RMC pour la synchroniser avec le PPS
                // On ajoute 1s pour compenser le fait qu'elle sera envoyée au PROCHAIN PPS
                lastRmc = adjustRmc(inputBuffer);
            } else {
                // Les autres trames passent tout de suite
                GpsUSB.print(inputBuffer);
            }
            inputBuffer = "";
        }
    }

    // 2. Gestion du PPS (Synchronisation)
    if (pps_detected) {
        pps_detected = false;
        pps_flash_time = millis(); // Déclenche le flash visuel
        
        // Envoi de la trame RMC stockée (si disponible)
        if (lastRmc.length() > 0) {
            GpsUSB.print(lastRmc);
            lastRmc = "";
        }
    }

    // 3. Gestion de la LED de Diagnostic
    unsigned long now = millis();
    
    if (now - pps_flash_time < 100) {
        pixels.setPixelColor(0, pixels.Color(255, 255, 255)); // FLASH BLANC (PPS)
    } else if (now - last_rx_time > 2000) {
        pixels.setPixelColor(0, pixels.Color(0, 0, 255));     // BLEU (Pas de data > 2s)
        gps_fix = false; // Perte présumée du fix si plus de data
    } else if (gps_fix) {
        if (now - pps_flash_time < 5000) {
            // PPS Actif (< 5s) : On éteint la LED (seul le flash blanc est visible)
            pixels.setPixelColor(0, pixels.Color(0, 0, 0));
        } else {
            pixels.setPixelColor(0, pixels.Color(0, 255, 0)); // VERT (Fix OK, PPS Perdu/Absent)
        }
    } else {
        pixels.setPixelColor(0, pixels.Color(255, 0, 0));     // ROUGE (Data OK, mais pas de Fix)
    }
    pixels.show();
}
