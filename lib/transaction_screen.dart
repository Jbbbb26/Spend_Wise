import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'budgetcategories.dart'; // ← reuse the same category picker

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

  String _filter = 'All';
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // Direct assign — no setState inside StreamBuilder (fixes blink)
  List<QueryDocumentSnapshot> _latestDocs = [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // ── Export ────────────────────────────────────────────────────────────────
  void _exportToCSV() {
    if (_latestDocs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to export.')),
      );
      return;
    }

    final List<List<dynamic>> rows = [
      ['Date', 'Time', 'Type', 'Category', 'Amount', 'Note', 'Tags'],
    ];

    for (final doc in _latestDocs) {
      final tx = doc.data() as Map<String, dynamic>;
      final Timestamp? ts = tx['timestamp'] as Timestamp?;
      final DateTime? date = ts?.toDate();
      rows.add([
        date != null ? DateFormat('yyyy-MM-dd').format(date) : '',
        date != null ? DateFormat('h:mm a').format(date) : '',
        tx['type'] ?? '',
        tx['category'] ?? '',
        (tx['amount'] as num?)?.toDouble() ?? 0.0,
        tx['note'] ?? '',
        tx['tags'] ?? '',
      ]);
    }

    final String csvData = const ListToCsvConverter().convert(rows);
    final bytes = utf8.encode(csvData);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute(
          'download',
          'spendwise_transactions_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv')
      ..click();
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: const Text('CSV downloaded!'),
          backgroundColor: primaryGreen),
    );
  }

  // ── Delete transaction ────────────────────────────────────────────────────
  Future<void> _deleteTransaction(String docId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('transactions')
        .doc(docId)
        .delete();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction deleted.')),
      );
    }
  }

  // ── Known categories (same lists as budgetcategories.dart) ───────────────
  // Used to validate whether a picked category is "known" or not.
  static const List<String> _knownExpenseCategories = [
    'Housing', 'Transport', 'Food', 'Utilities', 'Healthcare',
    'Entertainment', 'Shopping', 'Personal', 'Travel', 'Fitness',
    'Personal Care', 'Pets', 'Gifts', 'Dining & Cafe',
    'Subscriptions', 'Education',
  ];
  static const List<String> _knownIncomeCategories = [
    'Salary', 'Freelance', 'Investment', 'Business',
    'Gift', 'Rental', 'Bonus', 'Other',
  ];

  bool _isKnownCategory(String category, String type) {
    final list = type == 'expense'
        ? _knownExpenseCategories
        : _knownIncomeCategories;
    return list.any((c) => c.toLowerCase() == category.toLowerCase());
  }

  // ── Edit transaction ──────────────────────────────────────────────────────
  void _editTransaction(String docId, Map<String, dynamic> tx) {
    // Mutable state for the bottom sheet
    String selectedType = tx['type'] as String? ?? 'expense';
    String selectedCategory = tx['category'] as String? ?? '';
    int selectedIconCode = tx['category_icon_code'] as int? ?? 0xe532;
    bool categoryFromPicker = true; // existing tx already has a valid category

    final amountCtrl =
        TextEditingController(text: (tx['amount'] as num?)?.toString() ?? '');
    final noteCtrl =
        TextEditingController(text: tx['note'] as String? ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          final Color accentColor = selectedType == 'expense'
              ? Colors.red.shade400
              : primaryGreen;

          // Whether the current category is in the known list
          final bool isKnown =
              _isKnownCategory(selectedCategory, selectedType);
          // Show warning only if category was set but not recognized
          final bool showUnknownWarning =
              selectedCategory.isNotEmpty && !isKnown;

          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title row ────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.edit_outlined,
                            color: primaryGreen, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Text('Edit Transaction',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: primaryGreen)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Type toggle ──────────────────────────────────────
                  Text('Type',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Row(
                    children: ['income', 'expense'].map((type) {
                      final bool sel = selectedType == type;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedType = type;
                            // Reset category when type changes
                            selectedCategory = '';
                            selectedIconCode = 0xe532;
                            categoryFromPicker = false;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel
                                ? (type == 'income'
                                    ? primaryGreen
                                    : Colors.red.shade400)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            type[0].toUpperCase() + type.substring(1),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color:
                                  sel ? Colors.white : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // ── Category picker button ───────────────────────────
                  Text('Category',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      // Close the bottom sheet, open the category screen,
                      // then re-open the edit sheet with the result.
                      Navigator.pop(ctx);
                      final activeTab = selectedType == 'expense'
                          ? 'Expenses'
                          : 'Income';
                      final result =
                          await Navigator.push<Map<String, dynamic>>(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  SpendWiseCategoriesScreen(
                                      activeTab: activeTab),
                          transitionsBuilder: (context, animation,
                              secondaryAnimation, child) {
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
                          transitionDuration:
                              const Duration(milliseconds: 350),
                        ),
                      );

                      if (!mounted) return;

                      // Re-open the edit sheet, preserving all current data
                      _editTransactionWithData(
                        docId: docId,
                        tx: tx,
                        initialType: selectedType,
                        initialCategory:
                            result?['title'] ?? selectedCategory,
                        initialIconCode:
                            result?['iconCode'] ?? selectedIconCode,
                        initialAmount: amountCtrl.text,
                        initialNote: noteCtrl.text,
                        categoryFromPicker: result != null,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: backgroundGray,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selectedCategory.isNotEmpty
                              ? accentColor.withOpacity(0.4)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              IconData(selectedIconCode,
                                  fontFamily: 'MaterialIcons'),
                              color: accentColor,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedCategory.isNotEmpty
                                  ? selectedCategory
                                  : 'Tap to select a category',
                              style: TextStyle(
                                fontSize: 13,
                                color: selectedCategory.isNotEmpty
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

                  // ── Unknown category warning ──────────────────────────
                  if (showUnknownWarning) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 14, color: Colors.orange.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '"$selectedCategory" is not in your category list. '
                              'You can still save, or pick from the list above.',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Known category badge ─────────────────────────────
                  if (selectedCategory.isNotEmpty && isKnown) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryGreen.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 13, color: primaryGreen),
                          const SizedBox(width: 6),
                          Text(
                            'Category found in your list',
                            style: TextStyle(
                                fontSize: 11,
                                color: primaryGreen,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ── Amount ───────────────────────────────────────────
                  _modalField('Amount', amountCtrl,
                      hint: '0.00',
                      keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true)),
                  const SizedBox(height: 12),

                  // ── Note ─────────────────────────────────────────────
                  _modalField('Note (optional)', noteCtrl,
                      hint: 'Add a note…'),
                  const SizedBox(height: 24),

                  // ── Save button ──────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final double? amount =
                            double.tryParse(amountCtrl.text.trim());
                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Please enter a valid amount.')),
                          );
                          return;
                        }
                        if (selectedCategory.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please select a category.')),
                          );
                          return;
                        }

                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(_uid)
                            .collection('transactions')
                            .doc(docId)
                            .update({
                          'type': selectedType,
                          'category': selectedCategory,
                          'category_icon_code': selectedIconCode,
                          'amount': amount,
                          'note': noteCtrl.text.trim(),
                        });

                        if (mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Transaction updated!'),
                              backgroundColor: primaryGreen,
                            ),
                          );
                        }
                      },
                      child: const Text('Save Changes',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  /// Re-opens the edit sheet after returning from the category picker,
  /// preserving all previously filled fields.
  void _editTransactionWithData({
    required String docId,
    required Map<String, dynamic> tx,
    required String initialType,
    required String initialCategory,
    required int initialIconCode,
    required String initialAmount,
    required String initialNote,
    required bool categoryFromPicker,
  }) {
    String selectedType = initialType;
    String selectedCategory = initialCategory;
    int selectedIconCode = initialIconCode;

    final amountCtrl = TextEditingController(text: initialAmount);
    final noteCtrl = TextEditingController(text: initialNote);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          final Color accentColor = selectedType == 'expense'
              ? Colors.red.shade400
              : primaryGreen;
          final bool isKnown =
              _isKnownCategory(selectedCategory, selectedType);
          final bool showUnknownWarning =
              selectedCategory.isNotEmpty && !isKnown;

          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.edit_outlined,
                            color: primaryGreen, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Text('Edit Transaction',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: primaryGreen)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Type toggle
                  Text('Type',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Row(
                    children: ['income', 'expense'].map((type) {
                      final bool sel = selectedType == type;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedType = type;
                            selectedCategory = '';
                            selectedIconCode = 0xe532;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel
                                ? (type == 'income'
                                    ? primaryGreen
                                    : Colors.red.shade400)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            type[0].toUpperCase() + type.substring(1),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: sel
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Category picker button
                  Text('Category',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(ctx);
                      final activeTab = selectedType == 'expense'
                          ? 'Expenses'
                          : 'Income';
                      final result =
                          await Navigator.push<Map<String, dynamic>>(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation,
                                  secondaryAnimation) =>
                              SpendWiseCategoriesScreen(
                                  activeTab: activeTab),
                          transitionsBuilder: (context, animation,
                              secondaryAnimation, child) {
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
                          transitionDuration:
                              const Duration(milliseconds: 350),
                        ),
                      );
                      if (!mounted) return;
                      _editTransactionWithData(
                        docId: docId,
                        tx: tx,
                        initialType: selectedType,
                        initialCategory:
                            result?['title'] ?? selectedCategory,
                        initialIconCode:
                            result?['iconCode'] ?? selectedIconCode,
                        initialAmount: amountCtrl.text,
                        initialNote: noteCtrl.text,
                        categoryFromPicker: result != null,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: backgroundGray,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selectedCategory.isNotEmpty
                              ? accentColor.withOpacity(0.4)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              IconData(selectedIconCode,
                                  fontFamily: 'MaterialIcons'),
                              color: accentColor,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              selectedCategory.isNotEmpty
                                  ? selectedCategory
                                  : 'Tap to select a category',
                              style: TextStyle(
                                fontSize: 13,
                                color: selectedCategory.isNotEmpty
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

                  // Unknown category warning
                  if (showUnknownWarning) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 14, color: Colors.orange.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '"$selectedCategory" is not in your category list. '
                              'You can still save, or pick from the list above.',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Known category badge
                  if (selectedCategory.isNotEmpty && isKnown) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryGreen.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 13, color: primaryGreen),
                          const SizedBox(width: 6),
                          Text(
                            'Category found in your list',
                            style: TextStyle(
                                fontSize: 11,
                                color: primaryGreen,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  _modalField('Amount', amountCtrl,
                      hint: '0.00',
                      keyboardType:
                          const TextInputType.numberWithOptions(
                              decimal: true)),
                  const SizedBox(height: 12),
                  _modalField('Note (optional)', noteCtrl,
                      hint: 'Add a note…'),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final double? amount =
                            double.tryParse(amountCtrl.text.trim());
                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Please enter a valid amount.')),
                          );
                          return;
                        }
                        if (selectedCategory.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Please select a category.')),
                          );
                          return;
                        }

                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(_uid)
                            .collection('transactions')
                            .doc(docId)
                            .update({
                          'type': selectedType,
                          'category': selectedCategory,
                          'category_icon_code': selectedIconCode,
                          'amount': amount,
                          'note': noteCtrl.text.trim(),
                        });

                        if (mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  const Text('Transaction updated!'),
                              backgroundColor: primaryGreen,
                            ),
                          );
                        }
                      },
                      child: const Text('Save Changes',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _modalField(String label, TextEditingController ctrl,
      {String hint = '', TextInputType? keyboardType}) {
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
          controller: ctrl,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryGreen),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
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
        label =
            'YESTERDAY — ${DateFormat('MMM d').format(date).toUpperCase()}';
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
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
                  IconButton(
                    tooltip: 'Export to CSV',
                    icon: Icon(Icons.download_rounded,
                        color: primaryGreen, size: 26),
                    onPressed: _exportToCSV,
                  ),
                  const Icon(Icons.settings_outlined, size: 26),
                ],
              ),
            ),
            const SizedBox(height: 16),

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
                  final filtered = allDocs.where((doc) {
                    final tx = doc.data() as Map<String, dynamic>;
                    return _matchesFilter(tx) && _matchesSearch(tx);
                  }).toList();

                  _latestDocs = filtered;

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
                    itemCount: dateKeys.length + 1,
                    itemBuilder: (context, idx) {
                      if (idx == dateKeys.length) {
                        return Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 24),
                          child: Row(
                            children: [
                              Expanded(
                                  child: Divider(
                                      color: Colors.grey.shade300)),
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
                                  child: Divider(
                                      color: Colors.grey.shade300)),
                            ],
                          ),
                        );
                      }

                      final dateLabel = dateKeys[idx];
                      final txList = grouped[dateLabel]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 8, bottom: 10),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(dateLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade500,
                                      letterSpacing: 0.5,
                                    )),
                                Text(
                                  '${txList.length} item${txList.length == 1 ? '' : 's'}',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade400),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              itemCount: txList.length,
                              separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  indent: 68,
                                  color: Colors.grey.shade100),
                              itemBuilder: (context, txIdx) {
                                final doc = txList[txIdx];
                                final tx =
                                    doc.data() as Map<String, dynamic>;
                                return _buildTransactionTile(
                                    doc.id, tx);
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

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 1,
        onTap: (index) {
          if (index == 0)
            Navigator.pushReplacementNamed(context, '/overview');
          if (index == 2)
            Navigator.pushReplacementNamed(context, '/budgets');
          if (index == 3)
            Navigator.pushReplacementNamed(context, '/tasks');
          if (index == 4)
            Navigator.pushReplacementNamed(context, '/profile');
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

  // ── Transaction tile ──────────────────────────────────────────────────────
  Widget _buildTransactionTile(String docId, Map<String, dynamic> tx) {
    final bool isExpense = tx['type'] == 'expense';
    final double amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;
    final String category = tx['category'] ?? 'Unknown';
    final String note = tx['note'] as String? ?? '';
    final int iconCode = tx['category_icon_code'] ?? 0xe532;
    final Timestamp? ts = tx['timestamp'] as Timestamp?;
    final String timeStr =
        ts != null ? DateFormat('h:mm a').format(ts.toDate()) : '';

    final String subtitle = note.isNotEmpty
        ? note
        : isExpense
            ? 'Expense • $timeStr'
            : 'Income • $timeStr';

    return Dismissible(
      key: Key(docId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline,
            color: Colors.white, size: 24),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Delete Transaction',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            content: const Text(
                'Are you sure you want to delete this transaction?',
                style: TextStyle(fontSize: 13)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel',
                    style: TextStyle(color: Colors.grey.shade600)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => _deleteTransaction(docId),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Text(
              '${isExpense ? '-' : '+'}\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isExpense ? Colors.red.shade400 : primaryGreen,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _editTransaction(docId, tx),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.edit_outlined,
                    color: primaryGreen, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}