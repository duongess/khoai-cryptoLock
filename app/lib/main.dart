import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

// ==========================================
// THÀNH PHẦN 1: CÁC BIẾN TOÀN CỤC
// ==========================================
const String TARGET_BLUETOOTH_NAME = "NHOM5_MHT1"; 
const String TARGET_MAC_ADDRESS = "20:16:04:18:22:25"; 

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

// ==========================================
// THÀNH PHẦN 2: LỚP GIAO DIỆN CHUYỂN MÀN HÌNH
// ==========================================
class AuthGateWay extends StatefulWidget {
  const AuthGateWay({super.key});

  @override
  State<AuthGateWay> createState() => _AuthGateWayState();
}

class _AuthGateWayState extends State<AuthGateWay> {
  @override
  void initState() {
    super.initState(); // FIX 1: Đổi thành super.initState()
    _startBluetoothConnectionMock();
  }

  Future<void> _startBluetoothConnectionMock() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    // FIX 2: Đổi bluetoothOpacity thành bluetoothScan
    if (statuses[Permission.bluetoothScan] == PermissionStatus.granted &&
        statuses[Permission.bluetoothConnect] == PermissionStatus.granted) {
        
        print("Đã có đủ quyền phần cứng, bắt đầu kết nối HC-05...");
        
        // Giả lập thời gian kết nối
        Timer(const Duration(seconds: 4), () {
          setState(() {
            currentAuthStatus = AuthStatus.success; 
          });
        });
    } else {
      setState(() {
        currentAuthStatus = AuthStatus.failed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentAuthStatus == AuthStatus.success) {
      return const MainControlScreen();
    }
    
    // FIX 3: Truyền hàm gọi lại (callback) sang màn hình Radar
    return RadarScanScreen(
      onRetry: () {
        setState(() {
          currentAuthStatus = AuthStatus.scanning;
        });
        _startBluetoothConnectionMock();
      },
    );
  }
}

// ==========================================
// THÀNH PHẦN 3: LỚP MÀN HÌNH QUÉT RADAR
// ==========================================
class RadarScanScreen extends StatefulWidget {
  final VoidCallback onRetry; // Thêm biến nhận callback

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
                Icon(
                  isFailed ? Icons.gpp_bad : Icons.bluetooth_searching,
                  size: 50,
                  color: isFailed ? Colors.red : Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 50),
            Text(
              isFailed ? "KẾT NỐI KHÔNG PHÙ HỢP" : "HÃY KẾT NỐI ĐẾN BLUETOOTH CỬA",
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
                onPressed: widget.onRetry, // Sử dụng hàm callback từ Gateway truyền sang
                child: const Text("Thử kết nối lại"),
              )
            ]
          ],
        ),
      ),
    );
  }
}

// ==========================================
// THÀNH PHẦN 4: LỚP MÀN HÌNH ĐIỀU KHIỂN CHÍNH
// ==========================================
class MainControlScreen extends StatefulWidget {
  const MainControlScreen({super.key});

  @override
  State<MainControlScreen> createState() => _MainControlScreenState();
}

class _MainControlScreenState extends State<MainControlScreen> {
  
  void _sendRequestKeyCommand() {
    print("Đang gửi chuỗi dữ liệu 32 byte đăng ký qua Bluetooth...");
    setState(() {
      isDeviceApproved = true; 
    });
  }

  void _sendOpenDoorCommand() {
    print("Gửi lệnh: OPEN_DOOR_CMD");
  }

  void _sendCloseDoorCommand() {
    print("Gửi lệnh: CLOSE_DOOR_CMD");
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
            onPressed: () {
              currentAuthStatus = AuthStatus.scanning;
              isDeviceApproved = false;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MyApp()));
            },
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
          "Thiết bị chưa được cấp quyền",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          "Vui lòng nhấn nút dưới đây để gửi mã khóa công khai 32 bytes lên màn hình quản lý Processing.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 40),
        ElevatedButton.icon(
          onPressed: _sendRequestKeyCommand,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            backgroundColor: Colors.amber,
            foregroundColor: Colors.black,
          ),
          icon: const Icon(Icons.vpn_key),
          label: const Text("YÊU CẦU XÁC NHẬN KEY", style: TextStyle(fontWeight: FontWeight.bold)),
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
          "Hệ thống đã sẵn sàng",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        const SizedBox(height: 50),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _sendOpenDoorCommand,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.lock_open, size: 28),
              label: const Text("MỞ CỬA", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton.icon(
              onPressed: _sendCloseDoorCommand,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.lock, size: 28),
              label: const Text("ĐÓNG CỬA", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }
}