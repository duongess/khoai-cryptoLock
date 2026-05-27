#ifndef BLUETOOTH_TASK_H
#define BLUETOOTH_TASK_H

#include <Arduino.h>

// Khởi tạo SoftwareSerial cho HC-05
void BT_Init();

// Hàm lắng nghe dữ liệu, gọi liên tục trong loop()
void BT_Listen();

// Hàm gửi tin nhắn trả ngược về App điện thoại
void BT_SendMessage(String message);

#endif // BLUETOOTH_TASK_H