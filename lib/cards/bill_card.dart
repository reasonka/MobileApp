import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/bill_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/shared_app_bar.dart';

// ── Theme ─────────────────────────────────────────────────────────────────────
const _bg         = Color(0xFF0D0D1A);
const _card       = Color(0xFF1A1A2E);
const _cardBorder = Color(0xFF2E2E50);
const _pink       = Color(0xFFE040FB);
const _pinkDark   = Color(0xFF9C27B0);
const _textPri    = Color(0xFFFFFFFF);
const _textSec    = Color(0xFFB0ADCC);
const _pillBg     = Color(0xFF23233A);
const _green      = Color(0xFF00C9A7);
const _greenBg    = Color(0xFF00695C);

// ── Screen ────────────────────────────────────────────────────────────────────
class BillsScreen extends StatefulWidget {
  final String houseId;
  final String currentUserId;
  final String houseName;
  final int avatarIndex;

  const BillsScreen({
    super.key,
    required this.houseId,
    required this.currentUserId,
    required this.houseName,
    required this.avatarIndex,
  });

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  final _svc = FirestoreService();

  String get _weekRangeLabel {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    return '(${fmt(monday)}-${fmt(sunday)})';
  }

  (double, double) _summarise(List<BillModel> bills) {
    double youOwe = 0;
    double owedToYou = 0;
    for (final b in bills) {
      if (b.splitBetween.isEmpty) continue;
      if (b.paidBy != widget.currentUserId &&
          b.splitBetween.contains(widget.currentUserId) &&
          !b.isSettledBy(widget.currentUserId)) {
        youOwe += b.perPersonAmount;
      }
      if (b.paidBy == widget.currentUserId) {
        final unsettled = b.splitBetween
            .where((id) => id != widget.currentUserId && !b.isSettledBy(id))
            .length;
        owedToYou += b.perPersonAmount * unsettled;
      }
    }
    return (youOwe, owedToYou);
  }

  Future<String> _userName(String uid) => _svc.getUserName(uid);

  Future<List<Map<String, String>>> _getMembers() async {
    final raw = await _svc.getHouseMembers(widget.houseId);
    return raw
        .map((m) => {'userId': m['userId']!, 'userName': m['userName']!})
        .toList();
  }

  void _openNewBillSheet() async {
    final members = await _getMembers();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewBillSheet(
        houseId: widget.houseId,
        currentUserId: widget.currentUserId,
        members: members,
        service: _svc,
      ),
    );
  }

  void _openDetailSheet(BillModel bill) async {
    final members = await _getMembers();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BillDetailSheet(
        bill: bill,
        currentUserId: widget.currentUserId,
        members: members,
        service: _svc,
        getUserName: _userName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: StreamBuilder<List<BillModel>>(
        stream: _svc.billsStream(widget.houseId),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: _pink));
          }
          if (snap.hasError) {
            return Center(
              child: Text('Error: ${snap.error}',
                  style: const TextStyle(color: _textSec)),
            );
          }

          final allBills = snap.data ?? [];
          final active = allBills.where((b) => !b.isFullySettled).toList();
          final settled = allBills.where((b) => b.isFullySettled).toList();
          final bills = [...active, ...settled];
          final (youOwe, owedToYou) = _summarise(allBills);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              HouseAppBar(
                houseId: widget.houseId,
                currentUserId: widget.currentUserId,
                weekRangeLabel: _weekRangeLabel,
              ),

              // ── Summary cards ─────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'You owe',
                          amount: youOwe,
                          gradientColors: const [
                            Color(0xFF6A1B9A),
                            Color(0xFF4A148C),
                            Color(0xFF2A0A5E),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Owe you',
                          amount: owedToYou,
                          gradientColors: const [
                            Color(0xFF00695C),
                            Color(0xFF004D40),
                            Color(0xFF002B26),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Section heading ───────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Text(
                    'Bills',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: _textPri,
                    ),
                  ),
                ),
              ),

              // ── Empty state ───────────────────────────────────
              if (bills.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 40),
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long_outlined,
                            color: _textSec, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'No bills yet 🎉',
                          style: GoogleFonts.poppins(
                              color: _textSec, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final bill = bills[i];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: _BillCard(
                          bill: bill,
                          currentUserId: widget.currentUserId,
                          getUserName: _userName,
                          onTap: () => _openDetailSheet(bill),
                          onDelete: () => _svc.deleteBill(bill.billId),
                        ),
                      );
                    },
                    childCount: bills.length,
                  ),
                ),

              // ── New bill button ───────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  child: Center(
                    child: _NewBillButton(onTap: _openNewBillSheet),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────────────────
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
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _textSec)),
          const SizedBox(height: 8),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: _textPri,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bill Card ─────────────────────────────────────────────────────────────────
class _BillCard extends StatelessWidget {
  final BillModel bill;
  final String currentUserId;
  final Future<String> Function(String uid) getUserName;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BillCard({
    required this.bill,
    required this.currentUserId,
    required this.getUserName,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final settled = bill.isFullySettled;
    final iAmPayer = bill.paidBy == currentUserId;
    final iAmDebtor = !iAmPayer && bill.splitBetween.contains(currentUserId);
    final mySharePaid = bill.isSettledBy(currentUserId);

    return Opacity(
      opacity: settled ? 0.45 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              // ── Layer 1: BillMainPanel background ─────────────────
          Positioned.fill(
            child: IgnorePointer(     
            child: Image.asset(
              'assets/images/BillMainPanel.png',
              fit: BoxFit.cover,
            ),
            )
          ),
                           // ── Layer 2: card content ─────────────────────────────
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top row
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.12)),
                          ),
                          child: Center(
                            child: Text(
                              bill.category.emoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bill.category.label,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: settled ? _textSec : _textPri,
                                ),
                              ),
                              Text(
                                '÷ ${bill.splitBetween.length} people  •  \$${bill.perPersonAmount.toStringAsFixed(2)} each',
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: _textSec),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '\$${bill.amount.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: settled ? _textSec : _textPri,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: _card,
                                title: Text('Delete bill?',
                                    style: GoogleFonts.poppins(
                                        color: _textPri)),
                                content: Text('This cannot be undone.',
                                    style: GoogleFonts.poppins(
                                        color: _textSec)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Cancel',
                                        style: GoogleFonts.poppins(
                                            color: _textSec)),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      onDelete();
                                    },
                                    child: Text('Delete',
                                        style: GoogleFonts.poppins(
                                            color: Colors.redAccent)),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Icon(Icons.close_rounded,
                              size: 18, color: _textSec),
                        ),
                      ],
                    ),
                  ),

                  // ── Layer 3: BillSubPanel bottom strip ────────────
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(18),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            'assets/images/BillSubPanel.png',
                            fit: BoxFit.fill,
                          ),
                        ),
                        SizedBox(
                          height: 60,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              children: [
                                // Left spacer (same width as status pill area)
                                const SizedBox(width: 90),
                                Expanded(
                                  child: FutureBuilder<String>(
                                    future: getUserName(bill.paidBy),
                                    builder: (ctx, snap) {
                                      final name = snap.data ?? '...';
                                      return Center(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircleAvatar(
                                              radius: 18,
                                              backgroundColor: _pinkDark,
                                              child: Text(
                                                name.isNotEmpty
                                                    ? name[0].toUpperCase()
                                                    : '?',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: _textPri,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Paid by',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: _textSec,
                                                  ),
                                                ),
                                                Text(
                                                  name,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: _textPri,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 90,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: settled
                                        ? _StatusPill(
                                            label: 'Settled',
                                            color: _green,
                                          )
                                        : iAmPayer
                                            ? _StatusPill(
                                                label: 'Waiting',
                                                color: _pink,
                                              )
                                            : iAmDebtor && !mySharePaid
                                                ? _StatusPill(
                                                    label: 'You owe',
                                                    color: Colors.orangeAccent,
                                                  )
                                                : iAmDebtor && mySharePaid
                                                    ? _StatusPill(
                                                        label: 'You paid',
                                                        color: _green,
                                                      )
                                                    : const SizedBox.shrink(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              // ── Layer 4: border overlay ───────────────────────────
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: settled
                          ? Colors.white.withOpacity(0.05)
                          : Colors.white.withOpacity(0.08),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ]
        ),
      ),
      )
    );
  }
}

// ── Status Pill ───────────────────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ── New Bill Button ───────────────────────────────────────────────────────────
class _NewBillButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NewBillButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
        decoration: BoxDecoration(
          color: _pink.withOpacity(0.15),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: _pink.withOpacity(0.5), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_circle_outline, color: _pink, size: 18),
            const SizedBox(width: 8),
            Text(
              'New bill',
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _pink),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bill Detail Sheet ─────────────────────────────────────────────────────────
class _BillDetailSheet extends StatefulWidget {
  final BillModel bill;
  final String currentUserId;
  final List<Map<String, String>> members;
  final FirestoreService service;
  final Future<String> Function(String uid) getUserName;

  const _BillDetailSheet({
    required this.bill,
    required this.currentUserId,
    required this.members,
    required this.service,
    required this.getUserName,
  });

  @override
  State<_BillDetailSheet> createState() => _BillDetailSheetState();
}

class _BillDetailSheetState extends State<_BillDetailSheet> {
  late BillModel _bill;
  bool _saving = false;
  late final Stream<DocumentSnapshot> _billStream;

  @override
  void initState() {
    super.initState();
    _bill = widget.bill;
    _billStream = FirebaseFirestore.instance
        .collection('bills')
        .doc(_bill.billId)
        .snapshots();
    _billStream.listen((doc) {
      if (doc.exists && mounted) {
        setState(() => _bill = BillModel.fromFirestore(doc));
      }
    });
  }

  Future<void> _toggleSettle(String userId, bool currentlySettled) async {
    setState(() => _saving = true);
    await widget.service.settleBill(
      billId: _bill.billId,
      userId: userId,
      settled: !currentlySettled,
    );
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _changePayer(String newPayerId) async {
    await widget.service.updateBillPayer(
      billId: _bill.billId,
      newPayerId: newPayerId,
    );
  }

  String _nameFor(String uid) {
    return widget.members.firstWhere(
      (m) => m['userId'] == uid,
      orElse: () => {'userName': uid},
    )['userName']!;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final debtors =
        _bill.splitBetween.where((id) => id != _bill.paidBy).toList();
    final payerName = _nameFor(_bill.paidBy);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Stack(
        children: [
          // Sheet background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/BillSubPanel.png',
              fit: BoxFit.cover,
            ),
          ),
          // Dark overlay so text is readable
          Positioned.fill(
            child: Container(color: _card.withOpacity(0.85)),
          ),

          // Content
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                        color: _cardBorder,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),

                // ── Header ────────────────────────────────────────
                Row(
                  children: [
                    Text(_bill.category.emoji,
                        style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _bill.category.label,
                          style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _textPri),
                        ),
                        Text(
                          '\$${_bill.amount.toStringAsFixed(2)}  •  \$${_bill.perPersonAmount.toStringAsFixed(2)} each',
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: _textSec),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Paid by (editable) ────────────────────────────
                _SheetLabel('Paid by'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.members.map((m) {
                    final uid = m['userId']!;
                    final name = m['userName']!;
                    final selected = uid == _bill.paidBy;
                    return GestureDetector(
                      onTap: () => _changePayer(uid),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? _pink.withOpacity(0.2)
                              : _pillBg,
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
                              child: Text(name[0].toUpperCase(),
                                  style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: _textPri)),
                            ),
                            const SizedBox(width: 6),
                            Text(name,
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color:
                                        selected ? _pink : _textSec)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // ── Who needs to pay ──────────────────────────────
                _SheetLabel('Who needs to pay'),
                const SizedBox(height: 8),

                if (debtors.isEmpty)
                  Text(
                    'No one else in this bill.',
                    style: GoogleFonts.poppins(
                        color: _textSec, fontSize: 13),
                  )
                else
                  ...debtors.map((uid) {
                    final name = _nameFor(uid);
                    final paid = _bill.isSettledBy(uid);
                    final isMe = uid == widget.currentUserId;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: paid
                            ? _greenBg.withOpacity(0.15)
                            : _pillBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: paid
                              ? _green.withOpacity(0.4)
                              : _cardBorder,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: paid ? _greenBg : _pinkDark,
                            child: Text(
                              name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _textPri),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isMe ? 'You' : name,
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _textPri),
                                ),
                                Text(
                                  '\$${_bill.perPersonAmount.toStringAsFixed(2)}  →  $payerName',
                                  style: GoogleFonts.poppins(
                                      fontSize: 11, color: _textSec),
                                ),
                              ],
                            ),
                          ),
                          // Checkmark: debtor marks own, payer can mark anyone
                          if (isMe ||
                              _bill.paidBy == widget.currentUserId)
                            GestureDetector(
                              onTap: _saving
                                  ? null
                                  : () => _toggleSettle(uid, paid),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 200),
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: paid
                                      ? _green.withOpacity(0.2)
                                      : Colors.white.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        paid ? _green : _cardBorder,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.check,
                                  size: 16,
                                  color: paid ? _green : _cardBorder,
                                ),
                              ),
                            )
                          else
                            Icon(
                              paid
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: paid ? _green : _textSec,
                              size: 22,
                            ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 8),

                if (_bill.isFullySettled)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _greenBg.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: _green.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle,
                              color: _green, size: 16),
                          const SizedBox(width: 6),
                          Text('Fully settled',
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _green)),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── New Bill Sheet ────────────────────────────────────────────────────────────
class _NewBillSheet extends StatefulWidget {
  final String houseId;
  final String currentUserId;
  final List<Map<String, String>> members;
  final FirestoreService service;

  const _NewBillSheet({
    required this.houseId,
    required this.currentUserId,
    required this.members,
    required this.service,
  });

  @override
  State<_NewBillSheet> createState() => _NewBillSheetState();
}

class _NewBillSheetState extends State<_NewBillSheet> {
  final _amountCtrl = TextEditingController();
  BillCategory _selectedCat = BillCategory.groceries;
  bool _loading = false;
  late String _paidByUid;
  late Set<String> _splitBetween;

  @override
  void initState() {
    super.initState();
    _paidByUid = widget.currentUserId;
    _splitBetween = widget.members.map((m) => m['userId']!).toSet();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount.');
      return;
    }
    if (_splitBetween.isEmpty) {
      _showError('Select at least one person to split with.');
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.service.addBill(
        amount: amount,
        category: _selectedCat,
        splitBetween: _splitBetween.toList(),
        houseId: widget.houseId,
        currentUserId: _paidByUid,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showError('Failed to add bill: $e');
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
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Stack(
        children: [
          // Sheet background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/BillSubPanel.png',
              fit: BoxFit.cover,
            ),
          ),
          // Dark overlay
          Positioned.fill(
            child: Container(color: _card.withOpacity(0.85)),
          ),

          // Content
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                        color: _cardBorder,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),

                Text(
                  'New Bill',
                  style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _textPri),
                ),
                const SizedBox(height: 22),

                // Amount
                _SheetLabel('Amount (\$)'),
                const SizedBox(height: 8),
                _StyledTextField(
                  controller: _amountCtrl,
                  hint: '0.00',
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                ),
                const SizedBox(height: 18),

                // Category
                _SheetLabel('Category'),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: BillCategory.values.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final cat = BillCategory.values[i];
                      final selected = cat == _selectedCat;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCat = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14),
                          decoration: BoxDecoration(
                            color: selected
                                ? _pink.withOpacity(0.2)
                                : _pillBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: selected ? _pink : _cardBorder,
                                width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(cat.emoji),
                              const SizedBox(width: 5),
                              Text(cat.label,
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: selected
                                          ? _pink
                                          : _textSec)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Paid by
                _SheetLabel('Paid by'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.members.map((m) {
                    final uid = m['userId']!;
                    final name = m['userName']!;
                    final selected = uid == _paidByUid;
                    return GestureDetector(
                      onTap: () => setState(() => _paidByUid = uid),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? _pink.withOpacity(0.2)
                              : _pillBg,
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
                              child: Text(name[0].toUpperCase(),
                                  style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: _textPri)),
                            ),
                            const SizedBox(width: 6),
                            Text(name,
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: selected
                                        ? _pink
                                        : _textSec)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Split between
                _SheetLabel('Split between'),
                const SizedBox(height: 4),
                Text(
                  'Tap to toggle who shares this bill',
                  style:
                      GoogleFonts.poppins(fontSize: 11, color: _textSec),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.members.map((m) {
                    final uid = m['userId']!;
                    final name = m['userName']!;
                    final included = _splitBetween.contains(uid);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (included) {
                          _splitBetween.remove(uid);
                        } else {
                          _splitBetween.add(uid);
                        }
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: included
                              ? _greenBg.withOpacity(0.2)
                              : _pillBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: included ? _green : _cardBorder,
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
                              color: included ? _green : _textSec,
                            ),
                            const SizedBox(width: 6),
                            Text(name,
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        included ? _green : _textSec)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),

                // Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pink,
                      foregroundColor: _textPri,
                      disabledBackgroundColor: _pink.withOpacity(0.4),
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text('Add Bill',
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sheet Helpers ─────────────────────────────────────────────────────────────
class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.poppins(
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
        style: GoogleFonts.poppins(color: _textPri, fontSize: 15),
        cursorColor: _pink,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: _textSec),
          filled: true,
          fillColor: _pillBg.withOpacity(0.8),
          contentPadding: const EdgeInsets.symmetric(
              vertical: 14, horizontal: 16),
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