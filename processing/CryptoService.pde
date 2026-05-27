import java.security.KeyFactory;
import java.security.PublicKey;
import java.security.Signature;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;

boolean checkAccept(String payload) {
  String[] parts = split(payload, " ");
  if (parts.length < 3) return false; 
  
  String incomingPublicKey = parts[1];
  String signatureBase64 = parts[2];
  
  // 1. Quet kiem tra key nhan duoc trong database keys.db xem co hop le khong
  boolean isAuthorized = false;
  String[] savedKeys = loadStrings("data/keys.db");
  if (savedKeys == null || savedKeys.length == 0) return false;
  
  for (String line : savedKeys) {
    String[] pieces = split(line, ",");
    if (pieces.length >= 3) {
      // Neu tim thay key va trang thai phai la ACCEPT
      if (pieces[0].equals(incomingPublicKey) && pieces[2].equals("ACCEPT")) {
        isAuthorized = true;
        break;
      }
    }
  }
  if (!isAuthorized) return false;
  
  // 2. Xac minh chu ky ECC
  String originalMessage = "KHOAI_DOOR_UNLOCK";
  try {
    byte[] publicKeyBytes = Base64.getDecoder().decode(incomingPublicKey);
    byte[] signatureBytes = Base64.getDecoder().decode(signatureBase64);
    
    X509EncodedKeySpec keySpec = new X509EncodedKeySpec(publicKeyBytes);
    KeyFactory keyFactory = KeyFactory.getInstance("EC");
    PublicKey publicKey = keyFactory.generatePublic(keySpec);
    
    Signature ecdsaVerify = Signature.getInstance("SHA256withECDSA");
    ecdsaVerify.initVerify(publicKey);
    ecdsaVerify.update(originalMessage.getBytes("UTF-8"));
    
    return ecdsaVerify.verify(signatureBytes);
  } catch (Exception e) {
    println("Loi giai ma ECC: " + e.getMessage());
    return false;
  }
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
        l.status = "ACCEPT";
        l.time = timeStamp;
        exists = true;
        break;
      }
    }
    if (!exists) {
      logs.add(new KeyLog(publicKeyToSave, timeStamp, "ACCEPT"));
    }
    saveKeysDB();
  }
}