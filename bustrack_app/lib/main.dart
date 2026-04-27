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
      initialRoute: '/',
      routes: {
        '/': (context) => const PassengerScreen(),
        '/driver': (context) => const LoginScreen(role: 'driver'),
        '/moderator': (context) => const LoginScreen(role: 'moderator'),
      },
    );
  }
}