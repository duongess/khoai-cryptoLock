// Tọa độ và kích thước 2 nút bấm
int btnOpenX = 50, btnOpenY = 500, btnW = 150, btnH = 50;
int btnCloseX = 220, btnCloseY = 500;

void drawDashboard() {
  fill(255);
  textSize(24);
  text("KHOAI CRYPTOLOCK - QUAN LY TRUNG TAM", 50, 40);
  
  drawTable();
  drawButtons();
}

void drawTable() {
  // Vẽ tiêu đề bảng
  fill(80, 90, 110);
  rect(50, 70, 750, 40);
  fill(255);
  textSize(16);
  text("THOI GIAN", 60, 95);
  text("MA KHOA (PAYLOAD)", 180, 95);
  text("TRANG THAI", 650, 95);
  
  // Vẽ các hàng dữ liệu
  for (int i = 0; i < logs.size(); i++) {
    KeyLog l = logs.get(i);
    int yPos = 140 + i * 35;
    
    // Màu nền xen kẽ cho dễ đọc
    if (i % 2 == 0) fill(45, 50, 65);
    else fill(40, 45, 55);
    
    rect(50, yPos - 25, 750, 30);
    
    fill(200);
    text(l.time, 60, yPos - 5);
    
    // Cắt bớt chuỗi key nếu quá dài
    String displayKey = l.keyData;
    if (displayKey.length() > 40) {
      displayKey = displayKey.substring(0, 40) + "...";
    }
    text(displayKey, 180, yPos - 5);
    
    // Đổi màu chữ theo trạng thái
    if (l.status.equals("HOP LE")) fill(0, 200, 100);
    else if (l.status.equals("TU CHOI")) fill(255, 80, 80);
    else fill(255, 200, 0);
    
    text(l.status, 650, yPos - 5);
  }
}

void drawButtons() {
  // Nút Mở
  fill(0, 150, 80);
  rect(btnOpenX, btnOpenY, btnW, btnH, 5);
  fill(255);
  text("MO CUA", btnOpenX + 40, btnOpenY + 32);
  
  // Nút Đóng
  fill(200, 50, 50);
  rect(btnCloseX, btnCloseY, btnW, btnH, 5);
  fill(255);
  text("DONG CUA", btnCloseX + 30, btnCloseY + 32);
}

void handleMouseClick() {
  // Kiểm tra tọa độ click Mở cửa
  if (mouseX > btnOpenX && mouseX < btnOpenX + btnW && mouseY > btnOpenY && mouseY < btnOpenY + btnH) {
    sendCommand("[CMD]DO_OPEN");
    addLog("MANUAL", "MO CUA (UI)");
  }
  
  // Kiểm tra tọa độ click Đóng cửa
  if (mouseX > btnCloseX && mouseX < btnCloseX + btnW && mouseY > btnCloseY && mouseY < btnCloseY + btnH) {
    sendCommand("[CMD]DO_CLOSE");
    addLog("MANUAL", "DONG CUA (UI)");
  }
}