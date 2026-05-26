import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────

class Bill {
  final String id;
  final double amount;
  final String paidBy;
  final List<String> splitBetween;
  final String category;

  const Bill({
    required this.id,
    required this.amount,
    required this.paidBy,
    required this.splitBetween,
    required this.category,
  });

  factory Bill.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Bill(
      id:           doc.id,
      amount:       (d['amount'] as num).toDouble(),
      paidBy:       d['paidBy'] as String? ?? '',
      splitBetween: List<String>.from(d['splitBetween'] ?? []),
      category:     (d['categories'] as String? ?? 'other').toLowerCase(),
    );
  }
}

// Simple model to hold a member's id + display name
class _Member {
  final String uid;
  final String name;
  const _Member({required this.uid, required this.name});
}

// ─────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────

IconData _iconForCategory(String cat) {
  switch (cat) {
    case 'shopping':      return Icons.shopping_bag_outlined;
    case 'groceries':     return Icons.shopping_cart_outlined;
    case 'food':          return Icons.restaurant_outlined;
    case 'utilities':     return Icons.bolt_outlined;
    case 'rent':          return Icons.home_outlined;
    case 'transport':     return Icons.directions_car_outlined;
    case 'entertainment': return Icons.movie_outlined;
    default:              return Icons.receipt_long_outlined;
  }
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

// ─────────────────────────────────────────────
// THEME CONSTANTS
// ─────────────────────────────────────────────

const _bg         = Color(0xFF0D0D1A);
const _card       = Color(0xFF1A1A2E);
const _cardBorder = Color(0xFF2E2E50);
const _pink       = Color(0xFFE040FB);
const _pinkDark   = Color(0xFF9C27B0);
const _textPri    = Color(0xFFFFFFFF);
const _textSec    = Color(0xFFB0ADCC);
const _pillBg     = Color(0xFF23233A);

// ─────────────────────────────────────────────
// BILLS SCREEN
// ─────────────────────────────────────────────

class BillsScreen extends StatefulWidget {
  final String houseId;
  final String currentUserId;

  const BillsScreen({
    super.key,
    required this.houseId,
    required this.currentUserId, required String houseName,
  });

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  final _db = FirebaseFirestore.instance;

  // ── Firestore stream ───────────────────────

  Stream<List<Bill>> get _billsStream => _db
      .collection('bills')
      .where('houseId', isEqualTo: widget.houseId)
      .snapshots()
      .map((s) => s.docs.map(Bill.fromDoc).toList());

  // ── Summary calculation ────────────────────

  (double, double) _summarise(List<Bill> bills) {
    double youOwe    = 0;
    double owedToYou = 0;
    for (final b in bills) {
      if (b.splitBetween.isEmpty) continue;
      final share = b.amount / b.splitBetween.length;
      if (b.paidBy == widget.currentUserId) {
        owedToYou += b.amount - share;
      } else if (b.splitBetween.contains(widget.currentUserId)) {
        youOwe += share;
      }
    }
    return (youOwe, owedToYou);
  }

  // ── User name cache ────────────────────────

  final Map<String, String> _nameCache = {};

  Future<String> _userName(String uid) async {
    if (_nameCache.containsKey(uid)) return _nameCache[uid]!;
    try {
      final doc  = await _db.collection('users').doc(uid).get();
      final name = (doc.data()?['userName'] as String?) ?? 'Unknown';
      _nameCache[uid] = name;
      return name;
    } catch (_) {
      return 'Unknown';
    }
  }

  // ── Open sheet ─────────────────────────────

  void _openNewBillSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewBillSheet(
        houseId:       widget.houseId,
        currentUserId: widget.currentUserId,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: StreamBuilder<List<Bill>>(
          stream: _billsStream,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: _pink));
            }
            if (snap.hasError) {
              return Center(
                child: Text('Error: ${snap.error}',
                    style: const TextStyle(color: _textSec)),
              );
            }

            final bills               = snap.data ?? [];
            final (youOwe, owedToYou) = _summarise(bills);

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: const Text(
                      'Bills',
                      style: TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w700,
                        color: _textPri, letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            label: 'You owe',
                            amount: youOwe,
                            gradientColors: const [
                              Color(0xFF6A1B9A), Color(0xFF4A148C), Color(0xFF2A0A5E),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _SummaryCard(
                            label: 'Owe you',
                            amount: owedToYou,
                            gradientColors: const [
                              Color(0xFF00695C), Color(0xFF004D40), Color(0xFF002B26),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                    child: const Text(
                      'Pending bills',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _textPri),
                    ),
                  ),
                ),

                if (bills.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                      child: Center(
                        child: Column(
                          children: const [
                            Icon(Icons.receipt_long_outlined, color: _textSec, size: 48),
                            SizedBox(height: 12),
                            Text('No pending bills 🎉',
                                style: TextStyle(color: _textSec, fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: _BillCard(bill: bills[i], getUserName: _userName),
                      ),
                      childCount: bills.length,
                    ),
                  ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    child: _NewBillButton(onTap: _openNewBillSheet),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SUMMARY CARD
// ─────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final List<Color> gradientColors;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        border: Border.all(color: _cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.35),
            blurRadius: 20, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500, color: _textSec)),
          const SizedBox(height: 8),
          Text('\$${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 32, fontWeight: FontWeight.w800,
                  color: _textPri, letterSpacing: -1)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BILL CARD
// ─────────────────────────────────────────────

class _BillCard extends StatelessWidget {
  final Bill bill;
  final Future<String> Function(String uid) getUserName;

  const _BillCard({required this.bill, required this.getUserName});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder, width: 1),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: _pillBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _cardBorder),
                  ),
                  child: Icon(_iconForCategory(bill.category), color: _textPri, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_capitalize(bill.category),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600, color: _textPri)),
                ),
                Text('\$${bill.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: _textPri)),
              ],
            ),
          ),
          Divider(height: 1, color: _cardBorder),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Row(
              children: [
                const Text('Paid by',
                    style: TextStyle(fontSize: 13, color: _textSec)),
                const SizedBox(width: 8),
                FutureBuilder<String>(
                  future: getUserName(bill.paidBy),
                  builder: (ctx, snap) {
                    final name = snap.data ?? '…';
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 13,
                          backgroundColor: _pinkDark,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700, color: _textPri),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(name,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600, color: _textPri)),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// NEW BILL BUTTON
// ─────────────────────────────────────────────

class _NewBillButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NewBillButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
        decoration: BoxDecoration(
          color: _pillBg,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: _cardBorder, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.add_circle_outline, color: _textPri, size: 22),
            SizedBox(width: 10),
            Text('New bill',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: _textPri)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// NEW BILL BOTTOM SHEET
// ─────────────────────────────────────────────

class _NewBillSheet extends StatefulWidget {
  final String houseId;
  final String currentUserId;

  const _NewBillSheet({
    required this.houseId,
    required this.currentUserId,
  });

  @override
  State<_NewBillSheet> createState() => _NewBillSheetState();
}

class _NewBillSheetState extends State<_NewBillSheet> {
  final _db         = FirebaseFirestore.instance;
  final _amountCtrl = TextEditingController();

  String         _selectedCat = 'groceries';
  bool           _loading     = false;

  // Members loaded from Firestore
  List<_Member>  _members     = [];
  bool           _loadingMembers = true;
  String?        _membersError;

  // Who paid — defaults to current user once members load
  String?        _paidByUid;

  // Which members split this bill — defaults to all
  late Set<String> _splitBetween;

  final _categories = [
    'groceries', 'shopping', 'food', 'utilities',
    'rent', 'transport', 'entertainment', 'other',
  ];

  // ── Load housemates on open ────────────────

  @override
  void initState() {
    super.initState();
    _splitBetween = {};
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      // 1. Get the members list from the house doc
      final houseDoc = await _db
          .collection('houses')
          .doc(widget.houseId)
          .get();

      final memberIds = List<String>.from(
          houseDoc.data()?['members'] ?? []);

      if (memberIds.isEmpty) {
        // Fallback: just include the current user
        memberIds.add(widget.currentUserId);
      }

      // 2. Fetch each user's name from /users/{uid}
      final futures = memberIds.map((uid) async {
        try {
          final doc  = await _db.collection('users').doc(uid).get();
          final name = (doc.data()?['userName'] as String?) ?? uid;
          return _Member(uid: uid, name: name);
        } catch (_) {
          return _Member(uid: uid, name: uid);
        }
      });

      final loaded = await Future.wait(futures);

      if (mounted) {
        setState(() {
          _members        = loaded;
          _paidByUid      = widget.currentUserId; // default: I paid
          _splitBetween   = loaded.map((m) => m.uid).toSet(); // default: split all
          _loadingMembers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _membersError   = e.toString();
          _loadingMembers = false;
          // Still allow adding a bill for just the current user
          _members      = [_Member(uid: widget.currentUserId, name: 'Me')];
          _paidByUid    = widget.currentUserId;
          _splitBetween = {widget.currentUserId};
        });
      }
    }
  }

  // ── Submit ─────────────────────────────────

  Future<void> _submit() async {
    final amtStr = _amountCtrl.text.trim();
    if (amtStr.isEmpty) return;
    final amount = double.tryParse(amtStr);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount.');
      return;
    }
    if (_paidByUid == null) {
      _showError('Please select who paid.');
      return;
    }
    if (_splitBetween.isEmpty) {
      _showError('Please select at least one person to split with.');
      return;
    }

    setState(() => _loading = true);

    try {
      await _db.collection('bills').add({
        'amount':       amount,
        'paidBy':       _paidByUid,
        'splitBetween': _splitBetween.toList(),
        'categories':   _selectedCat,
        'createdAt':    FieldValue.serverTimestamp(),
        'houseId':      widget.houseId,
      });

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showError('Failed to save: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
      decoration: const BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: _cardBorder,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),

            const Text('New Bill',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: _textPri)),
            const SizedBox(height: 22),

            // ── Amount ──────────────────────────
            _SheetLabel('Amount (\$)'),
            const SizedBox(height: 8),
            _StyledTextField(
              controller: _amountCtrl,
              hint: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 18),

            // ── Category ────────────────────────
            _SheetLabel('Category'),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat      = _categories[i];
                  final selected = cat == _selectedCat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCat = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: selected ? _pink.withOpacity(0.2) : _pillBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: selected ? _pink : _cardBorder, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_iconForCategory(cat),
                              size: 15, color: selected ? _pink : _textSec),
                          const SizedBox(width: 5),
                          Text(_capitalize(cat),
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: selected ? _pink : _textSec)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // ── Paid by ─────────────────────────
            _SheetLabel('Paid by'),
            const SizedBox(height: 10),
            _loadingMembers
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: CircularProgressIndicator(color: _pink, strokeWidth: 2),
                    ),
                  )
                : _membersError != null
                    ? Text('Could not load members: $_membersError',
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12))
                    : Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _members.map((m) {
                          final selected = m.uid == _paidByUid;
                          return GestureDetector(
                            onTap: () => setState(() => _paidByUid = m.uid),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? _pink.withOpacity(0.2) : _pillBg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: selected ? _pink : _cardBorder,
                                    width: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 11,
                                    backgroundColor:
                                        selected ? _pink : _pinkDark,
                                    child: Text(
                                      m.name[0].toUpperCase(),
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: _textPri),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(m.name,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: selected ? _pink : _textSec)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
            const SizedBox(height: 20),

            // ── Split between ───────────────────
            _SheetLabel('Split between'),
            const SizedBox(height: 4),
            const Text('Tap to toggle who shares this bill',
                style: TextStyle(fontSize: 11, color: _textSec)),
            const SizedBox(height: 10),
            _loadingMembers
                ? const SizedBox()
                : Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _members.map((m) {
                      final included = _splitBetween.contains(m.uid);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (included) {
                            _splitBetween.remove(m.uid);
                          } else {
                            _splitBetween.add(m.uid);
                          }
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: included
                                ? const Color(0xFF00695C).withOpacity(0.2)
                                : _pillBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: included
                                  ? const Color(0xFF00C9A7)
                                  : _cardBorder,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                included
                                    ? Icons.check_circle_outline
                                    : Icons.radio_button_unchecked,
                                size: 14,
                                color: included
                                    ? const Color(0xFF00C9A7)
                                    : _textSec,
                              ),
                              const SizedBox(width: 6),
                              Text(m.name,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: included
                                          ? const Color(0xFF00C9A7)
                                          : _textSec)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 28),

            // ── Submit ──────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_loading || _loadingMembers) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pink,
                  foregroundColor: _textPri,
                  disabledBackgroundColor: _pink.withOpacity(0.4),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Add Bill',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SHEET HELPERS
// ─────────────────────────────────────────────

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _textSec,
            letterSpacing: 0.5),
      );
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: _textPri, fontSize: 15),
        cursorColor: _pink,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: _textSec),
          filled: true,
          fillColor: _pillBg,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _cardBorder)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _cardBorder)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _pink, width: 1.5)),
        ),
      );
}