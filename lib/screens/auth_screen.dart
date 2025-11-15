// Modified: 2025-11-15 06:45:00
// lib/screens/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController();
  final pass  = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> signIn() async {
    setState(() { loading = true; error = null; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email.text.trim(),
        password: pass.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const Placeholder()),
      );
      }
    } catch (e) {
      setState(() { error = e.toString(); });
    } finally { setState(() { loading = false; }); }
  }

  Future<void> signUp() async {
    setState(() { loading = true; error = null; });
    try {
      await Supabase.instance.client.auth.signUp(
        email: email.text.trim(),
        password: pass.text.trim(),
      );
    } catch (e) {
      setState(() { error = e.toString(); });
    } finally { setState(() { loading = false; }); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pentapol — Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: pass, decoration: const InputDecoration(labelText: 'Mot de passe'), obscureText: true),
          const SizedBox(height: 12),
          if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          FilledButton(onPressed: loading ? null : signIn, child: const Text('Se connecter')),
          TextButton(onPressed: loading ? null : signUp, child: const Text('Créer un compte')),
        ]),
      ),
    );
  }
}
