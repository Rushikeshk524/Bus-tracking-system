import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'dart:convert';
import '../config.dart';

class PassengerScreen extends StatefulWidget {
  const PassengerScreen({super.key});

  @override
  State<PassengerScreen> createState() => _PassengerScreenState();
}

class _PassengerScreenState extends State<PassengerScreen> {
  List buses = [];
  Map? selectedBus;
  io.Socket? socket;
  LatLng? busLocation;
  bool busOnline = false;
  String notification = '';
  final mapController = MapController();

  @override
  void initState() {
    super.initState();
    fetchBuses();
  }

  Future<void> fetchBuses() async {
    final res = await http.get(Uri.parse('$baseUrl/buses'));
    setState(() => buses = jsonDecode(res.body));
  }

  void watchBus(Map bus) {
    socket?.disconnect();
    socket = io.io(socketUrl, {
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket!.onConnect((_) {
      socket!.emit('passenger:watch', {'busId': bus['_id']});
    });

    socket!.on('bus:location', (data) {
      final loc = LatLng(data['lat'], data['lng']);
      setState(() {
        busLocation = loc;
        busOnline = true;
      });
      mapController.move(loc, 15);
    });

    socket!.on('bus:offline', (_) {
      setState(() => busOnline = false);
    });

    socket!.on('notification', (data) {
      setState(() => notification = data['message']);
    });
  }

  @override
  void dispose() {
    socket?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track My Bus'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Bus selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
                labelText: 'Select a bus to track',
              ),
              items: buses.map((b) => DropdownMenuItem(
                value: b,
                child: Text('${b['busNumber']} — ${b['routeName']}'),
              )).toList(),
              onChanged: (val) {
              final bus = val as Map;
              setState(() {
              selectedBus = bus;
              busLocation = null;
              busOnline = false;
              notification = '';
              });
              watchBus(bus);
              },
            ),
          ),

          // Notification banner
          if (notification.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE65100)),
              ),
              child: Row(
                children: [
                  const Text('📢 ', style: TextStyle(fontSize: 18)),
                  Expanded(child: Text(notification,
                      style: const TextStyle(fontWeight: FontWeight.w500))),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => notification = ''),
                  )
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Map
          Expanded(
            child: selectedBus == null
                ? const Center(child: Text('Select a bus to see its location',
                style: TextStyle(color: Colors.grey)))
                : busLocation == null
                ? Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(busOnline
                      ? 'Locating bus...'
                      : 'Waiting for driver to start trip...',
                      style: const TextStyle(color: Colors.grey)),
                ]))
                : FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: busLocation!,
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.bustrack.app',
                ),
                MarkerLayer(markers: [
                  Marker(
                    point: busLocation!,
                    width: 48,
                    height: 48,
                    child: const Text('🚍',
                        style: TextStyle(fontSize: 32)),
                  )
                ]),
              ],
            ),
          ),

          // Status bar
          if (selectedBus != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: busOnline
                  ? const Color(0xFF2E7D32) : Colors.grey,
              child: Text(
                busOnline
                    ? '🟢  Bus is live — tracking active'
                    : '🔴  Bus is offline',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}