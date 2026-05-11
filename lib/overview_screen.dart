import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'add_transaction_screen.dart';

class SpendWiseOverviewScreen extends StatefulWidget {
  const SpendWiseOverviewScreen({super.key});

  @override
  State<SpendWiseOverviewScreen> createState() => _SpendWiseOverviewScreenState();
}

class _SpendWiseOverviewScreenState extends State<SpendWiseOverviewScreen>
    with SingleTickerProviderStateMixin {
  final Color primaryGreen = const Color(0xFF0F3826);
  final Color backgroundGray = const Color(0xFFF8F9FA);

  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
  if (index == 1) {
    Navigator.pushNamed(context, '/transactions'); // ← ADD THIS
  } else if (index == 2) {
    Navigator.pushNamed(context, '/budgets');
  } else if (index == 3) {
    Navigator.pushNamed(context, '/tasks');
  } else if (index == 4) {
    Navigator.pushNamed(context, '/profile');
  } else {
    setState(() => _selectedIndex = index);
  }
} 

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: backgroundGray,
      body: SafeArea(
        child: user == null
            ? const Center(child: Text("Please log in."))
            : StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(color: Color(0xFF0F3826)));
                  }

                  final data = snapshot.data?.data() as Map<String, dynamic>?;
                  final double balance = (data?['balance'] as num?)?.toDouble() ?? 0.0;
                  final double monthlyIncome = (data?['monthly_income'] as num?)?.toDouble() ?? 0.0;
                  final double monthlySpent = (data?['monthly_spent'] as num?)?.toDouble() ?? 0.0;
                  final String displayName = data?['first_name'] ??
                      (data?['name'] as String?)?.split(' ').first ??
                      user.displayName ??
                      'User';

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pushNamed(context, '/profile'),
                                  child: const CircleAvatar(
                                    radius: 18,
                                    backgroundImage: AssetImage('assets/images/profile.png'),
                                    backgroundColor: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'HELLO, ${displayName.toUpperCase()}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: primaryGreen,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(Icons.settings_outlined, size: 28),
                              ],
                            ),
                            const SizedBox(height: 20),

                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: TabBar(
                                controller: _tabController,
                                labelColor: Colors.white,
                                unselectedLabelColor: Colors.grey.shade600,
                                labelStyle: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                                unselectedLabelStyle: const TextStyle(
                                    fontWeight: FontWeight.w500, fontSize: 13),
                                indicator: BoxDecoration(
                                  color: primaryGreen,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                indicatorSize: TabBarIndicatorSize.tab,
                                dividerColor: Colors.transparent,
                                padding: const EdgeInsets.all(4),
                                tabs: const [
                                  Tab(text: 'Overview'),
                                  Tab(text: 'Income'),
                                  Tab(text: 'Expenses'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: _buildOverviewPanel(
                                  balance, monthlyIncome, monthlySpent, user.uid),
                            ),
                            SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: _buildTransactionSummaryPanel(user.uid, 'income'),
                            ),
                            SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: _buildTransactionSummaryPanel(user.uid, 'expense'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const SpendWiseAddTransactionScreen()),
          );
        },
        backgroundColor: primaryGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'OVERVIEW'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'TRANSACTIONS'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'BUDGETS'),
          BottomNavigationBarItem(icon: Icon(Icons.checklist_rounded), label: 'TASKS'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'PROFILE'),
        ],
      ),
    );
  }

  // ── OVERVIEW PANEL (summary-only) ─────────────────────────────────────────
  Widget _buildOverviewPanel(
      double balance, double monthlyIncome, double monthlySpent, String uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Balance card ────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TOTAL AVAILABLE BALANCE',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                      letterSpacing: 0.5)),
              const SizedBox(height: 10),
              Text('\$${balance.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: balance < 0 ? Colors.red.shade400 : Colors.black)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFC8F6E0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('↑ Active Sync',
                    style: TextStyle(
                        color: Color(0xFF0C7A43),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('INCOME: \$${monthlyIncome.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                  Text('SPENT: \$${monthlySpent.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Budget Summary card ─────────────────────────────────────────
        _buildBudgetSummaryCard(uid),
        const SizedBox(height: 20),

        // ── Tasks Summary card ──────────────────────────────────────────
        _buildTasksSummaryCard(uid),
        const SizedBox(height: 20),

        // ── Recent Transactions (top 3) ─────────────────────────────────
        _buildRecentTransactionsCard(uid),
        const SizedBox(height: 100),
      ],
    );
  }

  // ── Budget Summary Card ───────────────────────────────────────────────────
  Widget _buildBudgetSummaryCard(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('budgets')
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snap) {
        final budgets = snap.data?.docs ?? [];

        // Totals
        double totalLimit = 0;
        double totalSpent = 0;
        for (final doc in budgets) {
          final d = doc.data() as Map<String, dynamic>;
          totalLimit += (d['limit'] as num?)?.toDouble() ?? 0.0;
          totalSpent += (d['spent'] as num?)?.toDouble() ?? 0.0;
        }
        final double totalProgress =
            totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.0) : 0;
        final double remaining = totalLimit - totalSpent;

        // Show top 3 budgets only
        final topBudgets = budgets.take(3).toList();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Budget Status',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/budgets'),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: primaryGreen,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('See All',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (budgets.isEmpty)
                Text('No budgets set up yet.',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic))
              else ...[
                // Overall progress bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Overall',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700)),
                    Text(
                      remaining >= 0
                          ? '\$${remaining.toStringAsFixed(0)} left'
                          : '-\$${remaining.abs().toStringAsFixed(0)} over',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: remaining >= 0
                              ? primaryGreen
                              : Colors.red.shade400),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalProgress,
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      totalProgress >= 1.0
                          ? Colors.red.shade400
                          : totalProgress >= 0.8
                              ? Colors.orange.shade400
                              : primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text('${(totalProgress * 100).toInt()}% of \$${totalLimit.toStringAsFixed(0)} used',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),

                const SizedBox(height: 16),

                // Top 3 category bars
                ...topBudgets.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  final String category = d['category'] ?? 'Unknown';
                  final double limit = (d['limit'] as num?)?.toDouble() ?? 0.0;
                  final double spent = (d['spent'] as num?)?.toDouble() ?? 0.0;
                  final double pct = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0;
                  final bool isOver = spent > limit;
                  final Color barColor = isOver
                      ? Colors.red.shade400
                      : pct >= 0.8
                          ? Colors.orange.shade400
                          : primaryGreen;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildBudgetBar(
                      category,
                      isOver
                          ? 'Over budget!'
                          : '${(pct * 100).toInt()}% used',
                      pct,
                      barColor,
                    ),
                  );
                }),

                if (budgets.length > 3)
                  Text(
                    '+${budgets.length - 3} more budget${budgets.length - 3 == 1 ? '' : 's'} — tap See All',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ── Tasks Summary Card ────────────────────────────────────────────────────
  Widget _buildTasksSummaryCard(String uid) {
    final groupsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('task_groups');

    final billsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('monthly_bills');

    return StreamBuilder<QuerySnapshot>(
      stream: groupsRef.snapshots(),
      builder: (context, groupsSnap) {
        final groups = groupsSnap.data?.docs ?? [];

        return StreamBuilder<QuerySnapshot>(
          stream: billsRef.snapshots(),
          builder: (context, billsSnap) {
            final bills = billsSnap.data?.docs ?? [];
            final int unpaidBills = bills
                .where((d) =>
                    (d.data() as Map<String, dynamic>)['paid'] != true)
                .length;

            // Count pending tasks across all groups using FutureBuilder
            return FutureBuilder<int>(
              future: _countPendingTasks(groups),
              builder: (context, countSnap) {
                final int pendingTasks = countSnap.data ?? 0;
                final int totalGroups = groups.length;
                final bool allClear = pendingTasks == 0 && unpaidBills == 0;

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tasks & Bills',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/tasks'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: primaryGreen,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('See All',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      if (allClear)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC8F6E0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.celebration_outlined,
                                  size: 16, color: primaryGreen),
                              const SizedBox(width: 8),
                              Text('All caught up!',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: primaryGreen)),
                            ],
                          ),
                        )
                      else
                        Row(
                          children: [
                            // Pending tasks stat
                            Expanded(
                              child: _buildStatChip(
                                icon: Icons.checklist_rounded,
                                label: 'Pending Tasks',
                                value: '$pendingTasks',
                                color: pendingTasks > 0
                                    ? Colors.orange.shade400
                                    : primaryGreen,
                                bgColor: pendingTasks > 0
                                    ? Colors.orange.shade50
                                    : const Color(0xFFC8F6E0),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Unpaid bills stat
                            Expanded(
                              child: _buildStatChip(
                                icon: Icons.receipt_long_outlined,
                                label: 'Unpaid Bills',
                                value: '$unpaidBills',
                                color: unpaidBills > 0
                                    ? Colors.red.shade400
                                    : primaryGreen,
                                bgColor: unpaidBills > 0
                                    ? Colors.red.shade50
                                    : const Color(0xFFC8F6E0),
                              ),
                            ),
                          ],
                        ),

                      if (totalGroups > 0) ...[
                        const SizedBox(height: 10),
                        Text(
                          '$totalGroups task group${totalGroups == 1 ? '' : 's'} • Tap See All to manage',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade400),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<int> _countPendingTasks(List<QueryDocumentSnapshot> groups) async {
    int pending = 0;
    for (final group in groups) {
      final items = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('task_groups')
          .doc(group.id)
          .collection('items')
          .where('done', isEqualTo: false)
          .get();
      pending += items.docs.length;
    }
    return pending;
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(label,
                  style: TextStyle(fontSize: 10, color: color.withOpacity(0.8))),
            ],
          ),
        ],
      ),
    );
  }

  // ── Recent Transactions Card (top 3 + See All) ────────────────────────────
  Widget _buildRecentTransactionsCard(String uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            GestureDetector(
              onTap: () => _onItemTapped(1), // navigate to TRANSACTIONS tab
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: primaryGreen,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('See All',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('transactions')
              .orderBy('timestamp', descending: true)
              .limit(3) // ← only top 3
              .snapshots(),
          builder: (context, txSnap) {
            if (txSnap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(color: Color(0xFF0F3826))));
            }
            final docs = txSnap.data?.docs ?? [];
            if (docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 40, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text('No transactions yet',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 13)),
                    ],
                  ),
                ),
              );
            }
            return Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (context, index) {
                  final tx = docs[index].data() as Map<String, dynamic>;
                  final bool isExpense = tx['type'] == 'expense';
                  final double amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
                  final String category = tx['category'] ?? 'Unknown';
                  final int iconCode = tx['category_icon_code'] ?? 0xe532;
                  final Timestamp? ts = tx['timestamp'] as Timestamp?;
                  final String timeStr = ts != null
                      ? DateFormat('MMM d, h:mm a').format(ts.toDate())
                      : 'Just now';
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isExpense
                            ? const Color(0xFFFFE8E8)
                            : const Color(0xFFC8F6E0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        IconData(iconCode, fontFamily: 'MaterialIcons'),
                        color: isExpense ? Colors.red.shade400 : primaryGreen,
                        size: 18,
                      ),
                    ),
                    title: Text(category,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: Text(timeStr,
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey)),
                    trailing: Text(
                      '${isExpense ? '-' : '+'}\$${amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isExpense ? Colors.red.shade400 : primaryGreen,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Reusable budget bar ───────────────────────────────────────────────────
  Widget _buildBudgetBar(
      String title, String subtitle, double percentage, Color barColor) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text(subtitle,
                style: TextStyle(
                    color: barColor == primaryGreen
                        ? Colors.grey
                        : barColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey.shade300,
          color: barColor,
          minHeight: 6,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  // ── Transaction summary panels (Income / Expenses tabs — unchanged) ────────
  Widget _buildTransactionSummaryPanel(String uid, String type) {
    final bool isIncome = type == 'income';
    final Color amountColor = isIncome ? primaryGreen : Colors.red.shade400;
    final Color bgColor =
        isIncome ? const Color(0xFFC8F6E0) : const Color(0xFFFFE8E8);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .where('type', isEqualTo: type)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: Color(0xFF0F3826))));
        }

        final docs = snap.data?.docs ?? [];
        final Map<String, double> categoryTotals = {};
        final Map<String, int> categoryIcons = {};
        double grandTotal = 0;

        for (final doc in docs) {
          final tx = doc.data() as Map<String, dynamic>;
          final String cat = tx['category'] ?? 'Unknown';
          final double amt = (tx['amount'] as num?)?.toDouble() ?? 0.0;
          final int icon = tx['category_icon_code'] ?? 0xe532;
          categoryTotals[cat] = (categoryTotals[cat] ?? 0) + amt;
          categoryIcons[cat] = icon;
          grandTotal += amt;
        }

        final sortedCategories = categoryTotals.keys.toList()
          ..sort((a, b) => categoryTotals[b]!.compareTo(categoryTotals[a]!));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isIncome
                        ? 'TOTAL INCOME THIS MONTH'
                        : 'TOTAL EXPENSES THIS MONTH',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${isIncome ? '+' : '-'}\$${grandTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: amountColor),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC8F6E0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('↑ Active Sync',
                        style: TextStyle(
                            color: Color(0xFF0C7A43),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${sortedCategories.length} categor${sortedCategories.length == 1 ? 'y' : 'ies'}  •  ${docs.length} transaction${docs.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (sortedCategories.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        isIncome
                            ? Icons.account_balance_wallet_outlined
                            : Icons.receipt_long_outlined,
                        size: 40,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isIncome
                            ? 'No income recorded yet'
                            : 'No expenses recorded yet',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isIncome ? 'Income by category' : 'Expenses by category',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ...sortedCategories.map((cat) {
                      final double amt = categoryTotals[cat]!;
                      final int iconCode = categoryIcons[cat] ?? 0xe532;
                      final double pct = grandTotal > 0 ? amt / grandTotal : 0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                IconData(iconCode, fontFamily: 'MaterialIcons'),
                                color: isIncome
                                    ? primaryGreen
                                    : Colors.red.shade400,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(cat,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13)),
                                      Text(
                                        '${isIncome ? '+' : '-'}\$${amt.toStringAsFixed(2)}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: amountColor),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Stack(
                                    children: [
                                      Container(
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                      FractionallySizedBox(
                                        widthFactor: pct,
                                        child: Container(
                                          height: 5,
                                          decoration: BoxDecoration(
                                            color: amountColor,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${(pct * 100).toStringAsFixed(1)}% of total',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    Divider(color: Colors.grey.shade300, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(
                          '${isIncome ? '+' : '-'}\$${grandTotal.toStringAsFixed(2)}',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: amountColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 100),
          ],
        );
      },
    );
  }
}