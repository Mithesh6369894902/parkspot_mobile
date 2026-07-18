import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: auth.isLoggedIn
        ? ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(child: CircleAvatar(
                radius: 40, backgroundColor: const Color(0xFFE0F2F1),
                child: Text(auth.user!.name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
              )),
              const SizedBox(height: 16),
              Center(child: Text(auth.user!.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
              Center(child: Text(auth.user!.role[0].toUpperCase() + auth.user!.role.substring(1),
                style: const TextStyle(color: Colors.grey))),
              const SizedBox(height: 32),
              _infoTile(Icons.person_outline, 'Name', auth.user!.name),
              _infoTile(Icons.email_outlined, 'Email', auth.user!.email),
              _infoTile(Icons.phone_outlined, 'Phone', auth.user!.phone),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity, height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    auth.logout();
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                  },
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        : Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.person_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Please login to view profile', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white),
                child: const Text('Login'),
              ),
            ]),
          ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: const Color(0xFF059669)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }
}
