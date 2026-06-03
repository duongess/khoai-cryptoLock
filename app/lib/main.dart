import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';
import 'package:cryptography/cryptography.dart';

const String TARGET_BLUETOOTH_NAME = "NHOM5_MHT1"; 
const String TARGET_MAC_ADDRESS = "00:25:11:02:84:46"; 

enum AuthStatus { scanning, failed, success }
AuthStatus currentAuthStatus = AuthStatus.scanning;

bool isDeviceApproved = false; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Khoai CryptoLock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthGateWay(), 
    );
  }
}

class AuthGateWay extends StatefulWidget {
  const AuthGateWay({super.key});

  @override
  State<AuthGateWay> createState() => _AuthGateWayState();
}

class _AuthGateWayState extends State<AuthGateWay> {
  BluetoothConnection? _connection;

  @override
  void initState() {
    super.initState();
    _startRealBluetoothConnection(); 
  }

  Future<void> _startRealBluetoothConnection() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetoothScan] != PermissionStatus.granted ||
        statuses[Permission.bluetoothConnect] != PermissionStatus.granted) {
      setState(() { currentAuthStatus = AuthStatus.failed; });
      return;
    }

    bool? isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
    if (isEnabled == false) {
      isEnabled = await FlutterBluetoothSerial.instance.requestEnable();
      if (isEnabled != true) {
        setState(() { currentAuthStatus = AuthStatus.failed; });
        return;
      }
    }

    try {
      List<BluetoothDevice> devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      BluetoothDevice? targetDevice;

      for (BluetoothDevice d in devices) {
        if (d.name == TARGET_BLUETOOTH_NAME || d.address == TARGET_MAC_ADDRESS) {
          targetDevice = d;
          break;
        }
      }

      if (targetDevice == null) {
        setState(() { currentAuthStatus = AuthStatus.failed; });
        return;
      }

      _connection = await BluetoothConnection.toAddress(targetDevice.address);

      if (_connection != null && _connection!.isConnected) {
        setState(() { currentAuthStatus = AuthStatus.success; });
      } else {
        setState(() { currentAuthStatus = AuthStatus.failed; });
      }

    } catch (e) {
      setState(() { currentAuthStatus = AuthStatus.failed; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentAuthStatus == AuthStatus.success && _connection != null) {
      return MainControlScreen(connection: _connection!);
    }
    
    return RadarScanScreen(
      onRetry: () {
        setState(() { currentAuthStatus = AuthStatus.scanning; });
        _startRealBluetoothConnection();
      },
    );
  }
}

class RadarScanScreen extends StatefulWidget {
  final VoidCallback onRetry; 

  const RadarScanScreen({super.key, required this.onRetry});

  @override
  State<RadarScanScreen> createState() => _RadarScanScreenState();
}

class _RadarScanScreenState extends State<RadarScanScreen> with TickerProviderStateMixin {
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isFailed = currentAuthStatus == AuthStatus.failed;

    return Scaffold(
      backgroundColor: isFailed ? const Color(0xFF2A0808) : const Color(0xFF0A1128),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _radarController,
                  builder: (context, child) {
                    double progress = (_radarController.value + (index / 3)) % 1.0;
                    return Container(
                      width: progress * 300,
                      height: progress * 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isFailed 
                              ? Colors.red.withOpacity(1.0 - progress)
                              : Colors.blue.withOpacity(1.0 - progress),
                          width: 2,
                        ),
                      ),
                    );
                  },
                );
              })..add(
                const Icon(
                  Icons.bluetooth_searching,
                  size: 50,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 50),
            Text(
              isFailed ? "KET NOI KHONG PHU HOP" : "HAY KET NOI DEN BLUETOOTH CUA",
              style: TextStyle(
                color: isFailed ? Colors.redAccent : Colors.blueAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            if (isFailed) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: widget.onRetry, 
                child: const Text("Thu ket noi lai"),
              )
            ]
          ],
        ),
      ),
    );
  }
}

class MainControlScreen extends StatefulWidget {
  final BluetoothConnection connection;
  const MainControlScreen({super.key, required this.connection});

  @override
  State<MainControlScreen> createState() => _MainControlScreenState();
}

class _MainControlScreenState extends State<MainControlScreen> {
  final CryptoEngine _crypto = CryptoEngine();
  StreamSubscription? _incomingSubscription;
  String _rxBuffer = ""; 
  bool _isKeyInitialized = false; // Biến cờ chặn bấm nút khi khóa chưa sẵn sàng
  String _pubKeyBase64 = ""; // Biến lưu chuỗi khóa công khai để dùng lại

  @override
  void initState() {
    super.initState();
    _initCryptoAndBluetooth(); 
  }

  Future<void> _initCryptoAndBluetooth() async {
    try {
      await _crypto.generateKeyPair();
      _pubKeyBase64 = await _crypto.getPublicKeyAsBase64(); // Lưu key lại 1 lần duy nhất
      if (mounted) {
        setState(() {
          _isKeyInitialized = true; // Mở khóa cho phép bấm nút
        });
      }
      print("[LOG] Key pair khoi tao thanh cong. Key: $_pubKeyBase64");
    } catch (e) {
      print("[LOI PHAN CUNG] Khong the sinh khoa mat ma: $e");
      _pubKeyBase64 = "KEY_GEN_FAILED";
      if (mounted) {
        setState(() {
          _isKeyInitialized = true; 
        });
        _showNotification("Loi tao khoa: $e");
      }
    }
    _listenToBluetoothStream();
  }

  @override
  void dispose() {
    _incomingSubscription?.cancel();
    super.dispose();
  }

  void _listenToBluetoothStream() {
    _incomingSubscription = widget.connection.input?.listen((Uint8List data) {
      _rxBuffer += utf8.decode(data);
      if (_rxBuffer.contains('\n')) {
        List<String> lines = _rxBuffer.split('\n');
        for (int i = 0; i < lines.length - 1; i++) {
          String msg = lines[i].trim();
          _parseIncomingMessage(msg);
        }
        _rxBuffer = lines.last; 
      }
    });
  }

  void _parseIncomingMessage(String msg) {
    if (msg == "APPROVED") {
      setState(() { isDeviceApproved = true; });
    } else if (msg == "AUTH_FAILED") {
      _showNotification("Xac thuc that bai! Khoa bi tu choi.");
      _logout();
    } else if (msg == "DOOR_OPENED") {
      _showNotification("Cua da mo thanh cong!");
    } else if (msg == "DOOR_CLOSED") {
      _showNotification("Cua da duoc khoa chat!");
    }
  }

  void _logout() {
    currentAuthStatus = AuthStatus.scanning;
    isDeviceApproved = false;
    _incomingSubscription?.cancel();
    widget.connection.close(); 
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyApp()));
  }

  Future<void> _sendChunkedMessage(String payload) async {
    Uint8List bytes = utf8.encode(payload);
    int chunkSize = 32;
    
    print("=== BAT DAU GUI ===");
    print("Tong bytes: ${bytes.length}");
    
    // Dua lệnh gui vao cuoi hang doi microtask de UI nhac ngon tay duoc thuc thi truoc
    Future.microtask(() async {
      try {
        for (int i = 0; i < bytes.length; i += chunkSize) {
          int end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
          Uint8List chunk = bytes.sublist(i, end);
          
          widget.connection.output.add(chunk);
          await widget.connection.output.allSent;
          await Future.delayed(const Duration(milliseconds: 20));
        }
        print("=== GUI XONG ===");
      } catch (e) {
        print("=== LOI GUI: $e ===");
      }
    });
  }

  void _sendRequestKeyCommand() {
    String rawPayload = "KEY_REQUEST $_pubKeyBase64\n";
    _sendChunkedMessage(rawPayload); 
  }

  void _sendOpenDoorCommand() {
    String rawPayload = "OPEN_DOOR_CMD $_pubKeyBase64\n";
    _sendChunkedMessage(rawPayload);
  }

  void _sendCloseDoorCommand() {
    String rawPayload = "CLOSE_DOOR_CMD $_pubKeyBase64\n";
    _sendChunkedMessage(rawPayload);
  }

  void _showNotification(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Khoai CryptoLock Dashboard"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: !isDeviceApproved 
              ? _buildPendingRegistrationView()  
              : _buildDoorControlView(),         
        ),
      ),
    );
  }

  Widget _buildPendingRegistrationView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_clock, size: 80, color: Colors.amber),
        const SizedBox(height: 20),
        const Text(
          "Thiet bi chua duoc cap quyen",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          "Vui long nhan nut duoi day de gui ma khoa cong khai len man hinh quan ly Processing.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 40),
        ElevatedButton.icon(
          onPressed: _isKeyInitialized ? _sendRequestKeyCommand : null,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            backgroundColor: _isKeyInitialized ? Colors.amber : Colors.grey,
            foregroundColor: Colors.black,
          ),
          icon: _isKeyInitialized ? const Icon(Icons.vpn_key) : const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)),
          label: Text(_isKeyInitialized ? "YEU CAU XAC NHAN KEY" : "DANG TAO KHOA...", style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildDoorControlView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.verified_user, size: 80, color: Colors.green),
        const SizedBox(height: 20),
        const Text(
          "He thong da san sang",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        const SizedBox(height: 50),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _isKeyInitialized ? _sendOpenDoorCommand : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                backgroundColor: _isKeyInitialized ? Colors.green : Colors.grey,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.lock_open, size: 28),
              label: const Text("MO CUA", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton.icon(
              onPressed: _isKeyInitialized ? _sendCloseDoorCommand : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                backgroundColor: _isKeyInitialized ? Colors.red : Colors.grey,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.lock, size: 28),
              label: const Text("DONG CUA", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}

class CryptoEngine {
  // Sua kieu du lieu thanh lop Cha truu tuong phu hop voi moi thuat toan EC
  KeyPair? _keyPair;
  PublicKey? _publicKey;

  final _algo = Ed25519();

  Future<void> generateKeyPair() async {
    _keyPair = await _algo.newKeyPair();
    _publicKey = await _keyPair!.extractPublicKey();
  }

  Future<String> getPublicKeyAsBase64() async {
    if (_publicKey == null) return "NULL_KEY";
    
    try {
      if (_publicKey is EcPublicKey) {
        final ecPubKey = _publicKey as EcPublicKey;
        final bytes = Uint8List.fromList([...ecPubKey.x, ...ecPubKey.y]);
        return base64Encode(bytes);
      } else if (_publicKey is SimplePublicKey) {
        final simplePubKey = _publicKey as SimplePublicKey;
        return base64Encode(simplePubKey.bytes);
      }
      return "UNKNOWN_KEY_TYPE_${_publicKey.runtimeType}";
    } catch (e) {
      return "ERROR_ENCODE";
    }
  }

  Future<String> signMessage(String message) async {
    if (_keyPair == null) return "";
    final messageBytes = Uint8List.fromList(utf8.encode(message));
    final sig = await _algo.sign(messageBytes, keyPair: _keyPair!);
    return base64Encode(sig.bytes);
  }
}