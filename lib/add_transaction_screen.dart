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
    extends State<SpendWiseAddTransactionScreen>
    with SingleTickerProviderStateMixin {
  final Color primaryGreen = const Color(0xFF0F3826);
  final Color backgroundGray = const Color(0xFFF8F9FA);

  String _activeTab = 'Expenses';
  String _amount = '0';

  // ── Date selection (defaults to today) ───────────────────────────────────────
  DateTime _selectedDate = DateTime.now();

  // ── Per-tab category state ───────────────────────────────────────────────────
  String _expenseCategory = 'Dining & Cafe';
  int _expenseIconCode = 0xe532;
  bool _expenseCategoryPicked = false;

  String _incomeCategory = 'Salary';
  int _incomeIconCode = 0xe8a5;
  bool _incomeCategoryPicked = false;

  // ── Getters ──────────────────────────────────────────────────────────────────
  String get _selectedCategory =>
      _activeTab == 'Expenses' ? _expenseCategory : _incomeCategory;

  int get _selectedIconCode =>
      _activeTab == 'Expenses' ? _expenseIconCode : _incomeIconCode;

  IconData get _selectedIcon =>
      IconData(_selectedIconCode, fontFamily: 'MaterialIcons');

  bool get _categoryPicked =>
      _activeTab == 'Expenses' ? _expenseCategoryPicked : _incomeCategoryPicked;

  // ── Validation ───────────────────────────────────────────────────────────────
  double get _parsedAmount => double.tryParse(_amount) ?? 0.0;
  bool get _amountIsValid => _parsedAmount > 0.0;
  bool get _canSave => _amountIsValid && _categoryPicked;

  late AnimationController _tabAnimController;

  final List<String> keys = [
    '1', '2', '3',
    '4', '5', '6',
    '7', '8', '9',
    '.', '0', '⌫',
  ];

  // ── Date helpers ─────────────────────────────────────────────────────────────
  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  String get _dateLabel {
    if (_isToday) {
      return 'Today at ${DateFormat('h:mm a').format(DateTime.now())}';
    }
    return 'Backdated — ${DateFormat('MMM d, yyyy').format(_selectedDate)}';
  }

  @override
  void initState() {
    super.initState();
    _tabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _tabAnimController.dispose();
    super.dispose();
  }

  // ── Backdate picker ───────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'SELECT TRANSACTION DATE',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: primaryGreen,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black87,
          ),
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  // ── Error snackbar ────────────────────────────────────────────────────────────
  void _showError(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade500,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Success dialog ────────────────────────────────────────────────────────────
  void _showSuccess() {
    final bool isExpense = _activeTab == 'Expenses';
    final Color accentColor = isExpense ? Colors.red.shade400 : primaryGreen;
    final String emoji = isExpense ? '💸' : '💰';
    final String amountText = '\$${_parsedAmount.toStringAsFixed(2)}';
    final String catText = _selectedCategory;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Transaction Added!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$amountText logged under $catText',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              // ── Show the selected date in success dialog ──────────────
              Text(
                _isToday
                    ? 'Recorded for today'
                    : 'Backdated to ${DateFormat('MMM d, yyyy').format(_selectedDate)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: _isToday ? Colors.grey.shade500 : primaryGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _activeTab.toUpperCase(),
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // back to overview
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Open category picker ──────────────────────────────────────────────────────
  Future<void> _openCategoryPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SpendWiseCategoriesScreen(activeTab: _activeTab),
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );

    if (result != null) {
      setState(() {
        if (_activeTab == 'Expenses') {
          _expenseCategory = result['title'];
          _expenseIconCode = result['iconCode'];
          _expenseCategoryPicked = true;
        } else {
          _incomeCategory = result['title'];
          _incomeIconCode = result['iconCode'];
          _incomeCategoryPicked = true;
        }
      });
    }
  }

  // ── Save transaction ──────────────────────────────────────────────────────────
  Future<void> _saveTransaction() async {
  if (!_amountIsValid) {
    _showError('Please enter an amount greater than \$0.00');
    return;
  }
  if (!_categoryPicked) {
    _showError('Please select a category before saving');
    return;
  }

  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    _showError('You must be logged in to save a transaction');
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  final bool isExpense = _activeTab == 'Expenses';
  final userDocRef =
      FirebaseFirestore.instance.collection('users').doc(user.uid);

  final now = DateTime.now();
  final DateTime transactionDateTime = DateTime(
    _selectedDate.year,
    _selectedDate.month,
    _selectedDate.day,
    now.hour,
    now.minute,
    now.second,
  );

  try {
    final userSnap = await userDocRef.get();
    final data = userSnap.data() as Map<String, dynamic>? ?? {};
    final double curBalance = (data['balance'] as num?)?.toDouble() ?? 0.0;
    final double curIncome = (data['monthly_income'] as num?)?.toDouble() ?? 0.0;
    final double curSpent = (data['monthly_spent'] as num?)?.toDouble() ?? 0.0;

    await userDocRef.collection('transactions').add({
      'type': isExpense ? 'expense' : 'income',
      'amount': _parsedAmount,
      'category': _selectedCategory,
      'category_icon_code': _selectedIconCode,
      'timestamp': Timestamp.fromDate(transactionDateTime),
    });

    await userDocRef.set({
      'balance': isExpense
          ? curBalance - _parsedAmount
          : curBalance + _parsedAmount,
      'monthly_income': isExpense ? curIncome : curIncome + _parsedAmount,
      'monthly_spent': isExpense ? curSpent + _parsedAmount : curSpent,
    }, SetOptions(merge: true));

    // ── Auto-sync budget spent amount ─────────────────────────────────────
    if (isExpense) {
      final budgetSnap = await userDocRef
          .collection('budgets')
          .where('category', isEqualTo: _selectedCategory)
          .get();

      if (budgetSnap.docs.isNotEmpty) {
        final budgetDoc = budgetSnap.docs.first;
        final double currentSpent =
            (budgetDoc.data()['spent'] as num?)?.toDouble() ?? 0.0;
        await userDocRef
            .collection('budgets')
            .doc(budgetDoc.id)
            .update({'spent': currentSpent + _parsedAmount});
      }
    }
    // ─────────────────────────────────────────────────────────────────────

    if (mounted) {
      Navigator.pop(context);
      _showSuccess();
    }
  } catch (e) {
    if (mounted) Navigator.pop(context);
    debugPrint('Save error: $e');
    if (mounted) _showError('Something went wrong. Please try again.');
  }
}

  // ── Keypad handler ────────────────────────────────────────────────────────────
  void _onKeyPress(String key) {
    setState(() {
      if (key == '⌫') {
        _amount = _amount.length > 1
            ? _amount.substring(0, _amount.length - 1)
            : '0';
        return;
      }
      if (key == '.') {
        if (!_amount.contains('.')) _amount += '.';
        return;
      }
      if (_amount == '0') {
        _amount = key;
      } else {
        if (_amount.contains('.')) {
          final parts = _amount.split('.');
          if (parts[1].length >= 2) return;
        }
        _amount += key;
      }
    });
  }

  String _formatDisplay(String s) =>
      (s == '0' || s.isEmpty) ? '0' : s;

  void _switchTab(String tab) {
    if (_activeTab == tab) return;
    _tabAnimController.forward(from: 0);
    setState(() => _activeTab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final bool isExpense = _activeTab == 'Expenses';
    final Color accentColor =
        isExpense ? Colors.red.shade400 : primaryGreen;

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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Header ─────────────────────────────────────
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage: const AssetImage(
                                        'assets/images/profile.png'),
                                    backgroundColor:
                                        Colors.blueGrey.shade200,
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

                        // ── Tab switcher ───────────────────────────────
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              _buildTypeTab('Income'),
                              _buildTypeTab('Expenses'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Amount label ───────────────────────────────
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            fontSize: 10,
                            color: accentColor.withOpacity(0.7),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                          child: const Text('AMOUNT TO LOG'),
                        ),
                        const SizedBox(height: 8),

                        // ── Amount display ─────────────────────────────
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: Row(
                            key: ValueKey(_amount),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedDefaultTextStyle(
                                duration:
                                    const Duration(milliseconds: 300),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: accentColor.withOpacity(0.5),
                                ),
                                child: const Text('\$'),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(
                                        milliseconds: 300),
                                    style: TextStyle(
                                      fontSize: 64,
                                      fontWeight: FontWeight.bold,
                                      color: accentColor,
                                    ),
                                    child:
                                        Text(_formatDisplay(_amount)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Inline hint ────────────────────────────────
                        const SizedBox(height: 6),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: !_amountIsValid
                              ? Row(
                                  key: const ValueKey('hint-amount'),
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.info_outline,
                                        size: 12,
                                        color: Colors.grey.shade400),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Enter an amount to get started',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade400),
                                    ),
                                  ],
                                )
                              : !_categoryPicked
                                  ? Row(
                                      key: const ValueKey('hint-cat'),
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.touch_app_outlined,
                                            size: 12,
                                            color: Colors.orange.shade400),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Now pick a category below',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color:
                                                  Colors.orange.shade400),
                                        ),
                                      ],
                                    )
                                  : const SizedBox.shrink(
                                      key: ValueKey('hint-none')),
                        ),
                        const SizedBox(height: 14),

                        // ── Category card ──────────────────────────────
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (_amountIsValid && !_categoryPicked)
                                  ? Colors.orange.shade300
                                  : accentColor.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _openCategoryPicker,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 300),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: accentColor.withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Icon(_selectedIcon,
                                          color: accentColor, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _categoryPicked
                                                ? _selectedCategory
                                                : 'Tap to select a category',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: _categoryPicked
                                                  ? Colors.black87
                                                  : Colors.grey.shade400,
                                            ),
                                          ),
                                          // ── Date display in card ───
                                          Text(
                                            _dateLabel,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: _isToday
                                                  ? Colors.grey
                                                  : primaryGreen,
                                              fontWeight: _isToday
                                                  ? FontWeight.normal
                                                  : FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 300),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color:
                                            accentColor.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        _activeTab.toUpperCase(),
                                        style: TextStyle(
                                            color: accentColor,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.chevron_right,
                                        color: Colors.grey.shade400,
                                        size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // ── Backdate button row ────────────────────────
                        GestureDetector(
                          onTap: _pickDate,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: _isToday
                                  ? backgroundGray
                                  : primaryGreen.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _isToday
                                    ? Colors.grey.shade200
                                    : primaryGreen.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_calendar_outlined,
                                  size: 16,
                                  color: _isToday
                                      ? Colors.grey.shade500
                                      : primaryGreen,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _isToday
                                            ? 'Transaction Date'
                                            : 'Backdated Transaction',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _isToday
                                              ? Colors.grey.shade600
                                              : primaryGreen,
                                        ),
                                      ),
                                      Text(
                                        _isToday
                                            ? 'Today — ${DateFormat('MMMM d, yyyy').format(_selectedDate)}'
                                            : DateFormat('MMMM d, yyyy')
                                                .format(_selectedDate),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _isToday
                                              ? Colors.grey.shade400
                                              : primaryGreen
                                                  .withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _isToday
                                        ? Colors.grey.shade200
                                        : primaryGreen.withOpacity(0.15),
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Change',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _isToday
                                          ? Colors.grey.shade600
                                          : primaryGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // ── Keypad ─────────────────────────────────────────────
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.2,
                      ),
                      itemCount: keys.length,
                      itemBuilder: (context, i) {
                        final key = keys[i];
                        final isBackspace = key == '⌫';
                        final isDot = key == '.';

                        return Material(
                          color: isBackspace
                              ? Colors.red.shade50
                              : const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: () => _onKeyPress(key),
                            borderRadius: BorderRadius.circular(10),
                            splashColor: isBackspace
                                ? Colors.red.shade100
                                : primaryGreen.withOpacity(0.1),
                            highlightColor: isBackspace
                                ? Colors.red.shade50
                                : primaryGreen.withOpacity(0.05),
                            child: Center(
                              child: isBackspace
                                  ? Icon(Icons.backspace_outlined,
                                      color: Colors.red.shade400, size: 22)
                                  : Text(
                                      key,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                        color: isDot
                                            ? Colors.grey.shade600
                                            : const Color(0xFF1F2937),
                                      ),
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // ── Add Transaction button ─────────────────────────────
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveTransaction,
                        icon: Icon(
                          _canSave
                              ? Icons.check_circle_outline
                              : Icons.arrow_forward_outlined,
                          color: Colors.white,
                          size: 15,
                        ),
                        label: const Text('Add Transaction'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _canSave
                              ? accentColor
                              : Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
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
    final bool isExpenseTab = title == 'Expenses';
    final Color activeColor =
        isExpenseTab ? Colors.red.shade400 : primaryGreen;

    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(title),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            child: Text(title),
          ),
        ),
      ),
    );
  }
}