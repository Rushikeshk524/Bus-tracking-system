import 'screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'screens/passenger_screen.dart';

void main() => runApp(const BusTrackApp());

class BusTrackApp extends StatelessWidget {
  const BusTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BusTrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE65100)),
        useMaterial3: true,
      ),
      home: const RoleSelectScreen(),
    );
  }
}

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🚌', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              const Text('BusTrack',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold,
                      color: Color(0xFFE65100))),
              const SizedBox(height: 8),
              const Text('Select your role to continue',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 48),
              _RoleButton(
                label: '🧑‍✈️  I am a Driver',
                color: const Color(0xFFE65100),
                onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const LoginScreen(role: 'driver'))),
              ),
              const SizedBox(height: 16),
              _RoleButton(
                label: '🧍 I am a Passenger',
                color: const Color(0xFF1565C0),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PassengerScreen())),
              ),
              const SizedBox(height: 16),
              _RoleButton(
                label: '🛠️  I am a Moderator',
                color: const Color(0xFF2E7D32),
               onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const LoginScreen(role: 'moderator'))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _RoleButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 3,
        ),
        child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
    );
  }
}