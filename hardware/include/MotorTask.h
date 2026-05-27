#ifndef MOTOR_TASK_H
#define MOTOR_TASK_H

// Khởi tạo phần cứng động cơ
void Motor_Init();

// Hàm chạy động cơ (BẮT BUỘC phải gọi liên tục trong loop() của main)
void Motor_Run();

// Các lệnh điều khiển từ bên ngoài
void Motor_OpenDoor();
void Motor_CloseDoor(); 

// Trả về trạng thái cửa hiện tại (true = đang mở, false = đang đóng)
bool Motor_IsOpen();

#endif // MOTOR_TASK_H