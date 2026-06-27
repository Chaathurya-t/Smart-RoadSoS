import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ADD THIS
  // ADD THIS
  String riskLevel = "SAFE";
  Color riskColor = Colors.green;
  IconData riskIcon = Icons.check_circle;

  DateTime lastRiskUpdate = DateTime.now();
  int countdown = 10;
  Timer? countdownTimer;
  bool isCountingDown = false;
  String status = "Monitoring";
  bool accidentDetected = false;
  bool isDialogOpen = false;

  double threshold = 70; // balanced
  DateTime lastTrigger = DateTime.now();

  StreamSubscription? sensorSub;

  TextEditingController phoneController = TextEditingController();
  String savedNumber = "";

  double lastForce = 0;

  @override
  void initState() {
    super.initState();
    initApp();
  }

  Future<void> initApp() async {
    await requestPermissions();
    await loadSavedNumber();
    startMonitoring();
  }

  @override
  void dispose() {
    sensorSub?.cancel();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> requestPermissions() async {
    await Permission.location.request();
  }

  // 🔥 LOAD SAVED NUMBER (PERMANENT)
  Future<void> loadSavedNumber() async {
    final prefs = await SharedPreferences.getInstance();
    String? number = prefs.getString('guardian');

    if (number != null) {
      setState(() {
        savedNumber = number;
        phoneController.text = number;
      });
    }
  }

  // 🔥 SAVE NUMBER PERMANENTLY
  Future<void> saveNumber() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('guardian', phoneController.text.trim());

    setState(() {
      savedNumber = phoneController.text.trim();
      status = "✅ Number Saved";
    });
  }

  // 🔥 RELIABLE DETECTION
  void startMonitoring() {
    sensorSub = accelerometerEvents.listen((event) {
      double force =
          (event.x * event.x + event.y * event.y + event.z * event.z);

      double diff = (force - lastForce).abs();
      lastForce = force;

      // ADD THIS (RISK CLASSIFICATION)
      if (!isCountingDown) {
        // Debounce to avoid flicker
        if (DateTime.now().difference(lastRiskUpdate).inMilliseconds > 800) {

          if (force < 25) {
            setState(() {
              riskLevel = "SAFE";
              riskColor = Colors.green;
              riskIcon = Icons.check_circle;
            });
          } 
          else if (force >= 25 && force < threshold) {
            setState(() {
              riskLevel = "HIGH RISK";
              riskColor = Colors.orange;
              riskIcon = Icons.warning;
            });
          }

          lastRiskUpdate = DateTime.now();
        }
      }

      if (DateTime.now().difference(lastTrigger).inSeconds < 3) return;

      if (force > threshold && diff > 15 && !accidentDetected && !isDialogOpen) {
        lastTrigger = DateTime.now();
        accidentDetected = true;
        detectAccident();
      }
    });
  }

  // REPLACE THIS
  void detectAccident() {
    setState(() {
      status = "⚠️ Accident Detected";
      isDialogOpen = true;
      countdown = 10;
      isCountingDown = true;

      // 🔥 ADD THIS (VERY IMPORTANT)
      riskLevel = "ACCIDENT";
      riskColor = Colors.red;
      riskIcon = Icons.warning;
    });


    startCountdown();
  }
  // ADD THIS
  void startCountdown() {
    countdownTimer?.cancel();

    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown == 0) {
        timer.cancel();

        setState(() {
          isCountingDown = false;
        });

        sendSOS();
      }else {
        setState(() {
          countdown--;
        });
      }
    });
  }

  // REPLACE THIS
  void resetState() {
    countdownTimer?.cancel();

    setState(() {
      accidentDetected = false;
      isDialogOpen = false;
      isCountingDown = false;
      countdown = 10;
      status = "Monitoring";
    });
  }

  // 🔥 SOS (WORKING)
  Future<void> sendSOS() async {
    if (savedNumber.isEmpty) {
      setState(() => status = "❗ Enter number first");
      return;
    }

    setState(() => status = "🚑 Sending SOS...");

    Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    String message =
        "🚨 Accident Alert!\nLocation: https://maps.google.com/?q=${pos.latitude},${pos.longitude}";

    final Uri whatsappUri = Uri.parse(
        "https://wa.me/${savedNumber.replaceAll("+", "")}?text=${Uri.encodeComponent(message)}");

    bool opened = false;

    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      opened = true;
    }

    final Uri smsUri =
        Uri.parse("sms:$savedNumber?body=${Uri.encodeComponent(message)}");

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    }

    resetState();

    setState(() => status =
        opened ? "✅ WhatsApp + SMS Ready" : "✅ SMS Ready");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Smart RoadSoS"),
        centerTitle: true,
      ),
      body: isCountingDown
          ? buildEmergencyScreen()
          : SingleChildScrollView(
            child: Column(
            children: [

              const SizedBox(height: 20),

            // 📱 INPUT
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "Guardian Number (91XXXXXXXXXX)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: saveNumber,
                      child: const Text("Save Number"),
                    ),
                  ],
                ),
              ),

            // STATUS
              Container(
                padding: const EdgeInsets.all(25),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      color: Colors.grey.shade300,
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      isCountingDown
                          ? Icons.warning
                          : riskIcon,
                      color: isCountingDown
                          ? Colors.red
                          : riskColor,
                      size: 80,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isCountingDown
                        ? "🚨 Accident Detected"
                        : riskLevel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

            // PANIC
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                onPressed: sendSOS,
                child: const Text(
                  "🚨 PANIC SOS",
                  style: TextStyle(fontSize: 18),
                ),
              ),
              // ADD THIS
              const SizedBox(height: 15),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                onPressed: detectAccident,
                child: const Text(
                  "🧪 Simulate Accident",
                  style: TextStyle(fontSize: 18),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      );
    }
    // ADD THIS
    // ADD THIS
  Widget buildEmergencyScreen() {
    return Container(
      color: Colors.red,
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          const Icon(Icons.warning, color: Colors.white, size: 100),

          const SizedBox(height: 20),

          const Text(
            "🚨 Accident Detected",
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            "$countdown",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 60,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "Sending SOS automatically...",
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),

          const SizedBox(height: 40),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            onPressed: resetState,
            child: const Text(
              "I AM SAFE",
              style: TextStyle(color: Colors.red, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}