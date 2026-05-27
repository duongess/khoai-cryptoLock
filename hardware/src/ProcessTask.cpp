#include "ProcessTask.h"
#include "Config.h"
#include "MotorTask.h"
#include "BluetoothTask.h"

String pcBuffer = "";

void PC_Init() {
  Serial.begin(PC_BAUD_RATE);
  pcBuffer.reserve(64);
  Serial.println("[LOG] PC Serial Init Done");
}

void PC_Listen() {
  while (Serial.available() > 0) {
    char c = Serial.read();
    if (c == '\n') {
      pcBuffer.trim();
      
      // Xu ly phan hoi cu the tu Processing
      if (pcBuffer == "[CMD]DO_OPEN") {
        Motor_OpenDoor();
        BT_SendMessage("DOOR_OPENED");
      } 
      else if (pcBuffer == "[CMD]DO_CLOSE") {
        Motor_CloseDoor();
        BT_SendMessage("DOOR_CLOSED"); 
      }
      else if (pcBuffer == "[CMD]ERROR_KEY") {
        BT_SendMessage("AUTH_FAILED"); 
      }
      
      pcBuffer = ""; 
    } else {
      pcBuffer += c;
    }
  }
}

void PC_SendMessage(String type, String payload) {
  Serial.println("[" + type + "] " + payload); 
}