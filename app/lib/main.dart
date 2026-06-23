import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Thu vien luu tru cuc bo

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
      title: 'Khoai Lock',
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
    // Yeu cau quyen co ban
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
      setState(() { 
        currentAuthStatus = (_connection != null && _connection!.isConnected) 
            ? AuthStatus.success 
            : AuthStatus.failed; 
      });
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

class RadarScanScreen extends StatelessWidget {
  final VoidCallback onRetry; 
  const RadarScanScreen({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    bool isFailed = currentAuthStatus == AuthStatus.failed;
    return Scaffold(
      backgroundColor: isFailed ? const Color(0xFF2A0808) : const Color(0xFF0A1128),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isFailed ? "KET NOI THAT BAI" : "DANG QUET BLUETOOTH...",
              style: TextStyle(color: isFailed ? Colors.red : Colors.blue, fontSize: 18),
            ),
            if (isFailed) ...[
              const SizedBox(height: 20),
              ElevatedButton(onPressed: onRetry, child: const Text("Thu lai"))
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
  StreamSubscription? _incomingSubscription;
  String _rxBuffer = ""; 
  bool _isKeyInitialized = false; 
  String _localKey = ""; // Chuoi khoa xac thuc don gian

  @override
  void initState() {
    super.initState();
    _initSimpleAuthAndBluetooth(); 
  }

  Future<void> _initSimpleAuthAndBluetooth() async {
    // Kiem tra trong may da co key chua, neu chua thi tao va luu lai
    final prefs = await SharedPreferences.getInstance();
    String? savedKey = prefs.getString('khoai_lock_simple_key');
    
    if (savedKey == null || savedKey.isEmpty) {
      savedKey = _generateRandomKey(16); // Tao key 16 ky tu
      await prefs.setString('khoai_lock_simple_key', savedKey);
    }
    
    _localKey = savedKey;
    if (mounted) {
      setState(() { _isKeyInitialized = true; });
    }
    _listenToBluetoothStream();
  }

  // Ham tao chuoi ngau nhien don gian
  String _generateRandomKey(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = math.Random();
    return String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))
    ));
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
      _showNotification("Xac thuc that bai!");
      _logout();
    } else if (msg == "DOOR_OPENED") {
      _showNotification("Cua da mo!");
    } else if (msg == "DOOR_CLOSED") {
      _showNotification("Cua da dong!");
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
    int chunkSize = 16; 
    
    try {
      for (int i = 0; i < bytes.length; i += chunkSize) {
        int end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        Uint8List chunk = bytes.sublist(i, end);
        widget.connection.output.add(chunk);
        await widget.connection.output.allSent;
        await Future.delayed(const Duration(milliseconds: 50)); 
      }
    } catch (e) {
      print("Loi gui data: $e");
    }
  }

  void _sendRequestKeyCommand() {
    _sendChunkedMessage("KEY_REQUEST $_localKey\n"); 
  }

  void _sendOpenDoorCommand() {
    // Khong can chu ky nua, chi gui key
    _sendChunkedMessage("OPEN_DOOR_CMD $_localKey\n");
  }

  void _sendCloseDoorCommand() {
    _sendChunkedMessage("CLOSE_DOOR_CMD $_localKey\n");
  }

  void _showNotification(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Khoai Lock Dashboard"),
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
        const Text("Thiet bi chua cap quyen", style: TextStyle(fontSize: 20)),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isKeyInitialized ? _sendRequestKeyCommand : null,
          child: const Text("YEU CAU CAP QUYEN"),
        ),
      ],
    );
  }

  Widget _buildDoorControlView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("He thong san sang", style: TextStyle(fontSize: 22, color: Colors.green)),
        const SizedBox(height: 50),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _isKeyInitialized ? _sendOpenDoorCommand : null, 
              child: const Text("MO CUA"),
            ),
            ElevatedButton(
              onPressed: _isKeyInitialized ? _sendCloseDoorCommand : null,
              child: const Text("DONG CUA"),
            ),
          ],
        ),
      ],
    );
  }
}