import 'package:flutter/material.dart';
import 'home_screen.dart';

void main() {
  runApp(const SmartRoadSOS());
}

class SmartRoadSOS extends StatelessWidget {
  const SmartRoadSOS({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Smart RoadSoS",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.red),
      home: const HomeScreen(),
    );
  }
}