import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SpendWiseTasksScreen extends StatefulWidget {
  const SpendWiseTasksScreen({super.key});

  @override
  State<SpendWiseTasksScreen> createState() => _SpendWiseTasksScreenState();
}

class _SpendWiseTasksScreenState extends State<SpendWiseTasksScreen> {
  final Color primaryGreen = const Color(0xFF0F3826);
  final Color backgroundGray = const Color(0xFFF8F9FA);

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference _groupsRef() => FirebaseFirestore.instance
      .collection('users')
      .doc(_uid)
      .collection('task_groups');

  CollectionReference _itemsRef(String groupId) =>
      _groupsRef().doc(groupId).collection('items');

  CollectionReference get _billsRef => FirebaseFirestore.instance
      .collection('users')
      .doc(_uid)
      .collection('monthly_bills');

  // ── Add group dialog ──────────────────────────────────────────────────────
  void _showAddGroupDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('New Task Group',
            style: TextStyle(
                fontWeight: FontWeight.w900,
                color: primaryGreen,
                fontSize: 16)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'e.g. Monthly Goals',
            hintStyle: TextStyle(color: Colors.grey.shade400),
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
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              await _groupsRef().add({
                'name': name,
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Create',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Delete group ──────────────────────────────────────────────────────────
  void _confirmDeleteGroup(String groupId, String groupName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Group',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        content: Text(
            'Delete "$groupName" and all its tasks? This cannot be undone.',
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
              final items = await _itemsRef(groupId).get();
              for (final doc in items.docs) {
                await doc.reference.delete();
              }
              await _groupsRef().doc(groupId).delete();
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

  // ── Add task item ─────────────────────────────────────────────────────────
  void _showAddItemDialog(String groupId) {
    final ctrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Text('Add Task',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: primaryGreen,
                  fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'e.g. Review monthly budget',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: backgroundGray,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: primaryGreen,
                          onPrimary: Colors.white,
                          surface: Colors.white,
                          onSurface: Colors.black87,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setModalState(() => selectedDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: backgroundGray,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 15, color: primaryGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isToday(selectedDate)
                              ? 'Today — ${DateFormat('MMM d, yyyy').format(selectedDate)}'
                              : DateFormat('MMM d, yyyy')
                                  .format(selectedDate),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _isToday(selectedDate)
                                ? Colors.grey.shade600
                                : primaryGreen,
                          ),
                        ),
                      ),
                      Icon(Icons.edit_calendar_outlined,
                          size: 14, color: Colors.grey.shade400),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: TextStyle(color: Colors.grey.shade500)),
            ),
            ElevatedButton(
              onPressed: () async {
                final text = ctrl.text.trim();
                if (text.isEmpty) return;
                final now = DateTime.now();
                final taskDateTime = DateTime(selectedDate.year,
                    selectedDate.month, selectedDate.day, now.hour,
                    now.minute, now.second);
                await _itemsRef(groupId).add({
                  'text': text,
                  'done': false,
                  'createdAt': FieldValue.serverTimestamp(),
                  'taskDate': Timestamp.fromDate(taskDateTime),
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Add',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Add monthly bill ──────────────────────────────────────────────────────
  void _showAddBillSheet() {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    int dueDayOfMonth = 1;

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
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Add Monthly Bill',
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

                // Bill name
                Text('Bill Name',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'e.g. Electricity, Rent, Netflix',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    filled: true,
                    fillColor: backgroundGray,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 14),

                // Amount
                Text('Amount Due',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: InputDecoration(
                    hintText: 'e.g. 150.00',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixText: '\$ ',
                    filled: true,
                    fillColor: backgroundGray,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                  ),
                ),
                const SizedBox(height: 14),

                // Due day
                Text('Due Day of Month',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: backgroundGray,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_outlined,
                          size: 16, color: primaryGreen),
                      const SizedBox(width: 10),
                      Text('Day ',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600)),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: primaryGreen,
                            thumbColor: primaryGreen,
                            inactiveTrackColor:
                                Colors.grey.shade300,
                            overlayColor:
                                primaryGreen.withOpacity(0.1),
                          ),
                          child: Slider(
                            value: dueDayOfMonth.toDouble(),
                            min: 1,
                            max: 31,
                            divisions: 30,
                            onChanged: (v) => setSheet(
                                () => dueDayOfMonth = v.toInt()),
                          ),
                        ),
                      ),
                      Container(
                        width: 36,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryGreen,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('$dueDayOfMonth',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      final double? amount =
                          double.tryParse(amountCtrl.text.trim());
                      if (name.isEmpty || amount == null || amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text(
                              'Please fill in name and amount'),
                          backgroundColor: Colors.orange.shade400,
                          behavior: SnackBarBehavior.floating,
                        ));
                        return;
                      }
                      await _billsRef.add({
                        'name': name,
                        'amount': amount,
                        'dueDay': dueDayOfMonth,
                        'paid': false,
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
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
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('Add Bill'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Future<void> _showBackdateModal(
      String groupId, String itemId, DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'SELECT TASK DATE',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: primaryGreen,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black87,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final now = DateTime.now();
      final updated = DateTime(
          picked.year, picked.month, picked.day, now.hour, now.minute);
      await _itemsRef(groupId)
          .doc(itemId)
          .update({'taskDate': Timestamp.fromDate(updated)});
    }
  }

  Future<void> _toggleItem(
      String groupId, String itemId, bool current) async {
    await _itemsRef(groupId).doc(itemId).update({'done': !current});
  }

  Future<void> _deleteItem(String groupId, String itemId) async {
    await _itemsRef(groupId).doc(itemId).delete();
  }

  Future<void> _toggleBillPaid(String billId, bool current) async {
    await _billsRef.doc(billId).update({'paid': !current});
  }

  Future<void> _deleteBill(String billId) async {
    await _billsRef.doc(billId).delete();
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
            // ── Header with back button ──────────────────────────────────
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
                          size: 16, color: primaryGreen),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MY TASKS',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: primaryGreen,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          'Track your financial goals and to-dos',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _showAddGroupDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: primaryGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 15),
                          SizedBox(width: 4),
                          Text('New Group',
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

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                children: [
                  // ── Monthly Bills section ────────────────────────────
                  _buildMonthlyBillsSection(),
                  const SizedBox(height: 24),

                  // ── Task Groups section ──────────────────────────────
                  _buildTaskGroupsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Monthly Bills Section ─────────────────────────────────────────────────
  Widget _buildMonthlyBillsSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .snapshots(),
      builder: (context, userSnap) {
        final userData =
            userSnap.data?.data() as Map<String, dynamic>? ?? {};
        final double balance =
            (userData['balance'] as num?)?.toDouble() ?? 0.0;

        return StreamBuilder<QuerySnapshot>(
          stream: _billsRef
              .orderBy('dueDay', descending: false)
              .snapshots(),
          builder: (context, snap) {
            final bills = snap.data?.docs ?? [];
            final int total = bills.length;
            final int paid = bills
                .where((d) =>
                    (d.data() as Map<String, dynamic>)['paid'] == true)
                .length;
            final double totalDue = bills.fold(0.0, (sum, d) {
              final data = d.data() as Map<String, dynamic>;
              return sum +
                  ((data['amount'] as num?)?.toDouble() ?? 0.0);
            });
            final double paidAmount = bills.fold(0.0, (sum, d) {
              final data = d.data() as Map<String, dynamic>;
              if (data['paid'] == true) {
                return sum +
                    ((data['amount'] as num?)?.toDouble() ?? 0.0);
              }
              return sum;
            });
            final double progress =
                totalDue > 0 ? (paidAmount / totalDue).clamp(0.0, 1.0) : 0;
            final bool allPaid = total > 0 && paid == total;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                              Icons.receipt_long_outlined,
                              size: 16,
                              color: primaryGreen),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text('MONTHLY BILLS',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      color: primaryGreen)),
                              Text(
                                  DateFormat('MMMM yyyy')
                                      .format(DateTime.now()),
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade400)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _showAddBillSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: primaryGreen,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.add,
                                    color: Colors.white, size: 13),
                                SizedBox(width: 3),
                                Text('Add Bill',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (total > 0) ...[
                    // Progress summary
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$paid / $total bills paid',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: allPaid
                                        ? primaryGreen
                                        : Colors.grey.shade600),
                              ),
                              Text(
                                '\$${paidAmount.toStringAsFixed(2)} / \$${totalDue.toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: Colors.grey.shade200,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(
                                allPaid
                                    ? primaryGreen
                                    : primaryGreen.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Balance affordability indicator
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: Builder(builder: (_) {
                        final double unpaidTotal = totalDue - paidAmount;
                        final bool canAfford = balance >= unpaidTotal;
                        if (unpaidTotal <= 0) return const SizedBox();
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: canAfford
                                ? const Color(0xFFC8F6E0)
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                canAfford
                                    ? Icons.check_circle_outline
                                    : Icons.warning_amber_rounded,
                                size: 14,
                                color: canAfford
                                    ? primaryGreen
                                    : Colors.red.shade400,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  canAfford
                                      ? 'You can afford remaining bills — Balance: \$${balance.toStringAsFixed(2)}'
                                      : 'Insufficient balance for remaining \$${unpaidTotal.toStringAsFixed(2)} in bills — Balance: \$${balance.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: canAfford
                                        ? primaryGreen
                                        : Colors.red.shade400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),

                    // Bill items
                    ...bills.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final String name = d['name'] ?? 'Bill';
                      final double amount =
                          (d['amount'] as num?)?.toDouble() ?? 0.0;
                      final int dueDay = d['dueDay'] ?? 1;
                      final bool isPaid = d['paid'] == true;
                      final bool canAffordThis = balance >= amount;

                      return Dismissible(
                        key: Key(doc.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          color: Colors.red.shade50,
                          child: Icon(Icons.delete_outline,
                              color: Colors.red.shade400, size: 20),
                        ),
                        onDismissed: (_) => _deleteBill(doc.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              // Paid checkbox
                              GestureDetector(
                                onTap: () =>
                                    _toggleBillPaid(doc.id, isPaid),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: isPaid
                                        ? primaryGreen
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isPaid
                                          ? primaryGreen
                                          : Colors.grey.shade400,
                                      width: 2,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(6),
                                  ),
                                  child: isPaid
                                      ? const Icon(Icons.check,
                                          color: Colors.white, size: 13)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isPaid
                                            ? Colors.grey.shade400
                                            : Colors.black87,
                                        decoration: isPaid
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                      ),
                                    ),
                                    Text(
                                      'Due: Day $dueDay of the month',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade400),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '\$${amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isPaid
                                          ? Colors.grey.shade400
                                          : primaryGreen,
                                    ),
                                  ),
                                  if (!isPaid)
                                    Container(
                                      margin:
                                          const EdgeInsets.only(top: 2),
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: canAffordThis
                                            ? const Color(0xFFC8F6E0)
                                            : Colors.red.shade50,
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        canAffordThis
                                            ? 'Can pay'
                                            : 'Low funds',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: canAffordThis
                                              ? primaryGreen
                                              : Colors.red.shade400,
                                        ),
                                      ),
                                    ),
                                  if (isPaid)
                                    Container(
                                      margin:
                                          const EdgeInsets.only(top: 2),
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: primaryGreen
                                            .withOpacity(0.08),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '✓ Paid',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: primaryGreen,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    // All paid banner
                    if (allPaid)
                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: primaryGreen.withOpacity(0.08),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.celebration_outlined,
                                size: 14, color: primaryGreen),
                            const SizedBox(width: 6),
                            Text(
                              'All bills paid this month!',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: primaryGreen),
                            ),
                          ],
                        ),
                      ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                      child: Text(
                        'No bills yet — tap "Add Bill" to track monthly payments.',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Task Groups Section ───────────────────────────────────────────────────
  Widget _buildTaskGroupsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _groupsRef()
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
              child: CircularProgressIndicator(color: primaryGreen));
        }

        final groups = snap.data?.docs ?? [];

        if (groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.checklist_rounded,
                    size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 10),
                Text('No task groups yet',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.grey.shade400)),
                const SizedBox(height: 4),
                Text('Tap "+ New Group" to get started',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade400)),
              ],
            ),
          );
        }

        return Column(
          children: groups.map((group) {
            final groupId = group.id;
            final groupName =
                (group.data() as Map<String, dynamic>)['name']
                        as String? ??
                    'Untitled';
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _TaskGroupCard(
                groupId: groupId,
                groupName: groupName,
                primaryGreen: primaryGreen,
                backgroundGray: backgroundGray,
                itemsRef: _itemsRef(groupId),
                onDelete: () => _confirmDeleteGroup(groupId, groupName),
                onAddItem: () => _showAddItemDialog(groupId),
                onToggle: (itemId, current) =>
                    _toggleItem(groupId, itemId, current),
                onDeleteItem: (itemId) => _deleteItem(groupId, itemId),
                onBackdate: (itemId, current) =>
                    _showBackdateModal(groupId, itemId, current),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ── Task Group Card ───────────────────────────────────────────────────────────
class _TaskGroupCard extends StatelessWidget {
  final String groupId;
  final String groupName;
  final Color primaryGreen;
  final Color backgroundGray;
  final CollectionReference itemsRef;
  final VoidCallback onDelete;
  final VoidCallback onAddItem;
  final Future<void> Function(String itemId, bool current) onToggle;
  final Future<void> Function(String itemId) onDeleteItem;
  final Future<void> Function(String itemId, DateTime current) onBackdate;

  const _TaskGroupCard({
    required this.groupId,
    required this.groupName,
    required this.primaryGreen,
    required this.backgroundGray,
    required this.itemsRef,
    required this.onDelete,
    required this.onAddItem,
    required this.onToggle,
    required this.onDeleteItem,
    required this.onBackdate,
  });

  String _formatTaskDate(Timestamp? ts) {
    if (ts == null) return '';
    final date = ts.toDate();
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    if (isToday) return 'Today';
    return DateFormat('MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: itemsRef.orderBy('createdAt', descending: false).snapshots(),
      builder: (context, snap) {
        final items = snap.data?.docs ?? [];
        final int total = items.length;
        final int done = items
            .where((d) =>
                (d.data() as Map<String, dynamic>)['done'] == true)
            .length;
        final double progress = total == 0 ? 0 : done / total;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final allDone = total > 0 && done == total;
                        for (final doc in items) {
                          await doc.reference
                              .update({'done': !allDone});
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: (total > 0 && done == total)
                              ? primaryGreen
                              : Colors.transparent,
                          border: Border.all(
                            color: (total > 0 && done == total)
                                ? primaryGreen
                                : Colors.grey.shade400,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: (total > 0 && done == total)
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 13)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(groupName,
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: primaryGreen)),
                    ),
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(6),
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
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${(progress * 100).toInt()}%',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: progress == 1.0
                                    ? primaryGreen
                                    : Colors.grey.shade500)),
                        Text('$done / $total tasks',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade400)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress == 1.0
                              ? primaryGreen
                              : primaryGreen.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (snap.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2))),
                )
              else if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text('No tasks yet — add one below.',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                          fontStyle: FontStyle.italic)),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, idx) {
                    final doc = items[idx];
                    final d = doc.data() as Map<String, dynamic>;
                    final bool isDone = d['done'] == true;
                    final String text = d['text'] as String? ?? '';
                    final Timestamp? taskDate =
                        d['taskDate'] as Timestamp?;
                    final String dateLabel = _formatTaskDate(taskDate);

                    return Dismissible(
                      key: Key(doc.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        color: Colors.red.shade50,
                        child: Icon(Icons.delete_outline,
                            color: Colors.red.shade400, size: 20),
                      ),
                      onDismissed: (_) => onDeleteItem(doc.id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: GestureDetector(
                                onTap: () => onToggle(doc.id, isDone),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: isDone
                                        ? primaryGreen
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isDone
                                          ? primaryGreen
                                          : Colors.grey.shade400,
                                      width: 1.5,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(4),
                                  ),
                                  child: isDone
                                      ? const Icon(Icons.check,
                                          color: Colors.white, size: 11)
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  AnimatedDefaultTextStyle(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDone
                                          ? Colors.grey.shade400
                                          : Colors.black87,
                                      decoration: isDone
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                    ),
                                    child: Text(text),
                                  ),
                                  if (dateLabel.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(dateLabel,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: dateLabel == 'Today'
                                              ? Colors.grey.shade400
                                              : primaryGreen,
                                          fontWeight: FontWeight.w600,
                                        )),
                                  ],
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => onBackdate(doc.id,
                                  taskDate?.toDate() ?? DateTime.now()),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    left: 8, top: 2),
                                child: Icon(
                                    Icons.edit_calendar_outlined,
                                    size: 15,
                                    color: Colors.grey.shade400),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: GestureDetector(
                  onTap: onAddItem,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: backgroundGray,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add,
                            size: 15, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Text('Add an item',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),

              if (total > 0 && done == total)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.08),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.celebration_outlined,
                          size: 14, color: primaryGreen),
                      const SizedBox(width: 6),
                      Text('All tasks complete!',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryGreen)),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}