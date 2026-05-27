import processing.serial.*;

Serial myPort;
PFont robotoFont;
ArrayList<KeyLog> logs = new ArrayList<KeyLog>();

void setup() {
  size(850, 600);
  smooth();
  
  // Nạp font chữ để giao diện không bị lỗi font
  robotoFont = createFont("Roboto.ttf", 16);
  textFont(robotoFont);
  
  try {
    // CHÚ Ý: Đổi "/dev/ttyACM0" thành tên cổng COM thực tế của bạn (VD: "COM3")
    myPort = new Serial(this, "/dev/ttyACM0", 9600); 
    myPort.bufferUntil('\n');
    addLog("SYSTEM", "Mo cong Serial thanh cong");
  } catch(Exception e) {
    println("Loi mo cong Serial. Kiem tra lai day cap.");
    addLog("SYSTEM", "LOI KET NOI SERIAL");
  }
}

void draw() {
  background(30, 35, 45); // Nền xám tối
  drawDashboard();
}

void mousePressed() {
  handleMouseClick();
}

// Hàm thêm log vào mảng, chỉ giữ lại 10 phần tử mới nhất
void addLog(String keyData, String status) {
  String timeStamp = nf(hour(), 2) + ":" + nf(minute(), 2) + ":" + nf(second(), 2);
  logs.add(new KeyLog(timeStamp, keyData, status));
  
  if (logs.size() > 10) {
    logs.remove(0); 
  }
}

// Lớp đối tượng lưu trữ dữ liệu 1 dòng log
class KeyLog {
  String time;
  String keyData;
  String status;
  
  KeyLog(String t, String k, String s) {
    time = t;
    keyData = k;
    status = s;
  }
}