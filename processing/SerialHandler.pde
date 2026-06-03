void serialEvent(Serial port) {
  String inString = port.readStringUntil('\n');
  println("Received from Serial: " + inString);
  
  if (inString != null) {
    inString = trim(inString);
    if (inString.startsWith("[REQ]")) {
      String payload = inString.substring(6).trim();
      
      if (payload.startsWith("KEY_REQUEST")) {
        verifyECC(payload);
      }
      else if (payload.startsWith("OPEN_DOOR_CMD")) {
        println("Received OPEN_DOOR_CMD, verifying key...");
        if (checkAccept(payload)) {
          sendCommand("[CMD]DO_OPEN");
        } else {
          sendCommand("[CMD]ERROR_KEY");
        }
      }
      else if (payload.startsWith("CLOSE_DOOR_CMD")) {
        println("Received CLOSE_DOOR_CMD, verifying key...");
        if (checkAccept(payload)) {
          sendCommand("[CMD]DO_CLOSE");
        } else {
          sendCommand("[CMD]ERROR_KEY");
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
