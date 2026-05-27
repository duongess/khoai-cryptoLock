#ifndef KHOAI_CONFIG_H
#define KHOAI_CONFIG_H

#include <Arduino.h>

// ==========================================
// 1. CẤU HÌNH CHÂN (PINS)
// ==========================================
#define HC05_RX_PIN 3
#define HC05_TX_PIN 2

// Thứ tự chân cho thư viện AccelStepper (IN1, IN3, IN2, IN4)
#define MOTOR_IN1 8
#define MOTOR_IN2 9
#define MOTOR_IN3 10
#define MOTOR_IN4 11

// ==========================================
// 2. CẤU HÌNH TỐC ĐỘ (BAUD RATE)
// ==========================================
#define PC_BAUD_RATE 9600   // Giao tiếp cáp USB với Processing
#define BT_BAUD_RATE 38400    // Giao tiếp HC-05

// ==========================================
// 3. THÔNG SỐ ĐỘNG CƠ (28BYJ-48)
// ==========================================
#define MOTOR_MAX_SPEED 2000.0
#define MOTOR_ACCELERATION 500.0
#define STEPS_PER_REV 2048

#endif // KHOAI_CONFIG_H