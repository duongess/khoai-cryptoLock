#include "MotorTask.h"
#include "Config.h"
#include <AccelStepper.h>
#include <ProcessTask.h>

// Thu tu chan giu nguyen theo Macro
AccelStepper stepper(AccelStepper::HALF4WIRE, MOTOR_IN1, MOTOR_IN3, MOTOR_IN2, MOTOR_IN4);
bool isDoorOpen = false;

void Motor_Init() {
  stepper.setMaxSpeed(MOTOR_MAX_SPEED);
  stepper.setAcceleration(MOTOR_ACCELERATION);
  stepper.setCurrentPosition(0);
  Serial.println("[LOG] Motor Init Done");
}

void Motor_Run() {
  // Tao xung chay dong co (Khong them log vao day de tranh giat lag)
  stepper.run();
}

void Motor_OpenDoor() {
  if (!isDoorOpen) {
    PC_SendMessage("LOG", "Mo cua...");
    stepper.moveTo(STEPS_PER_REV); // Quay 1/4 vong
    isDoorOpen = true;
  }
}

void Motor_CloseDoor() {
  if (isDoorOpen) {
    PC_SendMessage("LOG", "Dong cua...");
    stepper.moveTo(-STEPS_PER_REV); // Ve vi tri goc
    isDoorOpen = false;
  }
}

bool Motor_IsOpen() {
  return isDoorOpen;
}