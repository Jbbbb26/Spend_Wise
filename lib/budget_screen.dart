import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'budgetcategories.dart';

class SpendWiseBudgetScreen extends StatefulWidget {
  const SpendWiseBudgetScreen({super.key});

  @override
  State<SpendWiseBudgetScreen> createState() => _SpendWiseBudgetScreenState();
}

class _SpendWiseBudgetScreenState extends State<SpendWiseBudgetScreen> {
  final Color primaryGreen = const Color(0xFF0F3826);
  final Color backgroundGray = const Color(0xFFF8F9FA);

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference get _budgetsRef => FirebaseFirestore.instance
      .collection('users')
      .doc(_uid)
      .collection('budgets');

  // ── Create budget — uses a full bottom sheet instead of AlertDialog ────────
  void _showCreateBudgetSheet() {
    final amountCtrl = TextEditingController();
    String? selectedCategory;
    int selectedIconCode = 0xe532;
    String selectedPeriod = 'Monthly';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Sheet handle ──────────────────────────────────────
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

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Create Budget',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: primaryGreen,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(sheetCtx),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close,
                            size: 18, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Category picker ───────────────────────────────────
                Text('Category',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    // Close sheet first, then open category picker
                    Navigator.pop(sheetCtx);
                    final result =
                        await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SpendWiseCategoriesScreen(
                            activeTab: 'Expenses'),
                      ),
                    );
                    if (result != null && mounted) {
                      // Re-open the sheet with the selected category
                      _showCreateBudgetSheetWithData(
                        preselectedCategory: result['title'],
                        preselectedIconCode: result['iconCode'],
                        prefilledAmount: amountCtrl.text,
                        preselectedPeriod: selectedPeriod,
                      );
                    } else if (mounted) {
                      // Re-open without change
                      _showCreateBudgetSheetWithData(
                        prefilledAmount: amountCtrl.text,
                        preselectedPeriod: selectedPeriod,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: backgroundGray,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selectedCategory != null
                            ? primaryGreen.withOpacity(0.4)
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            IconData(selectedIconCode,
                                fontFamily: 'MaterialIcons'),
                            color: primaryGreen,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedCategory ?? 'Tap to select category',
                            style: TextStyle(
                              fontSize: 13,
                              color: selectedCategory != null
                                  ? Colors.black87
                                  : Colors.grey.shade400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            color: Colors.grey.shade400, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Budget limit ──────────────────────────────────────
                Text('Budget Limit',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                TextField(
                  controller: amountCtrl,
                  autofocus: false,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'e.g. 500',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixText: '\$ ',
                    filled: true,
                    fillColor: backgroundGray,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: primaryGreen.withOpacity(0.4), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Period selector ───────────────────────────────────
                Text('Period',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                Row(
                  children: ['Monthly', 'Weekly'].map((p) {
                    final bool isSelected = selectedPeriod == p;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setSheet(() => selectedPeriod = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin:
                              EdgeInsets.only(right: p == 'Monthly' ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color:
                                isSelected ? primaryGreen : backgroundGray,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? primaryGreen
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Text(
                            p,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // ── Create button ─────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final double? limit =
                          double.tryParse(amountCtrl.text.trim());

                      if (selectedCategory == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Please select a category'),
                            backgroundColor: Colors.orange.shade400,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      if (limit == null || limit <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                const Text('Please enter a valid amount'),
                            backgroundColor: Colors.orange.shade400,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      // Check duplicate
                      final existing = await _budgetsRef
                          .where('category', isEqualTo: selectedCategory)
                          .get();

                      if (existing.docs.isNotEmpty) {
                        if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'A budget for "$selectedCategory" already exists.'),
                              backgroundColor: Colors.orange.shade400,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                        return;
                      }

                      // Calculate already-spent from existing transactions
                      final txSnap = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(_uid)
                          .collection('transactions')
                          .where('type', isEqualTo: 'expense')
                          .where('category', isEqualTo: selectedCategory)
                          .get();

                      double alreadySpent = 0;
                      for (final doc in txSnap.docs) {
                        alreadySpent +=
                            (doc.data()['amount'] as num?)?.toDouble() ??
                                0.0;
                      }

                      // Save to Firestore
                      await _budgetsRef.add({
                        'category': selectedCategory,
                        'category_icon_code': selectedIconCode,
                        'limit': limit,
                        'spent': alreadySpent,
                        'period': selectedPeriod,
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      if (sheetCtx.mounted) Navigator.pop(sheetCtx);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '✓ "$selectedCategory" budget created!'),
                            backgroundColor: primaryGreen,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Create Budget'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Re-opens the sheet with pre-filled data after category pick ───────────
  void _showCreateBudgetSheetWithData({
    String? preselectedCategory,
    int preselectedIconCode = 0xe532,
    String prefilledAmount = '',
    String preselectedPeriod = 'Monthly',
  }) {
    final amountCtrl = TextEditingController(text: prefilledAmount);
    String? selectedCategory = preselectedCategory;
    int selectedIconCode = preselectedIconCode;
    String selectedPeriod = preselectedPeriod;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Create Budget',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: primaryGreen,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(sheetCtx),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close,
                            size: 18, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Text('Category',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(sheetCtx);
                    final result =
                        await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SpendWiseCategoriesScreen(
                            activeTab: 'Expenses'),
                      ),
                    );
                    if (mounted) {
                      _showCreateBudgetSheetWithData(
                        preselectedCategory:
                            result?['title'] ?? selectedCategory,
                        preselectedIconCode:
                            result?['iconCode'] ?? selectedIconCode,
                        prefilledAmount: amountCtrl.text,
                        preselectedPeriod: selectedPeriod,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: backgroundGray,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selectedCategory != null
                            ? primaryGreen.withOpacity(0.4)
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            IconData(selectedIconCode,
                                fontFamily: 'MaterialIcons'),
                            color: primaryGreen,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedCategory ?? 'Tap to select category',
                            style: TextStyle(
                              fontSize: 13,
                              color: selectedCategory != null
                                  ? Colors.black87
                                  : Colors.grey.shade400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            color: Colors.grey.shade400, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text('Budget Limit',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                TextField(
                  controller: amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'e.g. 500',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixText: '\$ ',
                    filled: true,
                    fillColor: backgroundGray,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: primaryGreen.withOpacity(0.4), width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),

                Text('Period',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                Row(
                  children: ['Monthly', 'Weekly'].map((p) {
                    final bool isSelected = selectedPeriod == p;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setSheet(() => selectedPeriod = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin:
                              EdgeInsets.only(right: p == 'Monthly' ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color:
                                isSelected ? primaryGreen : backgroundGray,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? primaryGreen
                                  : Colors.grey.shade200,
                            ),
                          ),
                          child: Text(
                            p,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final double? limit =
                          double.tryParse(amountCtrl.text.trim());

                      if (selectedCategory == null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text('Please select a category'),
                          backgroundColor: Colors.orange.shade400,
                          behavior: SnackBarBehavior.floating,
                        ));
                        return;
                      }
                      if (limit == null || limit <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text('Please enter a valid amount'),
                          backgroundColor: Colors.orange.shade400,
                          behavior: SnackBarBehavior.floating,
                        ));
                        return;
                      }

                      final existing = await _budgetsRef
                          .where('category', isEqualTo: selectedCategory)
                          .get();

                      if (existing.docs.isNotEmpty) {
                        if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                'A budget for "$selectedCategory" already exists.'),
                            backgroundColor: Colors.orange.shade400,
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                        return;
                      }

                      final txSnap = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(_uid)
                          .collection('transactions')
                          .where('type', isEqualTo: 'expense')
                          .where('category', isEqualTo: selectedCategory)
                          .get();

                      double alreadySpent = 0;
                      for (final doc in txSnap.docs) {
                        alreadySpent +=
                            (doc.data()['amount'] as num?)?.toDouble() ??
                                0.0;
                      }

                      await _budgetsRef.add({
                        'category': selectedCategory,
                        'category_icon_code': selectedIconCode,
                        'limit': limit,
                        'spent': alreadySpent,
                        'period': selectedPeriod,
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content:
                              Text('✓ "$selectedCategory" budget created!'),
                          backgroundColor: primaryGreen,
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Create Budget'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Delete budget ─────────────────────────────────────────────────────────
  void _confirmDelete(String budgetId, String category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Budget',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        content: Text(
            'Remove the "$category" budget? Your transactions won\'t be affected.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Cancel', style: TextStyle(color: Colors.grey.shade500)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _budgetsRef.doc(budgetId).delete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Edit budget limit ─────────────────────────────────────────────────────
  void _showEditDialog(String budgetId, String category, double currentLimit) {
    final ctrl =
        TextEditingController(text: currentLimit.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit "$category" Budget',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                color: primaryGreen,
                fontSize: 15)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: '\$ ',
            filled: true,
            fillColor: backgroundGray,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Cancel', style: TextStyle(color: Colors.grey.shade500)),
          ),
          ElevatedButton(
            onPressed: () async {
              final double? newLimit = double.tryParse(ctrl.text.trim());
              if (newLimit == null || newLimit <= 0) return;
              await _budgetsRef.doc(budgetId).update({'limit': newLimit});
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundGray,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header with back button ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 20, 0),
              child: Row(
                children: [
                  // ── Back button ────────────────────────────────────
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
                          size: 16, color: primaryGreen),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BUDGET ANALYSIS',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: primaryGreen,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'Track spending against your limits',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _showCreateBudgetSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: primaryGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text('New Budget',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Budget list ──────────────────────────────────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _budgetsRef
                    .orderBy('createdAt', descending: false)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return Center(
                        child: CircularProgressIndicator(
                            color: primaryGreen));
                  }

                  final budgets = snap.data?.docs ?? [];

                  if (budgets.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.account_balance_wallet_outlined,
                              size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('No budgets yet',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.grey.shade400)),
                          const SizedBox(height: 6),
                          Text('Tap "+ New Budget" to get started',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade400)),
                        ],
                      ),
                    );
                  }

                  double totalLimit = 0;
                  double totalSpent = 0;
                  for (final doc in budgets) {
                    final d = doc.data() as Map<String, dynamic>;
                    totalLimit +=
                        (d['limit'] as num?)?.toDouble() ?? 0.0;
                    totalSpent +=
                        (d['spent'] as num?)?.toDouble() ?? 0.0;
                  }
                  final double totalProgress = totalLimit > 0
                      ? (totalSpent / totalLimit).clamp(0.0, 1.0)
                      : 0;
                  final double remaining = totalLimit - totalSpent;

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    children: [
                      // ── Summary card ─────────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: primaryGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL BUDGET OVERVIEW',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white60,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text('Spent',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.white60)),
                                    Text(
                                      '\$${totalSpent.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    const Text('Total Budget',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.white60)),
                                    Text(
                                      '\$${totalLimit.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: totalProgress,
                                minHeight: 8,
                                backgroundColor:
                                    Colors.white.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  totalProgress >= 1.0
                                      ? Colors.red.shade300
                                      : totalProgress >= 0.8
                                          ? Colors.orange.shade300
                                          : Colors.greenAccent.shade200,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${(totalProgress * 100).toInt()}% used',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  remaining >= 0
                                      ? '\$${remaining.toStringAsFixed(2)} remaining'
                                      : '-\$${remaining.abs().toStringAsFixed(2)} over budget',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: remaining >= 0
                                        ? Colors.white70
                                        : Colors.red.shade200,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text('BY CATEGORY',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 0.8)),
                      const SizedBox(height: 12),

                      ...budgets.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        final String category = d['category'] ?? 'Unknown';
                        final int iconCode =
                            d['category_icon_code'] ?? 0xe532;
                        final double limit =
                            (d['limit'] as num?)?.toDouble() ?? 0.0;
                        final double spent =
                            (d['spent'] as num?)?.toDouble() ?? 0.0;
                        final String period = d['period'] ?? 'Monthly';
                        final double progress = limit > 0
                            ? (spent / limit).clamp(0.0, 1.0)
                            : 0;
                        final bool isOver = spent > limit;
                        final bool isWarning = !isOver && progress >= 0.8;
                        final double leftAmount = limit - spent;
                        final Color barColor = isOver
                            ? Colors.red.shade400
                            : isWarning
                                ? Colors.orange.shade400
                                : primaryGreen;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: isOver
                                ? Border.all(
                                    color: Colors.red.shade200, width: 1.5)
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: barColor.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      IconData(iconCode,
                                          fontFamily: 'MaterialIcons'),
                                      color: barColor,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(category,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14)),
                                        Text(period,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color:
                                                    Colors.grey.shade400)),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showEditDialog(
                                        doc.id, category, limit),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: BoxDecoration(
                                        color:
                                            primaryGreen.withOpacity(0.08),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text('Edit',
                                          style: TextStyle(
                                              color: primaryGreen,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        _confirmDelete(doc.id, category),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text('Delete',
                                          style: TextStyle(
                                              color: Colors.red.shade400,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '\$${spent.toStringAsFixed(2)} spent',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: barColor),
                                  ),
                                  Text(
                                    'of \$${limit.toStringAsFixed(2)}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 7,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(barColor),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${(progress * 100).toInt()}% used',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade400),
                                  ),
                                  Text(
                                    isOver
                                        ? '\$${(spent - limit).toStringAsFixed(2)} over budget!'
                                        : '\$${leftAmount.toStringAsFixed(2)} left',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isOver
                                          ? Colors.red.shade400
                                          : isWarning
                                              ? Colors.orange.shade400
                                              : Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                              if (isOver)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded,
                                          size: 13,
                                          color: Colors.red.shade400),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Over budget by \$${(spent - limit).toStringAsFixed(2)}',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.red.shade400,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                )
                              else if (isWarning)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline,
                                          size: 13,
                                          color: Colors.orange.shade400),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Approaching limit — only \$${leftAmount.toStringAsFixed(2)} left',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.orange.shade400,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
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
    );
  }
}