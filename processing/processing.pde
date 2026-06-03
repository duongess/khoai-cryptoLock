import processing.serial.*;

Serial myPort;
PFont robotoFont;
// Danh sach quan ly key load tu file keys.db
ArrayList<KeyLog> logs = new ArrayList<KeyLog>();

void setup() {
  size(850, 600);
  smooth();
  robotoFont = createFont("Roboto.ttf", 16);
  textFont(robotoFont);
  
  // Tai toan bo du lieu key tu file database luc khoi dong
  loadKeysDB();
  
  try {
    myPort = new Serial(this, "/dev/ttyACM0", 9600);
    myPort.bufferUntil('\n');
  } catch(Exception e) {
    println("Loi mo cong Serial. Kiem tra lai day cap.");
  }
}

void draw() {
  background(30, 35, 45); 
  drawDashboard();
}

void mousePressed() {
  handleMouseClick();
}

// Hàm doc du lieu tu file keys.db vao bo nho
void loadKeysDB() {
  logs.clear();
  String[] lines = loadStrings("data/keys.db");
  
  // Neu file khong ton tai (tra ve null), tien hanh khoi tao file trong moi
  if (lines == null) {
    String[] emptyData = new String[0];
    saveStrings("data/keys.db", emptyData);
    println("File database khong ton tai. Da tu dong khoi tao keys.db moi.");
  } else {
    // Neu file da ton tai, thuc hien phan tach du lieu de nap vao chuong trinh
    for (String line : lines) {
      String[] parts = split(line, ",");
      if (parts.length >= 3) {
        logs.add(new KeyLog(parts[0], parts[1], parts[2]));
      }
    }
  }
}

// Hàm luu danh sach hien tai xuong file keys.db
void saveKeysDB() {
  String[] lines = new String[logs.size()];
  for (int i = 0; i < logs.size(); i++) {
    KeyLog l = logs.get(i);
    lines[i] = l.keyData + "," + l.time + "," + l.status;
  }
  saveStrings("data/keys.db", lines);
}

// Lop doi tuong luu thong tin khoa
class KeyLog {
  String keyData;
  String time;
  String status; // "ACCEPT" hoac "DECLINE"
  
  KeyLog(String k, String t, String s) {
    keyData = k;
    time = t;
    status = s;
  }
}
