void serialEvent(Serial port) {
  String inString = port.readStringUntil('\n');
  
  if (inString != null) {
    inString = trim(inString);
    if (inString.startsWith("[REQ]")) {
      String payload = inString.substring(6).trim();
      
      if (payload.startsWith("KEY_REQUEST")) {
        verifyECC(payload);
      }
      else if (payload.startsWith("OPEN_DOOR_CMD") && checkAccept(payload)) {
        sendCommand("[CMD]DO_OPEN");
      }
      else if (payload.startsWith("CLOSE_DOOR_CMD") && checkAccept(payload)) {
        sendCommand("[CMD]DO_CLOSE");
      }
      else {
        sendCommand("[CMD]ERROR_KEY");
        // Tu dong ghi nhan key bi tu choi va luu vao file
        String[] parts = split(payload, " ");
        if (parts.length >= 2) {
          String invalidKey = parts[1];
          String timeStamp = nf(hour(), 2) + ":" + nf(minute(), 2) + ":" + nf(second(), 2);
          logs.add(new KeyLog(invalidKey, timeStamp, "DECLINE"));
          saveKeysDB();
        }
      }
    } 
    else if (inString.startsWith("[LOG]")) {
      println("ARDUINO: " + inString);
    }
  }
}

void sendCommand(String cmd) {
  if (myPort != null) {
    myPort.write(cmd + "\n");
  }
}