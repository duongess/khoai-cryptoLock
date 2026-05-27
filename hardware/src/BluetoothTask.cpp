#include "BluetoothTask.h"
#include "Config.h"
#include "ProcessTask.h"
#include <SoftwareSerial.h>

SoftwareSerial hc05(HC05_RX_PIN, HC05_TX_PIN);
String btBuffer = "";

void BT_Init() {
  hc05.begin(BT_BAUD_RATE);
  btBuffer.reserve(64);
  Serial.println("[LOG] BT Init Done");
}

void BT_Listen() {
  while (hc05.available() > 0) {
    char c = hc05.read();
    if (c == '\n') {
      btBuffer.trim();
      
      PC_SendMessage("REQ", btBuffer);
      
      btBuffer = ""; 
    } else {
      btBuffer += c;
    }
  }
}

void BT_SendMessage(String message) {
  hc05.println(message);
}