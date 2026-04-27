import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class ModeratorScreen extends StatefulWidget {
  final String userName;
  const ModeratorScreen({super.key, required this.userName});

  @override
  State<ModeratorScreen> createState() => _ModeratorScreenState();
}

class _ModeratorScreenState extends State<ModeratorScreen> {
  List buses = [];
  Future<void> _deleteBus(String busId) async {
  await http.delete(Uri.parse('$baseUrl/buses/$busId'));
  fetchBuses();
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Bus removed successfully'),
      backgroundColor: Colors.red,
    ),
  );
}

void _confirmDelete(BuildContext context, Map bus) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Cancel Bus?'),
      content: Text(
          'Remove ${bus['busNumber']} — ${bus['routeName']}?\n\nThis cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Keep', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            _deleteBus(bus['_id']);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Yes, Cancel Bus'),
        ),
      ],
    ),
  );
}
  // Controllers for Add Bus
  final busNumberCtrl = TextEditingController();
  final routeNameCtrl = TextEditingController();
  final driverNameCtrl = TextEditingController();

  // Notification
  Map? notifyBus;
  final messageCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchBuses();
  }

  Future<void> fetchBuses() async {
    final res = await http.get(Uri.parse('$baseUrl/buses'));
    setState(() => buses = jsonDecode(res.body));
  }

  Future<void> addBus() async {
    if (busNumberCtrl.text.isEmpty || routeNameCtrl.text.isEmpty) return;
    await http.post(Uri.parse('$baseUrl/buses'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'busNumber': busNumberCtrl.text.trim(),
          'routeName': routeNameCtrl.text.trim(),
          'driverName': driverNameCtrl.text.trim(),
        }));
    busNumberCtrl.clear();
    routeNameCtrl.clear();
    driverNameCtrl.clear();
    fetchBuses();
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bus added successfully!')));
  }

  Future<void> sendNotification() async {
    if (notifyBus == null || messageCtrl.text.isEmpty) return;
    await http.post(Uri.parse('$baseUrl/notify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'busId': notifyBus!['_id'],
          'message': messageCtrl.text.trim(),
        }));
    messageCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification sent!')));
  }

  @override
Widget build(BuildContext context) {
  return DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: AppBar(
        title: Text('Moderator - ${widget.userName}'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        bottom: const TabBar(
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          tabs: [
            Tab(icon: Icon(Icons.directions_bus), text: 'Buses'),
            Tab(icon: Icon(Icons.add_box), text: 'Add Bus'),
            Tab(icon: Icon(Icons.notifications), text: 'Notify'),
          ],
        ),
      ),
      body: TabBarView(
        children: [_busListTab(), _addBusTab(), _notifyTab()],
      ),
    ),
  );
}

  Widget _busListTab() {
  return RefreshIndicator(
    onRefresh: fetchBuses,
    child: buses.isEmpty
        ? const Center(
            child: Text('No buses added yet.\nGo to Add Bus tab.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: buses.length,
            itemBuilder: (_, i) {
              final b = buses[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: b['isActive'] == true
                        ? const Color(0xFF2E7D32) : Colors.grey,
                    child: const Icon(Icons.directions_bus,
                        color: Colors.white),
                  ),
                  title: Text(b['busNumber'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Route: ${b['routeName']}'),
                      if (b['driverName'] != null && b['driverName'] != '')
                        Text('Driver: ${b['driverName']}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        label: Text(
                          b['isActive'] == true ? 'Live' : 'Offline',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                        backgroundColor: b['isActive'] == true
                            ? const Color(0xFF2E7D32) : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        onPressed: () => _confirmDelete(context, b),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
  );
}
  Widget _addBusTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add a New Bus',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _field(busNumberCtrl, 'Bus Number', 'e.g. MH-04-BT-001',
              Icons.confirmation_number),
          const SizedBox(height: 16),
          _field(routeNameCtrl, 'Route Name', 'e.g. Virar → Churchgate',
              Icons.route),
          const SizedBox(height: 16),
          _field(driverNameCtrl, 'Driver Name', 'e.g. Ramesh Kumar',
              Icons.person),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: addBus,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add Bus',
                  style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ),
          )
        ],
      ),
    );
  }

  Widget _notifyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Send Notification',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          DropdownButtonFormField(
            decoration: InputDecoration(
              labelText: 'Select Bus',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              filled: true, fillColor: Colors.white,
            ),
            items: buses.map((b) => DropdownMenuItem(
              value: b,
              child: Text('${b['busNumber']} — ${b['routeName']}'),
            )).toList(),
            onChanged: (val) => setState(() => notifyBus = val as Map),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: messageCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Message',
              hintText: 'e.g. Bus MH-04 delayed by 15 minutes',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
              filled: true, fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: sendNotification,
              icon: const Icon(Icons.send),
              label: const Text('Send to Passengers',
                  style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true, fillColor: Colors.white,
      ),
    );
  }
}