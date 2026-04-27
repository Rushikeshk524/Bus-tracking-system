import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import '../config.dart';

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  List buses = [];
  Map? selectedBus;
  List stops = [];
  io.Socket? socket;
  Timer? simTimer;
  int currentStopIndex = 0;
  bool isRunning = false;
  LatLng? currentPos;
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

  Future<void> fetchStops(String busId) async {
    final res = await http.get(Uri.parse('$baseUrl/stops/$busId'));
    setState(() {
      stops = jsonDecode(res.body);
      currentStopIndex = 0;
      currentPos = stops.isNotEmpty
          ? LatLng(stops[0]['lat'], stops[0]['lng']) : null;
    });
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

  void startSimulation() {
    if (stops.isEmpty || selectedBus == null) return;
    connectSocket();
    setState(() { isRunning = true; currentStopIndex = 0; });

    simTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (currentStopIndex >= stops.length) {
        stopSimulation();
        return;
      }

      final stop = stops[currentStopIndex];
      final lat = stop['lat'] as num;
      final lng = stop['lng'] as num;
      final pos = LatLng(lat.toDouble(), lng.toDouble());

      setState(() { currentPos = pos; });
      mapController.move(pos, 13);

      socket!.emit('driver:location', {
        'busId': selectedBus!['_id'],
        'lat': lat,
        'lng': lng,
        'speed': 40.0,
      });

      setState(() => currentStopIndex++);
    });
  }

  void stopSimulation() {
    simTimer?.cancel();
    socket?.emit('driver:stop', {'busId': selectedBus!['_id']});
    socket?.disconnect();
    setState(() { isRunning = false; });
  }

  @override
  void dispose() {
    simTimer?.cancel();
    socket?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GPS Simulator'),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                DropdownButtonFormField(
                  decoration: InputDecoration(
                    labelText: 'Select bus to simulate',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true, fillColor: Colors.white,
                  ),
                  items: buses.map((b) => DropdownMenuItem(
                    value: b,
                    child: Text('${b['busNumber']} — ${b['routeName']}'),
                  )).toList(),
                  onChanged: isRunning ? null : (val) {
                    setState(() => selectedBus = val as Map);
                    fetchStops((val as Map)['_id']);
                  },
                ),
                const SizedBox(height: 12),

                // Progress indicator
                if (stops.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: Color(0xFF6A1B9A)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          currentStopIndex < stops.length
                              ? 'Next: ${stops[currentStopIndex]['stopName']}'
                              : 'Trip complete',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        )),
                        Text('${currentStopIndex}/${stops.length} stops',
                            style: const TextStyle(color: Colors.grey,
                                fontSize: 12)),
                      ],
                    ),
                  ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: selectedBus == null || stops.isEmpty
                        ? null
                        : isRunning ? stopSimulation : startSimulation,
                    icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
                    label: Text(isRunning
                        ? 'Stop Simulation' : 'Start Simulation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRunning
                          ? Colors.red : const Color(0xFF6A1B9A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: currentPos == null
                ? const Center(child: Text('Select a bus to see the route',
                style: TextStyle(color: Colors.grey)))
                : FlutterMap(
              mapController: mapController,
              options: MapOptions(
                  initialCenter: currentPos!, initialZoom: 12),
              children: [
                TileLayer(
                  urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.bustrack.app',
                ),
                if (stops.isNotEmpty)
                  PolylineLayer(polylines: [
                    Polyline(
                      points: stops.map((s) =>
                          LatLng((s['lat'] as num).toDouble(),
                              (s['lng'] as num).toDouble())).toList(),
                      strokeWidth: 4,
                      color: const Color(0xFF6A1B9A).withOpacity(0.5),
                    ),
                  ]),
                MarkerLayer(markers: [
                  ...stops.asMap().entries.map((e) => Marker(
                    point: LatLng(
                        (e.value['lat'] as num).toDouble(),
                        (e.value['lng'] as num).toDouble()),
                    width: 24, height: 24,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: e.key < currentStopIndex
                          ? Colors.green
                          : e.key == currentStopIndex
                          ? const Color(0xFF6A1B9A)
                          : Colors.grey.shade300,
                      child: Text('${e.key + 1}',
                          style: const TextStyle(fontSize: 8,
                              color: Colors.white)),
                    ),
                  )),
                  if (currentPos != null)
                    Marker(
                      point: currentPos!,
                      width: 48, height: 48,
                      child: const Text('🚌',
                          style: TextStyle(fontSize: 32)),
                    ),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}