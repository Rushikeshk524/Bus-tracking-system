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
  List stops = [];
  List allStops = [];
  final mapController = MapController();

  @override
  void initState() {
    super.initState();
    fetchBuses();
    fetchAllStops();
  }

  Future<void> fetchBuses() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/buses'));
      setState(() {
        buses = jsonDecode(res.body);
      });
    } catch (e) {
      debugPrint('Error fetching buses: $e');
    }
  }

  Future<void> fetchStops(String busId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/stops/$busId'));
      setState(() {
        stops = jsonDecode(res.body);
      });
    } catch (e) {
      debugPrint('Error fetching stops: $e');
    }
  }

  Future<void> fetchAllStops() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/stops'));
      setState(() {
        allStops = jsonDecode(res.body);
      });
    } catch (e) {
      debugPrint('Error fetching all stops: $e');
    }
  }

  void watchBus(Map bus) {
    socket?.disconnect();
    setState(() {
      busLocation = null;
      busOnline = false;
      stops = [];
      notification = '';
    });

    fetchStops(bus['_id'].toString());

    socket = io.io(socketUrl, {
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket!.onConnect((_) {
      socket!.emit('passenger:watch', {'busId': bus['_id']});
    });

    socket!.on('bus:location', (data) {
      final lat = (data['lat'] as num).toDouble();
      final lng = (data['lng'] as num).toDouble();
      final loc = LatLng(lat, lng);
      setState(() {
        busLocation = loc;
        busOnline = true;
      });
      mapController.move(loc, 15);
    });

    socket!.on('bus:offline', (_) {
      setState(() {
        busOnline = false;
      });
    });

    socket!.on('notification', (data) {
      setState(() {
        notification = data['message'].toString();
      });
    });
  }

  @override
  void dispose() {
    socket?.disconnect();
    super.dispose();
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    final stopsToRender = selectedBus == null ? allStops : stops;

    for (final s in stopsToRender) {
      final lat = (s['lat'] as num).toDouble();
      final lng = (s['lng'] as num).toDouble();
      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 120,
          height: 52,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_on,
                color: Color(0xFF1565C0),
                size: 20,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 2),
                  ],
                ),
                child: Text(
                  s['stopName'].toString(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (busLocation != null) {
      markers.add(
        Marker(
          point: busLocation!,
          width: 48,
          height: 48,
          child: const Text('🚌', style: TextStyle(fontSize: 32)),
        ),
      );
    }

    return markers;
  }

  List<Polyline> _buildPolylines() {
    if (stops.isEmpty) return [];
    return [
      Polyline(
        points: stops.map((s) {
          final lat = (s['lat'] as num).toDouble();
          final lng = (s['lng'] as num).toDouble();
          return LatLng(lat, lng);
        }).toList(),
        strokeWidth: 3,
        color: const Color(0xFF1565C0).withOpacity(0.6),
      ),
    ];
  }

  LatLng get _initialCenter {
    if (busLocation != null) return busLocation!;
    final stopsToRender = selectedBus == null ? allStops : stops;
    if (stopsToRender.isNotEmpty) {
      return LatLng(
        (stopsToRender[0]['lat'] as num).toDouble(),
        (stopsToRender[0]['lng'] as num).toDouble(),
      );
    }
    return const LatLng(19.2307, 72.8567);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track My Bus'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF1565C0),
              ),
              child: Text('BusTrack Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Passenger View'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_eta),
              title: const Text('Driver Login'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/driver');
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Moderator Login'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/moderator');
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<Map>(
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
                labelText: 'Select a bus to track',
              ),
              items: buses.map((b) {
                final bus = b as Map;
                return DropdownMenuItem<Map>(
                  value: bus,
                  child: Text('${bus['busNumber']} — ${bus['routeName']}'),
                );
              }).toList(),
              onChanged: (val) {
                if (val == null) return;
                setState(() {
                  selectedBus = val;
                });
                watchBus(val);
              },
            ),
          ),

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
                  Expanded(
                    child: Text(
                      notification,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      setState(() {
                        notification = '';
                      });
                    },
                  ),
                ],
              ),
            ),

          const SizedBox(height: 4),

          Expanded(
            child: selectedBus == null
                ? FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: _initialCenter,
                      initialZoom: 12,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.bustrack.app',
                      ),
                      MarkerLayer(markers: _buildMarkers()),
                    ],
                  )
                : busLocation == null && stops.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              busOnline
                                  ? 'Locating bus...'
                                  : 'Waiting for driver to start trip...',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : FlutterMap(
                        mapController: mapController,
                        options: MapOptions(
                          initialCenter: _initialCenter,
                          initialZoom: 13,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.bustrack.app',
                          ),
                          PolylineLayer(polylines: _buildPolylines()),
                          MarkerLayer(markers: _buildMarkers()),
                        ],
                      ),
          ),

          if (selectedBus != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: busOnline ? const Color(0xFF2E7D32) : Colors.grey,
              child: Text(
                busOnline
                    ? '🟢  Bus is live — tracking active'
                    : '🔴  Bus is offline',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}