#ifndef PROCESS_TASK_H
#define PROCESS_TASK_H

#include <Arduino.h>

// Khởi tạo Hardware Serial
void PC_Init();

// Hàm lắng nghe dữ liệu từ Processing, gọi liên tục trong loop()
void PC_Listen();

// Hàm gửi tin nhắn/mã khóa lên Processing
void PC_SendMessage(String key, String message);

#endif // PROCESS_TASK_H