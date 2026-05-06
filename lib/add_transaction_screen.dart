import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'budgetcategories.dart';

class SpendWiseAddTransactionScreen extends StatefulWidget {
  const SpendWiseAddTransactionScreen({super.key});

  @override
  State<SpendWiseAddTransactionScreen> createState() =>
      _SpendWiseAddTransactionScreenState();
}

class _SpendWiseAddTransactionScreenState
    extends State<SpendWiseAddTransactionScreen> {
  final Color primaryGreen = const Color(0xFF0F3826);
  final Color backgroundGray = const Color(0xFFF8F9FA);

  String _activeTab = 'Expenses';
  String _amount = '0';
  String _selectedCategory = 'Dining & Cafe';
  IconData _selectedIcon = Icons.restaurant;
  int _selectedIconCode = 0xe532;
  String _expression = '';
  bool _hasOperator = false;

  final List<String> keys = [
    '1', '2', '3', '×',
    '4', '5', '6', '-',
    '7', '8', '9', '+',
    '.', '0', 'C', '=',
  ];

  Future<void> _openCategoryPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => SpendWiseCategoriesScreen(activeTab: _activeTab),
      ),
    );
    if (result != null) {
      setState(() {
        _selectedCategory = result['title'];
        _selectedIconCode = result['iconCode'];
        _selectedIcon = IconData(result['iconCode'], fontFamily: 'MaterialIcons');
      });
    }
  }

  Future<void> _saveTransaction() async {
    final user = FirebaseAuth.instance.currentUser;
    final double amount = double.tryParse(_amount) ?? 0.0;
    if (user == null || amount == 0.0) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final isExpense = _activeTab == 'Expenses';
    final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final transactionsRef = userDocRef.collection('transactions');

    try {
      // Step 1: Read user doc first (outside transaction)
      final userSnap = await userDocRef.get();
      final data = userSnap.data() as Map<String, dynamic>? ?? {};
      final double curBalance = (data['balance'] as num?)?.toDouble() ?? 0.0;
      final double curIncome = (data['monthly_income'] as num?)?.toDouble() ?? 0.0;
      final double curSpent = (data['monthly_spent'] as num?)?.toDouble() ?? 0.0;

      // Step 2: Write transaction record with DateTime.now() instead of serverTimestamp
      await transactionsRef.add({
        'type': isExpense ? 'expense' : 'income',
        'amount': amount,
        'category': _selectedCategory,
        'category_icon_code': _selectedIconCode,
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });

      // Step 3: Update user totals with merge
      await userDocRef.set({
        'balance': isExpense ? curBalance - amount : curBalance + amount,
        'monthly_income': isExpense ? curIncome : curIncome + amount,
        'monthly_spent': isExpense ? curSpent + amount : curSpent,
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pop(context); // close spinner
        Navigator.pop(context); // close add screen
      }
    } catch (e, stack) {
      if (mounted) Navigator.pop(context);
      debugPrint('Save Transaction Error: ${e.toString()}');
      debugPrint('Stack: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onKeyPress(String key) {
    setState(() {
      if (key == 'C') {
        _amount = '0';
        _expression = '';
        _hasOperator = false;
        return;
      }
      if (['+', '-', '×', '÷'].contains(key)) {
        if (_amount != '0') {
          _expression = '$_amount $key ';
          _amount = '0';
          _hasOperator = true;
        }
        return;
      }
      if (key == '=') {
        if (_hasOperator && _expression.isNotEmpty) {
          try {
            final parts = _expression.trim().split(' ');
            final left = double.parse(parts[0]);
            final op = parts[1];
            final right = double.parse(_amount);
            double result;
            switch (op) {
              case '+': result = left + right; break;
              case '-': result = left - right; break;
              case '×': result = left * right; break;
              case '÷': result = right != 0 ? left / right : 0; break;
              default: result = right;
            }
            _amount = result % 1 == 0
                ? result.toInt().toString()
                : result.toStringAsFixed(2);
            _expression = '';
            _hasOperator = false;
          } catch (_) {}
        }
        return;
      }
      if (key == '.') {
        if (!_amount.contains('.')) _amount += '.';
        return;
      }
      _amount = _amount == '0' ? key : _amount + key;
    });
  }

  void _onBackspace() {
    setState(() {
      _amount = _amount.length > 1 ? _amount.substring(0, _amount.length - 1) : '0';
    });
  }

  String _formatDisplay(String s) {
    if (s == '0' || s.isEmpty) return '0.00';
    if (s.endsWith('.')) return '${s}00';
    try {
      return double.parse(s).toStringAsFixed(2);
    } catch (_) {
      return '0.00';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentTime = DateFormat('jm').format(DateTime.now());

    return Scaffold(
      backgroundColor: backgroundGray,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double maxW = 420;
            final double sidePad = constraints.maxWidth > maxW
                ? (constraints.maxWidth - maxW) / 2
                : 0;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: sidePad),
              child: Column(
                children: [
                  // ── Header + tabs + amount + category (compact, no Expanded scroll) ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage: const AssetImage('assets/images/profile.png'),
                                    backgroundColor: Colors.blueGrey.shade200,
                                  ),
                                  const SizedBox(width: 8),
                                  Text('SPENDWISE',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: primaryGreen,
                                          fontSize: 15)),
                                ],
                              ),
                            ),
                            const Icon(Icons.settings_outlined, size: 22),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Income / Expenses tabs
                        Container(
                          decoration: BoxDecoration(
                              color: const Color(0xFFF1F3F5),
                              borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              _buildTypeTab('Income'),
                              _buildTypeTab('Expenses'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Amount display
                        const Text('AMOUNT TO LOG',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8)),
                        const SizedBox(height: 4),
                        if (_expression.isNotEmpty)
                          Text(_expression,
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('\$',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _formatDisplay(_amount),
                                style: const TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF161E2E)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: _onBackspace,
                              child: Icon(Icons.backspace_outlined,
                                  size: 20, color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Category card — tappable
                        GestureDetector(
                          onTap: _openCategoryPicker,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFC8F6E0),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Icon(_selectedIcon, color: primaryGreen, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_selectedCategory,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text('Today at $currentTime',
                                          style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFF1F3F5),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Text(_activeTab.toUpperCase(),
                                      style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 16),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),

                  // ── Spacer pushes keypad to bottom ──────────────────────
                  const Spacer(),

                  // ── Fixed keypad ─────────────────────────────────────────
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.6,
                      ),
                      itemCount: keys.length,
                      itemBuilder: (context, i) {
                        final key = keys[i];
                        final isOp = ['+', '-', '×', '÷'].contains(key);
                        final isEq = key == '=';
                        final isCl = key == 'C';

                        return Material(
                          color: isEq
                              ? primaryGreen
                              : isCl
                                  ? Colors.red.shade50
                                  : isOp
                                      ? const Color(0xFFEFF6F1)
                                      : const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: () => _onKeyPress(key),
                            borderRadius: BorderRadius.circular(10),
                            child: Center(
                              child: Text(key,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    color: isEq
                                        ? Colors.white
                                        : isCl
                                            ? Colors.red
                                            : isOp
                                                ? primaryGreen
                                                : const Color(0xFF1F2937),
                                  )),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // ── Add Transaction button ────────────────────────────────
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveTransaction,
                        icon: const Icon(Icons.arrow_forward_outlined,
                            color: Colors.white, size: 15),
                        label: const Text('Add Transaction'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTypeTab(String title) {
    final bool isActive = _activeTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? primaryGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(title,
              style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
      ),
    );
  }
}