// Hàm giả lập xác thực ECC (Sẽ thay bằng logic BouncyCastle sau)
boolean verifyECC(String payload) {
  
  // Dành cho kịch bản App gửi Key Demo lúc trước
  if (payload.contains("KEY_REQUEST_DEMO_1234567890")) {
    return true;
  }
  
  // Nếu payload sai hoặc bị nhiễu
  return false;
}