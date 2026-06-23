#ifndef KHOAI_CONFIG_H
#define KHOAI_CONFIG_H

#include <Arduino.h>

// ==========================================
// 1. CẤU HÌNH CHÂN (PINS)
// ==========================================
#define HC05_RX_PIN 2
#define HC05_TX_PIN 3

// Thứ tự chân cho thư viện Servo.h (chân PWM)
#define SERVO_PIN A0

// ==========================================
// 2. CẤU HÌNH TỐC ĐỘ (BAUD RATE)
// ==========================================
#define PC_BAUD_RATE 9600   // Giao tiếp cáp USB với Processing
#define BT_BAUD_RATE 9600    // Giao tiếp HC-05

// ==========================================
// 3. THÔNG SỐ ĐỘNG CƠ (28BYJ-48)
// ==========================================
#define MOTOR_MAX_SPEED 2000.0
#define MOTOR_ACCELERATION 500.0
#define STEPS_PER_REV 2048

#endif // KHOAI_CONFIG_H