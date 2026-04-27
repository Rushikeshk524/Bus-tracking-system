import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';
import 'driver_screen.dart';
import 'moderator_screen.dart';

class LoginScreen extends StatefulWidget {
  final String role; // 'driver' or 'moderator'
  const LoginScreen({super.key, required this.role});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  bool loading = false;
  bool obscure = true;
  String error = '';

  Color get roleColor => widget.role == 'moderator'
      ? const Color(0xFF2E7D32) : const Color(0xFFE65100);

  String get roleLabel => widget.role == 'moderator'
      ? '🛠️  Moderator Login' : '🧑‍✈️  Driver Login';

  Future<void> login() async {
    if (usernameCtrl.text.isEmpty || passwordCtrl.text.isEmpty) {
      setState(() => error = 'Please enter username and password');
      return;
    }
    setState(() { loading = true; error = ''; });

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': usernameCtrl.text.trim(),
          'password': passwordCtrl.text.trim(),
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 401) {
        setState(() { error = 'Invalid username or password'; loading = false; });
        return;
      }

      if (data['role'] != widget.role) {
        setState(() { error = 'Access denied for this role'; loading = false; });
        return;
      }

      // Navigate to correct screen
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => widget.role == 'moderator'
            ? ModeratorScreen(userName: data['name'])
            : DriverScreen(userName: data['name']),
      ));
    } catch (e) {
      setState(() { error = 'Cannot connect to server'; loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: roleColor,
        foregroundColor: Colors.white,
        title: Text(roleLabel),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
          children: [
            const SizedBox(height: 40),
            CircleAvatar(
              radius: 48,
              backgroundColor: roleColor.withOpacity(0.1),
              child: Icon(
                widget.role == 'moderator' ? Icons.admin_panel_settings : Icons.drive_eta,
                size: 48, color: roleColor,
              ),
            ),
            const SizedBox(height: 32),

            // Username
            TextField(
              controller: usernameCtrl,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true, fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Password
            TextField(
              controller: passwordCtrl,
              obscureText: obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => obscure = !obscure),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true, fillColor: Colors.white,
              ),
              onSubmitted: (_) => login(),
            ),
            const SizedBox(height: 12),

            // Error message
            if (error.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(error,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center),
              ),

            const SizedBox(height: 24),

            // Login button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: roleColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: loading
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Login',
                        style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.w600)),
              ),
            ),

            const SizedBox(height: 24),

            // Demo credentials hint
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Demo credentials:',
                      style: TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 6),
                  if (widget.role == 'moderator') ...[
                    _cred('mod1', 'mod123'),
                    _cred('mod2', 'mod456'),
                  ] else ...[
                    _cred('driver1', 'drive123'),
                    _cred('driver2', 'drive456'),
                    _cred('driver3', 'drive789'),
                  ]
                ],
              ),
            ),
          ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cred(String u, String p) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text('$u / $p',
        style: const TextStyle(fontSize: 12,
            fontFamily: 'monospace', color: Colors.grey)),
  );
}