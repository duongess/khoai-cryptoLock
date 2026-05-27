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
  fill(80, 90, 110);
  rect(50, 70, 750, 40);
  fill(255);
  textSize(16);
  text("MA KHOA (KEY)", 60, 95);
  text("THOI GIAN", 460, 95);
  text("TRANG THAI / HANH DONG", 620, 95);
  
  for (int i = 0; i < logs.size(); i++) {
    KeyLog l = logs.get(i);
    int yPos = 140 + i * 35;
    
    if (i % 2 == 0) fill(45, 50, 65);
    else fill(40, 45, 55);
    rect(50, yPos - 25, 750, 30);
    
    fill(200);
    String displayKey = l.keyData;
    if (displayKey.length() > 38) {
      displayKey = displayKey.substring(0, 38) + "...";
    }
    text(displayKey, 60, yPos - 5);
    text(l.time, 460, yPos - 5);
    
    // Xu ly mau sac va hien thi nut hanh dong theo loai trang thai
    if (l.status.equals("ACCEPT")) {
      fill(0, 200, 100);
      text("ACCEPT [XOA]", 620, yPos - 5); // Bấm truc tiep vao hang de Delete
    } else if (l.status.equals("DECLINE")) {
      fill(255, 80, 80);
      text("DECLINE", 620, yPos - 5);
    } else {
      fill(255, 200, 0);
      text(l.status, 620, yPos - 5);
    }
  }
}

void drawButtons() {
  fill(0, 150, 80);
  rect(btnOpenX, btnOpenY, btnW, btnH, 5);
  fill(255);
  text("MO CUA", btnOpenX + 40, btnOpenY + 32);
  
  fill(200, 50, 50);
  rect(btnCloseX, btnCloseY, btnW, btnH, 5);
  fill(255);
  text("DONG CUA", btnCloseX + 30, btnCloseY + 32);
}

void handleMouseClick() {
  if (mouseX > btnOpenX && mouseX < btnOpenX + btnW && mouseY > btnOpenY && mouseY < btnOpenY + btnH) {
    sendCommand("[CMD]DO_OPEN");
  }
  
  if (mouseX > btnCloseX && mouseX < btnCloseX + btnW && mouseY > btnCloseY && mouseY < btnCloseY + btnH) {
    sendCommand("[CMD]DO_CLOSE");
  }
  
  // Kiem tra tuong tac click vao vung bang du lieu de xoa key da dang ky
  for (int i = 0; i < logs.size(); i++) {
    int yPos = 140 + i * 35;
    if (mouseX > 50 && mouseX < 800 && mouseY > yPos - 25 && mouseY < yPos + 5) {
      KeyLog l = logs.get(i);
      if (l.status.equals("ACCEPT")) {
        logs.remove(i); // Xoa khoi danh sach neu chu so huu bam vao [XOA]
        saveKeysDB(); // Cap nhat lai database keys.db
        break;
      }
    }
  }
}