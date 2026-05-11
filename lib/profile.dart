import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SpendWiseProfileScreen extends StatefulWidget {
  const SpendWiseProfileScreen({super.key});

  @override
  State<SpendWiseProfileScreen> createState() => _SpendWiseProfileScreenState();
}

class _SpendWiseProfileScreenState extends State<SpendWiseProfileScreen> {
  final Color primaryGreen = const Color(0xFF0F3826);

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      debugPrint("Logout Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in.')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                  child: CircularProgressIndicator(color: primaryGreen));
            }

            final data =
                snapshot.data?.data() as Map<String, dynamic>? ?? {};

            // ── Pull live values from Firestore ──────────────────────
            final String firstName = data['first_name'] as String? ?? '';
            final String lastName = data['last_name'] as String? ?? '';
            final String fullName = (firstName.isNotEmpty || lastName.isNotEmpty)
                ? '${firstName.trim()} ${lastName.trim()}'.trim()
                : (data['name'] as String? ?? user.displayName ?? 'User');
            final String email =
                data['email'] as String? ?? user.email ?? '';
            final String phone = data['phone'] as String? ?? '';
            final String address = data['address'] as String? ?? '';
            final String joinedDate =
                data['joined_date'] as String? ?? 'June 2023';
            final String memberType =
                data['member_type'] as String? ?? 'Premium Member';

            final double monthlyIncome =
                (data['monthly_income'] as num?)?.toDouble() ?? 0.0;
            final double monthlySpent =
                (data['monthly_spent'] as num?)?.toDouble() ?? 0.0;

            // Savings goal = % of income NOT spent
            final double savingsPct = monthlyIncome > 0
                ? ((monthlyIncome - monthlySpent) / monthlyIncome)
                    .clamp(0.0, 1.0)
                : 0.0;
            final int savingsPctInt = (savingsPct * 100).round();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // ── Header ─────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: primaryGreen,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.account_balance,
                                  color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 8),
                            Text('SpendWise',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primaryGreen,
                                    fontSize: 18)),
                          ],
                        ),
                      ),
                      const Icon(Icons.settings_outlined),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // ── Avatar ─────────────────────────────────────────
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
                            image:
                                AssetImage('assets/images/profile.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            color: primaryGreen, shape: BoxShape.circle),
                        child: const Icon(Icons.edit,
                            color: Colors.white, size: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(fullName,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(
                    '$memberType • Joined $joinedDate',
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 30),

                  // ── Total Wealth (sum of ALL income transactions) ──
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('transactions')
                        .where('type', isEqualTo: 'income')
                        .snapshots(),
                    builder: (context, txSnap) {
                      double totalIncome = 0.0;
                      if (txSnap.hasData) {
                        for (final doc in txSnap.data!.docs) {
                          final d = doc.data() as Map<String, dynamic>;
                          totalIncome +=
                              (d['amount'] as num?)?.toDouble() ?? 0.0;
                        }
                      }
                      final int txCount = txSnap.data?.docs.length ?? 0;
                      return _buildStatsCard(
                        label: 'TOTAL WEALTH MANAGED',
                        value: '\$${totalIncome.toStringAsFixed(2)}',
                        sub: txCount > 0
                            ? '$txCount income transaction${txCount == 1 ? '' : 's'} recorded'
                            : 'No income recorded yet',
                        bg: Colors.white,
                        textCol: Colors.black,
                        subColor: const Color(0xFF0C7A43),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Savings Goal (live %) ──────────────────────────
                  _buildSavingsCard(
                    primaryGreen: primaryGreen,
                    savingsPct: savingsPct,
                    savingsPctInt: savingsPctInt,
                    monthlyIncome: monthlyIncome,
                    monthlySpent: monthlySpent,
                  ),
                  const SizedBox(height: 30),

                  // ── Account Settings ───────────────────────────────
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('ACCOUNT SETTINGS',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey)),
                  ),
                  const SizedBox(height: 10),

                  // Personal Information — tappable, opens edit sheet
                  _buildSettingsItem(
                    icon: Icons.person_outline,
                    title: 'Personal Information',
                    sub: 'Update your name, email, phone and address',
                    onTap: () => _openPersonalInfoSheet(
                      context,
                      uid: user.uid,
                      primaryGreen: primaryGreen,
                      currentFirstName: firstName,
                      currentLastName: lastName,
                      currentEmail: email,
                      currentPhone: phone,
                      currentAddress: address,
                    ),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('linked_accounts')
                        .snapshots(),
                    builder: (context, accSnap) {
                      final int count = accSnap.data?.docs.length ?? 0;
                      return _buildSettingsItem(
                        icon: Icons.account_balance_outlined,
                        title: 'Linked Bank Accounts',
                        sub: count == 0
                            ? 'Add your banks, e-wallets & cards'
                            : '$count account${count == 1 ? '' : 's'} connected',
                        onTap: () => _openLinkedAccountsScreen(
                            context, user.uid),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    icon: Icons.notifications_none,
                    title: 'Notifications',
                    sub: 'Alerts, summaries and marketing',
                    onTap: () {},
                  ),

                  const SizedBox(height: 30),

                  // ── Logout ─────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleLogout(context),
                      icon: const Icon(Icons.logout),
                      label: const Text('Log Out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFE0E0),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('SPENDWISE V2.4.1 (STABLE BUILD)',
                      style: TextStyle(fontSize: 10, color: Colors.grey)),
                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Personal Info Bottom Sheet ──────────────────────────────────────────
  void _openPersonalInfoSheet(
    BuildContext context, {
    required String uid,
    required Color primaryGreen,
    required String currentFirstName,
    required String currentLastName,
    required String currentEmail,
    required String currentPhone,
    required String currentAddress,
  }) {
    final firstNameCtrl =
        TextEditingController(text: currentFirstName);
    final lastNameCtrl =
        TextEditingController(text: currentLastName);
    final emailCtrl = TextEditingController(text: currentEmail);
    final phoneCtrl = TextEditingController(text: currentPhone);
    final addressCtrl = TextEditingController(text: currentAddress);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Personal Information',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: primaryGreen)),
                      GestureDetector(
                        onTap: () => Navigator.pop(sheetCtx),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle),
                          child: Icon(Icons.close,
                              size: 18, color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // First + Last name row
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          label: 'First Name',
                          controller: firstNameCtrl,
                          hint: 'Jane',
                          primaryGreen: primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildField(
                          label: 'Last Name',
                          controller: lastNameCtrl,
                          hint: 'Doe',
                          primaryGreen: primaryGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _buildField(
                    label: 'Email Address',
                    controller: emailCtrl,
                    hint: 'you@example.com',
                    primaryGreen: primaryGreen,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),

                  _buildField(
                    label: 'Phone Number',
                    controller: phoneCtrl,
                    hint: '+1 (555) 000-0000',
                    primaryGreen: primaryGreen,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),

                  _buildField(
                    label: 'Address',
                    controller: addressCtrl,
                    hint: '123 Main St, City, Country',
                    primaryGreen: primaryGreen,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              setSheet(() => isSaving = true);
                              try {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(uid)
                                    .update({
                                  'first_name':
                                      firstNameCtrl.text.trim(),
                                  'last_name':
                                      lastNameCtrl.text.trim(),
                                  'name':
                                      '${firstNameCtrl.text.trim()} ${lastNameCtrl.text.trim()}'
                                          .trim(),
                                  'email': emailCtrl.text.trim(),
                                  'phone': phoneCtrl.text.trim(),
                                  'address': addressCtrl.text.trim(),
                                });
                                if (sheetCtx.mounted) {
                                  Navigator.pop(sheetCtx);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: const Text(
                                        '✓ Profile updated successfully'),
                                    backgroundColor: primaryGreen,
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                }
                              } catch (e) {
                                setSheet(() => isSaving = false);
                                if (sheetCtx.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                        'Failed to save: ${e.toString()}'),
                                    backgroundColor:
                                        Colors.red.shade400,
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Reusable text field ───────────────────────────────────────────────────
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required Color primaryGreen,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: const Color(0xFFF4F6F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: primaryGreen.withOpacity(0.5), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  // ── Stats card (balance) ──────────────────────────────────────────────────
  Widget _buildStatsCard({
    required String label,
    required String value,
    required String sub,
    required Color bg,
    required Color textCol,
    Color subColor = Colors.green,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: textCol.withOpacity(0.6),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textCol)),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(sub,
                style: TextStyle(
                    color: subColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ],
        ],
      ),
    );
  }

  // ── Savings goal card (live %) ────────────────────────────────────────────
  Widget _buildSavingsCard({
    required Color primaryGreen,
    required double savingsPct,
    required int savingsPctInt,
    required double monthlyIncome,
    required double monthlySpent,
  }) {
    final double saved = monthlyIncome - monthlySpent;
    final bool isPositive = saved >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: primaryGreen, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SAVINGS THIS MONTH',
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.white60,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$savingsPctInt%',
                  style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isPositive
                        ? '+\$${saved.toStringAsFixed(2)} saved'
                        : '-\$${saved.abs().toStringAsFixed(2)} over',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isPositive
                            ? Colors.greenAccent.shade200
                            : Colors.red.shade300),
                  ),
                  Text('of \$${monthlyIncome.toStringAsFixed(0)} income',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.white54)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: savingsPct,
              minHeight: 8,
              color: Colors.greenAccent,
              backgroundColor: Colors.white24,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isPositive
                ? 'You saved $savingsPctInt% of your income this month 🎉'
                : 'Spending exceeded income this month',
            style: TextStyle(
                fontSize: 11,
                color: isPositive
                    ? Colors.white60
                    : Colors.red.shade300),
          ),
        ],
      ),
    );
  }

  // ── Linked Accounts — full screen ────────────────────────────────────────
  void _openLinkedAccountsScreen(BuildContext context, String uid) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _LinkedAccountsScreen(uid: uid, primaryGreen: primaryGreen),
      ),
    );
  }

  // ── Settings row ─────────────────────────────────────────────────────────
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String sub,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 20, color: Colors.black87)),
      title:
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle:
          Text(sub, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right, size: 18),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Linked Accounts Screen
// ══════════════════════════════════════════════════════════════════════════════

class _LinkedAccountsScreen extends StatefulWidget {
  final String uid;
  final Color primaryGreen;

  const _LinkedAccountsScreen({
    required this.uid,
    required this.primaryGreen,
  });

  @override
  State<_LinkedAccountsScreen> createState() => _LinkedAccountsScreenState();
}

class _LinkedAccountsScreenState extends State<_LinkedAccountsScreen> {
  Color get _green => widget.primaryGreen;
  final Color _bg = const Color(0xFFF4F6F8);

  CollectionReference get _accountsRef => FirebaseFirestore.instance
      .collection('users')
      .doc(widget.uid)
      .collection('linked_accounts');

  static const List<Map<String, dynamic>> _accountTypes = [
    {
      'type': 'Local Bank',
      'icon': Icons.account_balance,
      'color': Color(0xFF0F3826),
      'bgColor': Color(0xFFC8F6E0),
      'examples': ['BDO', 'BPI', 'Metrobank', 'UnionBank', 'PNB', 'Landbank', 'Security Bank', 'Other'],
    },
    {
      'type': 'E-Wallet',
      'icon': Icons.account_balance_wallet,
      'color': Color(0xFF1565C0),
      'bgColor': Color(0xFFE3F2FD),
      'examples': ['GCash', 'Maya', 'ShopeePay', 'GrabPay', 'Coins.ph', 'Other'],
    },
    {
      'type': 'Credit Card',
      'icon': Icons.credit_card,
      'color': Color(0xFF6A1B9A),
      'bgColor': Color(0xFFF3E5F5),
      'examples': ['Visa', 'Mastercard', 'BDO Credit Card', 'BPI Credit Card', 'Metrobank Card', 'Other'],
    },
    {
      'type': 'International Bank',
      'icon': Icons.language,
      'color': Color(0xFFBF360C),
      'bgColor': Color(0xFFFBE9E7),
      'examples': ['PayPal', 'Wise', 'Citibank', 'HSBC', 'Standard Chartered', 'Other'],
    },
  ];

  void _confirmDelete(String docId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Account',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        content: Text(
          'Remove "$name" from your linked accounts? This won\'t affect your transactions.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade500)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _accountsRef.doc(docId).delete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showTypePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Add Account',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: _green)),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('What type of account would you like to add?',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.4,
              physics: const NeverScrollableScrollPhysics(),
              children: _accountTypes.map((t) {
                final Color color = t['color'] as Color;
                final Color bgColor = t['bgColor'] as Color;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    _showAccountForm(t);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Icon(t['icon'] as IconData, color: color, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t['type'] as String,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: color),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountForm(Map<String, dynamic> typeInfo) {
    final String accountType = typeInfo['type'] as String;
    final List<String> examples = List<String>.from(typeInfo['examples'] as List);
    final Color color = typeInfo['color'] as Color;
    final Color bgColor = typeInfo['bgColor'] as Color;

    String? selectedProvider;
    final accountNameCtrl = TextEditingController();
    final accountNumberCtrl = TextEditingController();
    final balanceCtrl = TextEditingController();
    bool isSaving = false;
    bool isCustomName = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(typeInfo['icon'] as IconData, color: color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Add $accountType',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 17,
                                    color: _green)),
                            Text('Fill in your account details',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade100, shape: BoxShape.circle),
                          child: Icon(Icons.close, size: 18, color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Provider chips
                  Text('Select Provider',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: examples.map((e) {
                      final bool isOther = e == 'Other';
                      final bool selected = selectedProvider == e;
                      return GestureDetector(
                        onTap: () {
                          setSheet(() {
                            selectedProvider = e;
                            isCustomName = isOther;
                            if (!isOther) accountNameCtrl.text = e;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? color : bgColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected ? color : color.withOpacity(0.2),
                            ),
                          ),
                          child: Text(e,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: selected ? Colors.white : color)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  if (isCustomName) ...[
                    _formField(
                      label: 'Account / Institution Name',
                      controller: accountNameCtrl,
                      hint: 'e.g. My Credit Union',
                      accentColor: color,
                    ),
                    const SizedBox(height: 14),
                  ],

                  _formField(
                    label: 'Account Number (last 4 digits)',
                    controller: accountNumberCtrl,
                    hint: 'e.g. 1234',
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    accentColor: color,
                  ),
                  const SizedBox(height: 14),

                  _formField(
                    label: 'Current Balance',
                    controller: balanceCtrl,
                    hint: 'e.g. 5000.00',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixText: '\$ ',
                    accentColor: color,
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (selectedProvider == null) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: const Text('Please select a provider'),
                                  backgroundColor: Colors.orange.shade400,
                                  behavior: SnackBarBehavior.floating,
                                ));
                                return;
                              }
                              final String name = isCustomName
                                  ? accountNameCtrl.text.trim()
                                  : (selectedProvider ?? '');
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: const Text('Please enter an account name'),
                                  backgroundColor: Colors.orange.shade400,
                                  behavior: SnackBarBehavior.floating,
                                ));
                                return;
                              }
                              final double? balance =
                                  double.tryParse(balanceCtrl.text.trim());
                              setSheet(() => isSaving = true);
                              try {
                                await _accountsRef.add({
                                  'name': name,
                                  'type': accountType,
                                  'account_number': accountNumberCtrl.text.trim(),
                                  'balance': balance ?? 0.0,
                                  'createdAt': FieldValue.serverTimestamp(),
                                });
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('✓ "$name" added successfully'),
                                    backgroundColor: _green,
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                }
                              } catch (e) {
                                setSheet(() => isSaving = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text('Failed to save: $e'),
                                    backgroundColor: Colors.red.shade400,
                                    behavior: SnackBarBehavior.floating,
                                  ));
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Link Account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required Color accentColor,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixText: prefixText,
            counterText: '',
            filled: true,
            fillColor: const Color(0xFFF4F6F8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: accentColor.withOpacity(0.5), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16, color: _green),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LINKED ACCOUNTS',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                color: _green,
                                letterSpacing: 1.2)),
                        Text('Manage your banks, wallets & cards',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _showTypePicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 15),
                          SizedBox(width: 4),
                          Text('Add New',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Account list ─────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _accountsRef
                    .orderBy('createdAt', descending: false)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return Center(
                        child: CircularProgressIndicator(color: _green));
                  }

                  final docs = snap.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.account_balance_outlined,
                              size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('No accounts linked yet',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.grey.shade400)),
                          const SizedBox(height: 6),
                          Text('Tap "+ Add New" to link your first account',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade400)),
                        ],
                      ),
                    );
                  }

                  // Group by type
                  final Map<String, List<QueryDocumentSnapshot>> grouped = {};
                  for (final doc in docs) {
                    final d = doc.data() as Map<String, dynamic>;
                    final String type = d['type'] as String? ?? 'Other';
                    grouped.putIfAbsent(type, () => []).add(doc);
                  }

                  // Total balance across all accounts
                  double grandTotal = 0;
                  for (final doc in docs) {
                    final d = doc.data() as Map<String, dynamic>;
                    grandTotal += (d['balance'] as num?)?.toDouble() ?? 0.0;
                  }

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    children: [
                      // Total summary card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: _green,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TOTAL ACROSS ALL ACCOUNTS',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white60,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5)),
                            const SizedBox(height: 8),
                            Text(
                              '\$${grandTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${docs.length} account${docs.length == 1 ? '' : 's'} linked',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white60),
                            ),
                          ],
                        ),
                      ),

                      // Grouped by type
                      ...grouped.entries.map((entry) {
                        final String type = entry.key;
                        final List<QueryDocumentSnapshot> typeDocs = entry.value;
                        final typeInfo = _accountTypes.firstWhere(
                          (t) => t['type'] == type,
                          orElse: () => {
                            'icon': Icons.account_balance,
                            'color': const Color(0xFF0F3826),
                            'bgColor': const Color(0xFFC8F6E0),
                          },
                        );
                        final Color color = typeInfo['color'] as Color;
                        final Color bgColor = typeInfo['bgColor'] as Color;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                type.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade500,
                                    letterSpacing: 0.5),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              margin: const EdgeInsets.only(bottom: 20),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: typeDocs.length,
                                separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    indent: 68,
                                    color: Colors.grey.shade100),
                                itemBuilder: (context, idx) {
                                  final doc = typeDocs[idx];
                                  final d = doc.data() as Map<String, dynamic>;
                                  final String name = d['name'] as String? ?? 'Account';
                                  final String acctNum = d['account_number'] as String? ?? '';
                                  final double bal =
                                      (d['balance'] as num?)?.toDouble() ?? 0.0;

                                  return Dismissible(
                                    key: Key(doc.id),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Icon(Icons.delete_outline,
                                          color: Colors.red.shade400, size: 22),
                                    ),
                                    onDismissed: (_) => _confirmDelete(doc.id, name),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 14),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: bgColor,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              typeInfo['icon'] as IconData,
                                              color: color,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(name,
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14)),
                                                if (acctNum.isNotEmpty)
                                                  Text('•••• $acctNum',
                                                      style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.grey.shade500)),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '\$${bal.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: bal >= 0
                                                        ? _green
                                                        : Colors.red.shade400),
                                              ),
                                              Text('balance',
                                                  style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey.shade400)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showTypePicker,
        backgroundColor: _green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}