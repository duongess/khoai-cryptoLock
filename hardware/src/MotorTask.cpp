#include "MotorTask.h"
#include "Config.h"
#include <ProcessTask.h>
#include <Servo.h>

Servo doorServo;
bool isDoorOpen = false;

void Motor_Init() {
  doorServo.attach(SERVO_PIN);
  doorServo.write(180); // Đặt servo về vị trí ban đầu
  Serial.println("[LOG] Motor Init Done");
}

void Motor_OpenDoor() {
  if (!isDoorOpen) {
    PC_SendMessage("LOG", "Mo cua...");
    doorServo.write(90); // Quay servo đến vị trí mở cửa
    isDoorOpen = true;
  }
}

void Motor_CloseDoor() {
  if (isDoorOpen) {
    PC_SendMessage("LOG", "Dong cua...");
    doorServo.write(180); // Quay servo về vị trí đóng cửa
    isDoorOpen = false;
  }
}

bool Motor_IsOpen() {
  return isDoorOpen;
}