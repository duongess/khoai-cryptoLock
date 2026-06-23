#include <Arduino.h>
#include "Config.h"
#include "MotorTask.h"
#include "BluetoothTask.h"
#include "ProcessTask.h"

void setup() {
  PC_Init();
  BT_Init();
  Motor_Init();
  
  PC_SendMessage("LOG", "SYS_READY");
}

void loop() {
  // Goi lien tuc khong delay
  BT_Listen();
  PC_Listen();
}