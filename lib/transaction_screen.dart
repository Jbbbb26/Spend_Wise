import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SpendWiseTransactionsScreen extends StatefulWidget {
  const SpendWiseTransactionsScreen({super.key});

  @override
  State<SpendWiseTransactionsScreen> createState() =>
      _SpendWiseTransactionsScreenState();
}

class _SpendWiseTransactionsScreenState
    extends State<SpendWiseTransactionsScreen> {
  final Color primaryGreen = const Color(0xFF0F3826);
  final Color backgroundGray = const Color(0xFFF8F9FA);

  String _filter = 'All'; // 'All' | 'Income' | 'Expenses'
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Group a flat list of docs by calendar date label ("TODAY — OCT 24" style)
  Map<String, List<QueryDocumentSnapshot>> _groupByDate(
      List<QueryDocumentSnapshot> docs) {
    final Map<String, List<QueryDocumentSnapshot>> grouped = {};
    final now = DateTime.now();

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final Timestamp? ts = data['timestamp'] as Timestamp?;
      final DateTime date = ts?.toDate() ?? now;

      final bool isToday = date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
      final bool isYesterday = date.year == now.year &&
          date.month == now.month &&
          date.day == now.day - 1;

      final String label;
      if (isToday) {
        label = 'TODAY — ${DateFormat('MMM d').format(date).toUpperCase()}';
      } else if (isYesterday) {
        label = 'YESTERDAY — ${DateFormat('MMM d').format(date).toUpperCase()}';
      } else {
        label = DateFormat('MMM d').format(date).toUpperCase();
      }

      grouped.putIfAbsent(label, () => []).add(doc);
    }
    return grouped;
  }

  bool _matchesFilter(Map<String, dynamic> tx) {
    if (_filter == 'Income' && tx['type'] != 'income') return false;
    if (_filter == 'Expenses' && tx['type'] != 'expense') return false;
    return true;
  }

  bool _matchesSearch(Map<String, dynamic> tx) {
    if (_searchQuery.isEmpty) return true;
    final q = _searchQuery.toLowerCase();
    final category = (tx['category'] as String? ?? '').toLowerCase();
    final note = (tx['note'] as String? ?? '').toLowerCase();
    final tags = (tx['tags'] as String? ?? '').toLowerCase();
    return category.contains(q) || note.contains(q) || tags.contains(q);
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGray,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  // App icon / logo placeholder
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: primaryGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.savings_outlined,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Transactions',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      color: primaryGreen,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.settings_outlined, size: 26),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Search bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search activity, merchants, or tags',
                    hintStyle: TextStyle(
                        color: Colors.grey.shade400, fontSize: 13),
                    prefixIcon: Icon(Icons.search,
                        color: Colors.grey.shade400, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: Icon(Icons.close,
                                color: Colors.grey.shade400, size: 18),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Filter tabs ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Income', 'Expenses'].map((label) {
                    final bool selected = _filter == label;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = label),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? primaryGreen : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: selected
                                ? primaryGreen
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: selected
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Transaction list ─────────────────────────────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(_uid)
                    .collection('transactions')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return Center(
                        child: CircularProgressIndicator(
                            color: primaryGreen));
                  }

                  final allDocs = snap.data?.docs ?? [];

                  // Apply filter + search
                  final filtered = allDocs.where((doc) {
                    final tx = doc.data() as Map<String, dynamic>;
                    return _matchesFilter(tx) && _matchesSearch(tx);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 52, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No results for "$_searchQuery"'
                                : 'No transactions yet',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap + to add your first transaction',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    );
                  }

                  final grouped = _groupByDate(filtered);
                  final dateKeys = grouped.keys.toList();

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: dateKeys.length + 1, // +1 for footer
                    itemBuilder: (context, idx) {
                      // Footer
                      if (idx == dateKeys.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: Divider(color: Colors.grey.shade300),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                child: Text(
                                  'END OF RECENT ACTIVITY',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade400,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5),
                                ),
                              ),
                              Expanded(
                                child: Divider(color: Colors.grey.shade300),
                              ),
                            ],
                          ),
                        );
                      }

                      final dateLabel = dateKeys[idx];
                      final txList = grouped[dateLabel]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Date header ──────────────────────────────
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 8, bottom: 10),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dateLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade500,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  '${txList.length} item${txList.length == 1 ? '' : 's'}',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade400),
                                ),
                              ],
                            ),
                          ),

                          // ── Transaction items ────────────────────────
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: txList.length,
                              separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  indent: 68,
                                  color: Colors.grey.shade100),
                              itemBuilder: (context, txIdx) {
                                final tx = txList[txIdx].data()
                                    as Map<String, dynamic>;
                                return _buildTransactionTile(tx);
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ── Bottom Nav ───────────────────────────────────────────────────────
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/overview');
          if (index == 2) Navigator.pushReplacementNamed(context, '/budgets');
          if (index == 3) Navigator.pushReplacementNamed(context, '/tasks');
          if (index == 4) Navigator.pushReplacementNamed(context, '/profile');
        },
        selectedItemColor: const Color(0xFF0F3826),
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
              icon: Icon(Icons.checklist_rounded), label: 'TASKS'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'PROFILE'),
        ],
      ),
    );
  }

  // ── Single transaction tile ───────────────────────────────────────────────
  Widget _buildTransactionTile(Map<String, dynamic> tx) {
    final bool isExpense = tx['type'] == 'expense';
    final double amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
    final String category = tx['category'] ?? 'Unknown';
    final String note = tx['note'] as String? ?? '';
    final int iconCode = tx['category_icon_code'] ?? 0xe532;
    final Timestamp? ts = tx['timestamp'] as Timestamp?;
    final String timeStr = ts != null
        ? DateFormat('h:mm a').format(ts.toDate())
        : '';

    // Subtitle: show note if present, otherwise category type label
    final String subtitle = note.isNotEmpty
        ? note
        : isExpense
            ? 'Expense • $timeStr'
            : 'Income • $timeStr';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Icon bubble
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isExpense
                  ? const Color(0xFFFFE8E8)
                  : const Color(0xFFC8F6E0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              IconData(iconCode, fontFamily: 'MaterialIcons'),
              color: isExpense ? Colors.red.shade400 : primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),

          // Name + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Amount
          Text(
            '${isExpense ? '-' : '+'}\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isExpense ? Colors.red.shade400 : primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}