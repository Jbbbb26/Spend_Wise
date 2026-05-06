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

class _SpendWiseOverviewScreenState extends State<SpendWiseOverviewScreen> {
  final Color primaryGreen = const Color(0xFF0F3826);
  final Color backgroundGray = const Color(0xFFF8F9FA);

  // 'Overview' | 'Income' | 'Expenses'
  String _activeTab = 'Overview';
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (index == 3) {
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
                  final double balance =
                      (data?['balance'] as num?)?.toDouble() ?? 0.0;
                  final double monthlyIncome =
                      (data?['monthly_income'] as num?)?.toDouble() ?? 0.0;
                  final double monthlySpent =
                      (data?['monthly_spent'] as num?)?.toDouble() ?? 0.0;
                  final String displayName = data?['first_name'] ??
                      (data?['name'] as String?)?.split(' ').first ??
                      user.displayName ??
                      'User';

                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Header ──────────────────────────────────────
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    Navigator.pushNamed(context, '/profile'),
                                child: const CircleAvatar(
                                  radius: 18,
                                  backgroundImage:
                                      AssetImage('assets/images/profile.png'),
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
                          const SizedBox(height: 24),

                          // ── Tabs ─────────────────────────────────────────
                          Row(
                            children: [
                              _buildTab('Overview'),
                              const SizedBox(width: 10),
                              _buildTab('Income'),
                              const SizedBox(width: 10),
                              _buildTab('Expenses'),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // ── Tab Panels ────────────────────────────────────
                          if (_activeTab == 'Overview')
                            _buildOverviewPanel(
                                balance, monthlyIncome, monthlySpent, user.uid),
                          if (_activeTab == 'Income')
                            _buildTransactionSummaryPanel(user.uid, 'income'),
                          if (_activeTab == 'Expenses')
                            _buildTransactionSummaryPanel(user.uid, 'expense'),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),

      // ── FAB ────────────────────────────────────────────────────────────────
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

      // ── Bottom Nav ──────────────────────────────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view), label: 'OVERVIEW'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: 'TRANSACTIONS'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: 'BUDGETS'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'PROFILE'),
        ],
      ),
    );
  }

  // ── Overview panel (original content) ──────────────────────────────────────
  Widget _buildOverviewPanel(
      double balance, double monthlyIncome, double monthlySpent, String uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Balance card
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
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('INCOME: \$${monthlyIncome.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold)),
                  Text('SPENT: \$${monthlySpent.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Budget Status
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Budget Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildBudgetBar('Housing', '85% used', 0.85),
              const SizedBox(height: 16),
              _buildBudgetBar('Dining', '42% used', 0.42),
              const SizedBox(height: 16),
              _buildBudgetBar('Entertainment', '18% used', 0.18),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Recent Transactions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {},
              child: Text('See All',
                  style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
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
              .limit(5)
              .snapshots(),
          builder: (context, txSnap) {
            if (txSnap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: Padding(
                      padding: EdgeInsets.all(16),
                      child:
                          CircularProgressIndicator(color: Color(0xFF0F3826))));
            }
            final docs = txSnap.data?.docs ?? [];
            if (docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16)),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (context, index) {
                  final tx = docs[index].data() as Map<String, dynamic>;
                  final bool isExpense = tx['type'] == 'expense';
                  final double amount =
                      (tx['amount'] as num?)?.toDouble() ?? 0.0;
                  final String category = tx['category'] ?? 'Unknown';
                  final int iconCode = tx['category_icon_code'] ?? 0xe532;
                  final Timestamp? ts = tx['timestamp'] as Timestamp?;
                  final String timeStr = ts != null
                      ? DateFormat('MMM d, h:mm a').format(ts.toDate())
                      : 'Just now';
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
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
                        color:
                            isExpense ? Colors.red.shade400 : primaryGreen,
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

  // ── Income / Expense summary panel ─────────────────────────────────────────
  // Queries ALL transactions of the given type, groups by category, sums totals.
  Widget _buildTransactionSummaryPanel(String uid, String type) {
    final bool isIncome = type == 'income';
    final Color amountColor =
        isIncome ? primaryGreen : Colors.red.shade400;
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

        // Group and sum by category
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

        // Sort categories by total descending
        final sortedCategories = categoryTotals.keys.toList()
          ..sort((a, b) =>
              categoryTotals[b]!.compareTo(categoryTotals[a]!));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary balance card
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
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

            // Category breakdown
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
                      isIncome
                          ? 'Income by category'
                          : 'Expenses by category',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    // Category rows
                    ...sortedCategories.map((cat) {
                      final double amt = categoryTotals[cat]!;
                      final int iconCode =
                          categoryIcons[cat] ?? 0xe532;
                      final double pct =
                          grandTotal > 0 ? amt / grandTotal : 0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    IconData(iconCode,
                                        fontFamily: 'MaterialIcons'),
                                    color: isIncome
                                        ? primaryGreen
                                        : Colors.red.shade400,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment
                                                .spaceBetween,
                                        children: [
                                          Text(cat,
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  fontSize: 13)),
                                          Text(
                                            '${isIncome ? '+' : '-'}\$${amt.toStringAsFixed(2)}',
                                            style: TextStyle(
                                                fontWeight:
                                                    FontWeight.bold,
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
                                                  BorderRadius.circular(
                                                      4),
                                            ),
                                          ),
                                          FractionallySizedBox(
                                            widthFactor: pct,
                                            child: Container(
                                              height: 5,
                                              decoration: BoxDecoration(
                                                color: amountColor,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        4),
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
                          ],
                        ),
                      );
                    }),

                    // Grand total row
                    Divider(color: Colors.grey.shade300, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
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
          ],
        );
      },
    );
  }

  // ── Helper widgets ──────────────────────────────────────────────────────────
  Widget _buildTab(String title) {
    final bool isActive = _activeTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? primaryGreen : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: isActive ? null : Border.all(color: Colors.grey.shade300),
          ),
          alignment: Alignment.center,
          child: Text(title,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              )),
        ),
      ),
    );
  }

  Widget _buildBudgetBar(String title, String subtitle, double percentage) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            Text(subtitle,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey.shade300,
          color: primaryGreen,
          minHeight: 6,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}