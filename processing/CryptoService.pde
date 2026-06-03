import java.security.KeyFactory;
import java.security.PublicKey;
import java.security.Signature;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;

boolean checkAccept(String payload) {
  // Su dung splitTokens de tranh loi parse khi co nhieu khoang trang
  String[] parts = splitTokens(payload, " ");
  if (parts.length < 2) return false; 
  
  // Them trim() de loai bo cac ky tu an (nhu \r, \n)
  String incomingKey = parts[1].trim();
  
  // 1. Quet kiem tra key nhan duoc xem co hop le khong bang cach tim tren RAM (danh sach 'logs')
  for (KeyLog l : logs) {
    if (l.keyData.trim().equals(incomingKey) && l.status.trim().equals("ACCEPT")) {
      return true;
    }
  }
  return false;
}

void verifyECC(String payload) {
  String[] parts = split(payload, " ");
  if (parts.length >= 2) {
    String publicKeyToSave = parts[1];
    String timeStamp = nf(hour(), 2) + ":" + nf(minute(), 2) + ":" + nf(second(), 2);
    
    // Kiem tra neu key da ton tai thi ghi de trang thai, neu chua thi them moi
    boolean exists = false;
    for (KeyLog l : logs) {
      if (l.keyData.equals(publicKeyToSave)) {
        // Chi cap nhat thanh PENDING neu key chua duoc phe duyet truoc do
        if (!l.status.equals("ACCEPT")) {
          l.status = "PENDING";
          l.time = timeStamp;
        }
        exists = true;
        break;
      }
    }
    if (!exists) {
      logs.add(new KeyLog(publicKeyToSave, timeStamp, "PENDING"));
    }
    saveKeysDB();
  }
}
