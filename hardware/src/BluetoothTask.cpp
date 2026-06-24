#include "BluetoothTask.h"
#include "Config.h"
#include "ProcessTask.h"
#include <SoftwareSerial.h>

SoftwareSerial hc05(HC05_TX_PIN, HC05_RX_PIN);
String btBuffer = "";

void BT_Init() {
  hc05.begin(BT_BAUD_RATE);
  // Tang vung dem len 256 byte de chua du Public Key va Signature
  btBuffer.reserve(256);
  Serial.println("[LOG] BT Init Done");
}

void BT_Listen() {
  while (hc05.available() > 0) {
    char c = hc05.read();

    if (c == '\n') {
      btBuffer.trim();
      Serial.print("[BUFFER NHAN DUOC] '");
      Serial.print(btBuffer);
      Serial.println("'");
      
      if (btBuffer.length() > 0) {
        PC_SendMessage("REQ", btBuffer);
      }
      btBuffer = "";
      btBuffer.reserve(256);
    } else {
      if (c != '\r') {
        if (btBuffer.length() < 250) {
          btBuffer += c;
        } else {
          Serial.println("[CANH BAO] Buffer day 250 byte, bo ky tu!");
        }
      }
    }
  }
}

void BT_SendMessage(String message) {
  hc05.println(message);
}