void serialEvent(Serial port) {
  String inString = port.readStringUntil('\n');
  
  if (inString != null) {
    inString = trim(inString);
    
    if (inString.startsWith("[REQ]")) {
      // Tách lấy phần payload phía sau chuỗi [REQ]
      String payload = inString.substring(5).trim();
      
      // 1. Xử lý kịch bản Đóng Cửa (Không cần giải mã ECC)
      if (payload.equals("CLOSE_DOOR_CMD")) {
        sendCommand("[CMD]DO_CLOSE");
        addLog("APP COMMAND", "DONG CUA");
        return; // Thoát hàm luôn, không chạy xuống phần verifyECC nữa
      }
      
      // 2. Xử lý kịch bản Mở Cửa (Bắt buộc phải qua giải mã)
      boolean isValid = verifyECC(payload);
      
      if (isValid) {
        sendCommand("[CMD]DO_OPEN");
        addLog(payload, "HOP LE");
      } else {
        sendCommand("[CMD]ERROR_KEY");
        addLog(payload, "TU CHOI");
      }
    } 
    else if (inString.startsWith("[LOG]")) {
      // In log hệ thống ra console của Arduino (không hiện lên UI)
      println("ARDUINO: " + inString);
    }
  }
}

void sendCommand(String cmd) {
  if (myPort != null) {
    myPort.write(cmd + "\n");
    println("[LOG] Da gui lenh xuong Arduino: " + cmd);
  } else {
    println("Loi: Cong Serial chua mo");
  }
}