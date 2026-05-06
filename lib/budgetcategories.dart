import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SpendWiseCategoriesScreen extends StatefulWidget {
  final String activeTab; // 'Expenses' or 'Income'
  const SpendWiseCategoriesScreen({super.key, this.activeTab = 'Expenses'});

  @override
  State<SpendWiseCategoriesScreen> createState() =>
      _SpendWiseCategoriesScreenState();
}

class _SpendWiseCategoriesScreenState
    extends State<SpendWiseCategoriesScreen> {
  final Color primaryDarkGreen = const Color(0xFF0F3826);
  final Color lightGreenAccent = const Color(0xFFE9F0EC);
  final Color backgroundGray = const Color(0xFFF4F6F8);

  late String _activeTab;
  String _selectedCategory = '';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // ── Hardcoded categories ────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _expenseCategories = [
    {'title': 'Housing', 'subtitle': 'RENT & MORTGAGE', 'iconCode': 0xe318},
    {'title': 'Transport', 'subtitle': 'FUEL & TRANSIT', 'iconCode': 0xe531},
    {'title': 'Food', 'subtitle': 'GROCERIES & DINING', 'iconCode': 0xe532},
    {'title': 'Utilities', 'subtitle': 'BILLS & ELECTRIC', 'iconCode': 0xe63f},
    {'title': 'Healthcare', 'subtitle': 'MEDICAL & WELLNESS', 'iconCode': 0xe3f3},
    {'title': 'Entertainment', 'subtitle': 'FUN & LEISURE', 'iconCode': 0xe40c},
    {'title': 'Shopping', 'subtitle': 'CLOTHES & GOODS', 'iconCode': 0xe614},
    {'title': 'Personal', 'subtitle': 'SELF CARE', 'iconCode': 0xe7fd},
    {'title': 'Travel', 'subtitle': 'ADVENTURE & TRIPS', 'iconCode': 0xe195},
    {'title': 'Fitness', 'subtitle': 'SPORT & HEALTH', 'iconCode': 0xe3c4},
    {'title': 'Personal Care', 'subtitle': 'BEAUTY & GROOMING', 'iconCode': 0xe3f8},
    {'title': 'Pets', 'subtitle': 'FOOD & VET', 'iconCode': 0xe539},
    {'title': 'Gifts', 'subtitle': 'GIVING & EVENTS', 'iconCode': 0xe1bc},
    {'title': 'Dining & Cafe', 'subtitle': 'RESTAURANTS & COFFEE', 'iconCode': 0xe532},
    {'title': 'Subscriptions', 'subtitle': 'DIGITAL SERVICES', 'iconCode': 0xe916},
    {'title': 'Education', 'subtitle': 'LEARNING & GROWTH', 'iconCode': 0xe80c},
  ];

  final List<Map<String, dynamic>> _incomeCategories = [
    {'title': 'Salary', 'subtitle': 'MONTHLY PAY', 'iconCode': 0xe8a5},
    {'title': 'Freelance', 'subtitle': 'CONTRACT WORK', 'iconCode': 0xe156},
    {'title': 'Investment', 'subtitle': 'STOCKS & FUNDS', 'iconCode': 0xe6de},
    {'title': 'Business', 'subtitle': 'SELF EMPLOYED', 'iconCode': 0xe0af},
    {'title': 'Gift', 'subtitle': 'RECEIVED GIFTS', 'iconCode': 0xe1bc},
    {'title': 'Rental', 'subtitle': 'PROPERTY INCOME', 'iconCode': 0xe318},
    {'title': 'Bonus', 'subtitle': 'EXTRA PAY', 'iconCode': 0xe8b5},
    {'title': 'Other', 'subtitle': 'MISCELLANEOUS', 'iconCode': 0xe88f},
  ];

  // ── Pickable icons for custom categories ────────────────────────────────────
  final List<Map<String, dynamic>> _availableIcons = [
    {'label': 'Star', 'iconCode': 0xe8b5},
    {'label': 'Wallet', 'iconCode': 0xe62c},
    {'label': 'Tag', 'iconCode': 0xe892},
    {'label': 'Cart', 'iconCode': 0xe614},
    {'label': 'Heart', 'iconCode': 0xe25a},
    {'label': 'School', 'iconCode': 0xe80c},
    {'label': 'Sports', 'iconCode': 0xe3c4},
    {'label': 'Music', 'iconCode': 0xe405},
    {'label': 'Plane', 'iconCode': 0xe195},
    {'label': 'Car', 'iconCode': 0xe531},
    {'label': 'Home', 'iconCode': 0xe318},
    {'label': 'More', 'iconCode': 0xe88f},
  ];

  @override
  void initState() {
    super.initState();
    _activeTab = widget.activeTab;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Firestore helpers ────────────────────────────────────────────────────────

  /// Returns the Firestore stream of custom categories for the current user + tab
  Stream<QuerySnapshot> _customCategoriesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('custom_categories')
        .where('type', isEqualTo: _activeTab == 'Expenses' ? 'expense' : 'income')
        .snapshots();
  }

  /// Saves a new custom category to Firestore
  Future<void> _saveCustomCategory(
      String title, String subtitle, int iconCode) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('custom_categories')
        .add({
      'title': title,
      'subtitle': subtitle.toUpperCase(),
      'iconCode': iconCode,
      'type': _activeTab == 'Expenses' ? 'expense' : 'income',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Add Category bottom sheet ────────────────────────────────────────────────
  void _openAddCategorySheet() {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController subtitleCtrl = TextEditingController();
    int selectedIconCode = _availableIcons[0]['iconCode'] as int;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sheet header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'New Category',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: primaryDarkGreen),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: const Icon(Icons.close, size: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Adding to: $_activeTab',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 20),

                    // Name field
                    const Text('Category name',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'e.g. Side hustle',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: const Color(0xFFF4F6F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Subtitle field
                    const Text('Short label (optional)',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: subtitleCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'e.g. EXTRA INCOME',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        filled: true,
                        fillColor: const Color(0xFFF4F6F8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Icon picker
                    const Text('Pick an icon',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey)),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: _availableIcons.length,
                      itemBuilder: (_, i) {
                        final ic = _availableIcons[i];
                        final code = ic['iconCode'] as int;
                        final bool isChosen = selectedIconCode == code;
                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedIconCode = code),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            decoration: BoxDecoration(
                              color: isChosen
                                  ? lightGreenAccent
                                  : const Color(0xFFF0F2F5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isChosen
                                    ? primaryDarkGreen
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                IconData(code, fontFamily: 'MaterialIcons'),
                                color: primaryDarkGreen,
                                size: 22,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Please enter a category name')),
                            );
                            return;
                          }
                          final subtitle = subtitleCtrl.text.trim().isEmpty
                              ? name.toUpperCase()
                              : subtitleCtrl.text.trim().toUpperCase();

                          await _saveCustomCategory(
                              name, subtitle, selectedIconCode);

                          if (ctx.mounted) Navigator.pop(ctx);

                          // Auto-select the newly created category
                          setState(() => _selectedCategory = name);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryDarkGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          textStyle: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        child: const Text('Save Category'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Confirm selection (searches hardcoded + custom list) ────────────────────
  void _confirmSelection(List<Map<String, dynamic>> allCategories) {
    if (_selectedCategory.isEmpty) return;
    final cat = allCategories.firstWhere(
      (c) => c['title'] == _selectedCategory,
      orElse: () => allCategories.first,
    );
    Navigator.pop(context, {
      'title': cat['title'],
      'iconCode': cat['iconCode'],
    });
  }

  // ── BUILD ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final hardcoded =
        _activeTab == 'Expenses' ? _expenseCategories : _incomeCategories;

    return StreamBuilder<QuerySnapshot>(
      stream: _customCategoriesStream(),
      builder: (context, customSnap) {
        // Convert Firestore docs to the same Map format
        final List<Map<String, dynamic>> customCategories =
            (customSnap.data?.docs ?? []).map((doc) {
          final d = doc.data() as Map<String, dynamic>;
          return {
            'title': d['title'] ?? '',
            'subtitle': d['subtitle'] ?? '',
            'iconCode': d['iconCode'] ?? 0xe88f,
            'isCustom': true,
          };
        }).toList();

        // Merge: hardcoded first, then custom (deduplicated by title)
        final hardcodedTitles = hardcoded.map((c) => c['title']).toSet();
        final uniqueCustom = customCategories
            .where((c) => !hardcodedTitles.contains(c['title']))
            .toList();
        final List<Map<String, dynamic>> allCategories = [
          ...hardcoded,
          ...uniqueCustom,
        ];

        // Apply search filter
        final filtered = _searchQuery.isEmpty
            ? allCategories
            : allCategories
                .where((c) =>
                    (c['title'] as String)
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()) ||
                    (c['subtitle'] as String)
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                .toList();

        return Scaffold(
          backgroundColor: backgroundGray,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  children: [
                    // ── Scrollable body ─────────────────────────────────
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // App bar row
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: const Icon(Icons.arrow_back,
                                      color: Colors.black87),
                                ),
                                const SizedBox(width: 16),
                                Text('Select Category',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: primaryDarkGreen)),
                                const Spacer(),
                                Icon(Icons.search,
                                    color: Colors.grey.shade600, size: 22),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Expenses / Income toggle
                            Row(
                              children: [
                                _buildToggle('Expenses'),
                                const SizedBox(width: 10),
                                _buildToggle('Income'),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Section label
                            Text(
                              _activeTab == 'Expenses'
                                  ? 'TOP EXPENSE CATEGORIES'
                                  : 'INCOME SOURCES',
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade500,
                                  letterSpacing: 0.8),
                            ),
                            const SizedBox(height: 16),

                            // Search bar
                            TextField(
                              controller: _searchController,
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v),
                              decoration: InputDecoration(
                                hintText: 'Search categories...',
                                hintStyle: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 13),
                                prefixIcon: Icon(Icons.search,
                                    color: Colors.grey.shade400, size: 18),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Category grid
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.85,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final cat = filtered[index];
                                final isSelected =
                                    _selectedCategory == cat['title'];
                                final isCustom =
                                    cat['isCustom'] == true;
                                return GestureDetector(
                                  onTap: () => setState(() =>
                                      _selectedCategory = cat['title']),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? primaryDarkGreen
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withOpacity(0.03),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        )
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? lightGreenAccent
                                                    : const Color(
                                                        0xFFF0F2F5),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        8),
                                              ),
                                              child: Icon(
                                                IconData(cat['iconCode'],
                                                    fontFamily:
                                                        'MaterialIcons'),
                                                color: primaryDarkGreen,
                                                size: 26,
                                              ),
                                            ),
                                            // Custom badge
                                            if (isCustom)
                                              Positioned(
                                                top: -4,
                                                right: -4,
                                                child: Container(
                                                  width: 10,
                                                  height: 10,
                                                  decoration: BoxDecoration(
                                                    color: primaryDarkGreen,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                        color: Colors.white,
                                                        width: 1.5),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          cat['title'],
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: primaryDarkGreen,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          cat['subtitle'],
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 8,
                                            color: Colors.grey.shade500,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),

                            // "Can't find it?" card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Can't find it?",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Create a custom category tailored to your spending habits.',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      // ← now calls the sheet
                                      onPressed: _openAddCategorySheet,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryDarkGreen,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                      ),
                                      child: const Text('Add New Category',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),

                    // ── Bottom action buttons ──────────────────────────────
                    Container(
                      color: backgroundGray,
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade200,
                                  foregroundColor: Colors.black87,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8)),
                                ),
                                child: const Text('Cancel',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _selectedCategory.isEmpty
                                    ? null
                                    : () =>
                                        _confirmSelection(allCategories),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryDarkGreen,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor:
                                      Colors.grey.shade300,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8)),
                                ),
                                child: const Text('Select',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildToggle(String label) {
    final isActive = _activeTab == label;
    return GestureDetector(
      onTap: () => setState(() {
        _activeTab = label;
        _selectedCategory = '';
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? primaryDarkGreen : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isActive ? primaryDarkGreen : Colors.grey.shade300),
        ),
        child: Text(label,
            style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ),
    );
  }
}