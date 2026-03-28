import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:async';
import 'dart:convert';
import '../config.dart';

class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  List buses = [];
  Map? selectedBus;
  bool isTripActive = false;
  io.Socket? socket;
  Timer? locationTimer;
  String statusText = 'Select a bus to start';
  double? currentLat, currentLng, currentSpeed;

  @override
  void initState() {
    super.initState();
    fetchBuses();
  }

  Future<void> fetchBuses() async {
    final res = await http.get(Uri.parse('$baseUrl/buses'));
    setState(() => buses = jsonDecode(res.body));
  }

  void connectSocket() {
    socket = io.io(socketUrl, {
      'transports': ['websocket'],
      'autoConnect': true,
    });
    socket!.onConnect((_) {
      socket!.emit('driver:join', {'busId': selectedBus!['_id']});
    });
  }

  Future<void> startTrip() async {
    LocationPermission perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied) return;

    connectSocket();
    setState(() {
      isTripActive = true;
      statusText = 'Trip active — broadcasting location';
    });

    locationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        currentLat = pos.latitude;
        currentLng = pos.longitude;
        currentSpeed = pos.speed;
      });
      socket!.emit('driver:location', {
        'busId': selectedBus!['_id'],
        'lat': pos.latitude,
        'lng': pos.longitude,
        'speed': pos.speed,
      });
    });
  }

  void endTrip() {
    locationTimer?.cancel();
    socket?.emit('driver:stop', {'busId': selectedBus!['_id']});
    socket?.disconnect();
    setState(() {
      isTripActive = false;
      statusText = 'Trip ended';
      currentLat = null;
      currentLng = null;
    });
  }

  @override
  void dispose() {
    locationTimer?.cancel();
    socket?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: const Text('Driver Panel'),
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select your bus',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true, fillColor: Colors.white,
              ),
              hint: const Text('Choose bus'),
              items: buses.map((b) => DropdownMenuItem(
                value: b,
                child: Text('${b['busNumber']} — ${b['routeName']}'),
              )).toList(),
              onChanged: isTripActive ? null : (val) =>
                  setState(() => selectedBus = val as Map),
            ),
            const SizedBox(height: 32),

            // Status card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isTripActive
                    ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isTripActive
                      ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                ),
              ),
              child: Column(
                children: [
                  Icon(isTripActive ? Icons.directions_bus : Icons.bus_alert,
                      size: 48,
                      color: isTripActive
                          ? const Color(0xFF2E7D32) : const Color(0xFFE65100)),
                  const SizedBox(height: 12),
                  Text(statusText,
                      style: const TextStyle(fontSize: 16,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center),
                  if (currentLat != null) ...[
                    const SizedBox(height: 12),
                    Text('📍 ${currentLat!.toStringAsFixed(5)}, '
                        '${currentLng!.toStringAsFixed(5)}',
                        style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    Text('🚀 Speed: ${(currentSpeed! * 3.6).toStringAsFixed(1)} km/h',
                        style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  ]
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedBus == null
                    ? null
                    : isTripActive ? endTrip : startTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isTripActive
                      ? Colors.red : const Color(0xFFE65100),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  isTripActive ? '🛑  End Trip' : '🚀  Start Trip',
                  style: const TextStyle(fontSize: 18,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}