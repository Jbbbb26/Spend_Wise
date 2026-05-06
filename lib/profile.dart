import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SpendWiseProfileScreen extends StatelessWidget {
  const SpendWiseProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint("Logout Error: $e");
    }
    // StreamBuilder in main.dart will automatically redirect to login
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String displayName = user?.displayName ?? "User Name";
    final Color primaryDarkGreen = const Color(0xFF0F3826);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: primaryDarkGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.account_balance, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Text('SpendWise',
                          style: TextStyle(fontWeight: FontWeight.bold, color: primaryDarkGreen, fontSize: 18)),
                    ],
                  ),
                  const Icon(Icons.settings_outlined),
                ],
              ),
              const SizedBox(height: 30),

              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/profile.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: primaryDarkGreen, shape: BoxShape.circle),
                    child: const Icon(Icons.edit, color: Colors.white, size: 14),
                  )
                ],
              ),
              const SizedBox(height: 16),

              Text(displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Text("Premium Member • Joined June 2023",
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 30),

              _buildStatsCard("TOTAL WEALTH MANAGED", "\$142,500.00",
                  "+12.4% this year", Colors.white, Colors.black),
              const SizedBox(height: 16),

              _buildStatsCard("SAVINGS GOAL", "84%", "", primaryDarkGreen, Colors.white,
                  isProgress: true),

              const SizedBox(height: 30),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("ACCOUNT SETTINGS",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              const SizedBox(height: 10),

              _buildSettingsItem(Icons.person_outline, "Personal Information",
                  "Update your name, email, and address"),
              _buildSettingsItem(Icons.account_balance_outlined, "Linked Bank Accounts",
                  "Manage 3 connected institutions"),
              _buildSettingsItem(Icons.notifications_none, "Notifications",
                  "Alerts, summaries and marketing"),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _handleLogout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text("Log Out"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFE0E0),
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text("SPENDWISE V2.4.1 (STABLE BUILD)",
                  style: TextStyle(fontSize: 10, color: Colors.grey)),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(String label, String value, String sub, Color bg, Color textCol,
      {bool isProgress = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 10, color: textCol.withOpacity(0.7), fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textCol)),
          const SizedBox(height: 8),
          if (isProgress)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                  value: 0.84, minHeight: 8, color: Colors.greenAccent, backgroundColor: Colors.white24),
            )
          else
            Text(sub, style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, String sub) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 20, color: Colors.black87)),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right, size: 18),
    );
  }
}