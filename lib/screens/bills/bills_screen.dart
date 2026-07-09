import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/bill_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/shared_app_bar.dart';
import '../../services/sound_service.dart';
import '../home/home_widgets.dart';



const _bg         = Color(0xFF0D0D1A);
const _card       = Color(0xFF1A1A2E);
const _cardBorder = Color(0xFF2E2E50);
const _pink       = Color(0xFFE040FB);
const _textPri    = Color(0xFFFFFFFF);
const _textSec    = Color(0xFFB0ADCC);
const _pillBg     = Color(0xFF23233A);
const _green      = Color(0xFF00C9A7);
const _greenBg    = Color(0xFF00695C);


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
  static const double _fabBottomInset = 123;

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
        youOwe += b.amountFor(widget.currentUserId);
      }
      if (b.paidBy == widget.currentUserId) {
        final unsettledOthers = b.splitBetween
            .where((id) => id != widget.currentUserId && !b.isSettledBy(id));
        for (final id in unsettledOthers) {
          owedToYou += b.amountFor(id);
        }
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
      if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
        return const Center(child: CircularProgressIndicator(color: _pink));
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
      final fabBottom = MediaQuery.paddingOf(context).bottom + _fabBottomInset;

      return Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          label: 'You Owe',
                          amount: youOwe,
                          backgroundImage: 'assets/images/bills/YouOwe.png',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _SummaryCard(
                          label: 'Owe You',
                          amount: owedToYou,
                          backgroundImage: 'assets/images/bills/OweYou.png',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

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
                        Text('No bills yet 🎉',
                            style: GoogleFonts.poppins(
                                color: _textSec, fontSize: 15)),
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

              const SliverToBoxAdapter(child: SizedBox(height: 180)),
            ],
          ),

          Positioned(
            left: HomeTokens.horizontalPadding,
            bottom: fabBottom,
            child: HomeGlassActionButton(
              label: 'New bill',
              width: 171,
              onTap: () {
                SoundService.instance.playPop();
                _openNewBillSheet();
              },
            ),
          ),
        ],
      );
    },
  ),
);
  }
}


class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final String backgroundImage;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.backgroundImage,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(backgroundImage, fit: BoxFit.cover),
          ),
          SizedBox(
            width: double.infinity,
            height: 140,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _textPri)),
                const SizedBox(height: 6),
                Text(
                  '\$${amount.isNaN || amount.isInfinite ? '0.00' : amount.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: _textPri,
                      letterSpacing: -1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


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
              Positioned.fill(
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/images/BillMainPanel.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                            child: Text(bill.category.emoji,
                                style: const TextStyle(fontSize: 20)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(bill.category.label,
                                  style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: settled ? _textSec : _textPri)),
                              Text(
                                bill.hasCustomAmounts
                                    ? '÷ ${bill.splitBetween.length} people  •  custom split'
                                    : '÷ ${bill.splitBetween.length} people  •  \$${bill.perPersonAmount.toStringAsFixed(2)} each',
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
                              color: settled ? _textSec : _textPri),
                        ),
                        const SizedBox(width: 2),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            SoundService.instance.playDelete();
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: _card,
                                title: Text('Delete bill?',
                                    style: GoogleFonts.poppins(color: _textPri)),
                                content: Text('This cannot be undone.',
                                    style: GoogleFonts.poppins(color: _textSec)),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      SoundService.instance.playUndo();
                                      Navigator.pop(context);
                                    },
                                    child: Text('Cancel',
                                        style: GoogleFonts.poppins(
                                            color: _textSec)),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      SoundService.instance.playDelete();
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
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(Icons.close_rounded,
                                size: 18, color: _textSec),
                          ),
                        ),
                      ],
                    ),
                  ),

                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(18)),
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              children: [
                                const SizedBox(width: 80),
                                Expanded(
                                  child: FutureBuilder<Map<String, dynamic>>(
                                    future: FirestoreService()
                                        .getUserProfile(bill.paidBy),
                                    builder: (ctx, snap) {
                                      final name = snap.data?['name']
                                              as String? ??
                                          '…';
                                      final avatarIndex =
                                          snap.data?['avatarIndex'] as int? ??
                                              0;
                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text('Paid by',
                                              style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: _textPri)),
                                          const SizedBox(width: 8),
                                          HomeCatAvatar(
                                              avatarIndex: avatarIndex,
                                              size: 36),
                                          const SizedBox(width: 8),
                                          Text(name,
                                              style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: _textPri)),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: settled
                                        ? _StatusPill(
                                            label: 'Settled', color: _green)
                                        : iAmPayer
                                            ? _StatusPill(
                                                label: 'Waiting', color: _pink)
                                            : iAmDebtor && !mySharePaid
                                                ? _StatusPill(
                                                    label: 'You owe',
                                                    color: Colors.orangeAccent)
                                                : iAmDebtor && mySharePaid
                                                    ? _StatusPill(
                                                        label: 'You paid',
                                                        color: _green)
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
                ],
              ),

              Positioned.fill(
                child: IgnorePointer(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}


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


// ─────────────────────────────────────────────
// BILL DETAIL SHEET — view, settle, and edit
// (category / payer / split / custom amounts)
// ─────────────────────────────────────────────

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
  bool _editingAmount = false;
  bool _editingDetails = false;

  late final TextEditingController _amountCtrl;
  late final Stream<DocumentSnapshot> _billStream;

  late BillCategory _editCategory;
  late Set<String> _editSplitBetween;
  bool _useCustomAmounts = false;
  final Map<String, TextEditingController> _customAmountCtrls = {};

  @override
  void initState() {
    super.initState();
    _bill = widget.bill;
    _amountCtrl = TextEditingController(text: _bill.amount.toStringAsFixed(2));
    _editCategory = _bill.category;
    _editSplitBetween = _bill.splitBetween.toSet();
    _useCustomAmounts = _bill.hasCustomAmounts;
    for (final m in widget.members) {
      final uid = m['userId']!;
      _customAmountCtrls[uid] = TextEditingController(
        text: _bill.amountFor(uid).toStringAsFixed(2),
      );
    }

    _billStream = FirebaseFirestore.instance
        .collection('bills')
        .doc(_bill.billId)
        .snapshots();
    _billStream.listen((doc) {
      if (doc.exists && mounted) {
        setState(() {
          _bill = BillModel.fromFirestore(doc);
          if (!_editingAmount) {
            _amountCtrl.text = _bill.amount.toStringAsFixed(2);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    for (final c in _customAmountCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAmount() async {
    final newAmount = double.tryParse(_amountCtrl.text.trim());
    if (newAmount == null || newAmount <= 0) {
      _showSnack('Enter a valid amount.', error: true);
      return;
    }
    setState(() => _saving = true);
    await widget.service.updateBillAmount(billId: _bill.billId, newAmount: newAmount);
    if (mounted) setState(() { _saving = false; _editingAmount = false; });
  }

  Future<void> _toggleSettle(String userId, bool currentlySettled) async {
    if (currentlySettled) {
      SoundService.instance.playUndo();
    } else {
      SoundService.instance.playPop();
    }
    setState(() => _saving = true);
    await widget.service.settleBill(
        billId: _bill.billId, userId: userId, settled: !currentlySettled);
    if (mounted) setState(() => _saving = false);
  }

  Future<void> _changePayer(String newPayerId) async {
    await widget.service.updateBillPayer(billId: _bill.billId, newPayerId: newPayerId);
  }

  String _nameFor(String uid) {
    return widget.members
        .firstWhere((m) => m['userId'] == uid, orElse: () => {'userName': uid})['userName']!;
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.poppins(color: _textPri)),
      backgroundColor: error ? Colors.red.shade700 : _card,
    ));
  }

  void _startEditingDetails() {
    setState(() {
      _editingDetails = true;
      _editCategory = _bill.category;
      _editSplitBetween = _bill.splitBetween.toSet();
      _useCustomAmounts = _bill.hasCustomAmounts;
      for (final m in widget.members) {
        final uid = m['userId']!;
        _customAmountCtrls[uid]?.text = _bill.amountFor(uid).toStringAsFixed(2);
      }
    });
  }

  Future<void> _saveDetails() async {
    if (_editSplitBetween.isEmpty) {
      _showSnack('Select at least one person to split with.', error: true);
      return;
    }
    if (!_editSplitBetween.contains(_bill.paidBy)) {
      _showSnack('The payer must be included in the split.', error: true);
      return;
    }

    Map<String, double>? customAmounts;
    if (_useCustomAmounts) {
      customAmounts = {};
      double sum = 0;
      for (final uid in _editSplitBetween) {
        final raw = double.tryParse(_customAmountCtrls[uid]?.text.trim() ?? '');
        if (raw == null || raw < 0) {
          _showSnack('Enter a valid amount for everyone.', error: true);
          return;
        }
        customAmounts[uid] = raw;
        sum += raw;
      }
      if ((sum - _bill.amount).abs() > 0.01) {
        _showSnack(
          'Custom amounts must add up to \$${_bill.amount.toStringAsFixed(2)} (currently \$${sum.toStringAsFixed(2)}).',
          error: true,
        );
        return;
      }
    }

    setState(() => _saving = true);
    try {
      await widget.service.updateBillDetails(
        billId: _bill.billId,
        category: _editCategory,
        splitBetween: _editSplitBetween.toList(),
        customAmounts: customAmounts,
      );
      if (mounted) setState(() { _editingDetails = false; _saving = false; });
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      _showSnack(e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  void _openMockPayment(String payerUid, double amountDue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MockPaymentSheet(
        amount: amountDue,
        payerName: payerUid == widget.currentUserId ? 'You' : _nameFor(payerUid),
        onConfirmed: () => _toggleSettle(payerUid, false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final debtors = _bill.splitBetween.where((id) => id != _bill.paidBy).toList();
    final payerName = _nameFor(_bill.paidBy);
    final canEdit = !_bill.hasAnySettlement;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/BillSubPanel.png', fit: BoxFit.cover),
          ),
          Positioned.fill(child: Container(color: _card.withOpacity(0.88))),

          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                        color: _cardBorder, borderRadius: BorderRadius.circular(2)),
                  ),
                ),

                // Header row: category + amount + edit-details toggle
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_bill.category.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_bill.category.label,
                              style: GoogleFonts.poppins(
                                  fontSize: 20, fontWeight: FontWeight.w700, color: _textPri)),
                          const SizedBox(height: 6),
                          if (_editingAmount) ...[
                            Row(children: [
                              Expanded(
                                child: TextField(
                                  controller: _amountCtrl,
                                  autofocus: true,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: GoogleFonts.poppins(color: _textPri, fontSize: 15),
                                  cursorColor: _pink,
                                  decoration: InputDecoration(
                                    prefixText: '\$',
                                    prefixStyle: GoogleFonts.poppins(color: _textPri, fontSize: 15),
                                    filled: true,
                                    fillColor: _pillBg,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _cardBorder)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _cardBorder)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _pink, width: 1.5)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _saving ? null : _saveAmount,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _pink.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: _pink),
                                  ),
                                  child: _saving
                                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: _pink, strokeWidth: 2))
                                      : Text('Save', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _pink)),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  SoundService.instance.playUndo();
                                  setState(() {
                                    _editingAmount = false;
                                    _amountCtrl.text = _bill.amount.toStringAsFixed(2);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _pillBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: _cardBorder),
                                  ),
                                  child: Text('Cancel', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _textSec)),
                                ),
                              ),
                            ]),
                          ] else ...[
                            Row(children: [
                              Text(
                                '\$${_bill.amount.toStringAsFixed(2)}${_bill.hasCustomAmounts ? ' • custom split' : '  •  \$${_bill.perPersonAmount.toStringAsFixed(2)} each'}',
                                style: GoogleFonts.poppins(fontSize: 13, color: _textSec),
                              ),
                              if (canEdit) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    SoundService.instance.playPop();
                                    setState(() => _editingAmount = true);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _pillBg,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: _cardBorder),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit_outlined, size: 11, color: _textSec),
                                        const SizedBox(width: 4),
                                        Text('Edit', style: GoogleFonts.poppins(fontSize: 11, color: _textSec)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ]),
                          ],
                        ],
                      ),
                    ),
                    if (canEdit && !_editingDetails)
                      GestureDetector(
                        onTap: () {
                          SoundService.instance.playPop();
                          _startEditingDetails();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _pillBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _cardBorder),
                          ),
                          child: const Icon(Icons.tune_rounded, size: 18, color: _textSec),
                        ),
                      ),
                  ],
                ),

                if (!canEdit) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Locked: someone has already settled their share.',
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.orangeAccent),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                if (_editingDetails) ...[
                  _buildEditDetailsPanel(),
                  const SizedBox(height: 20),
                ] else ...[
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
                        onTap: canEdit
                            ? () {
                                SoundService.instance.playPop();
                                _changePayer(uid);
                              }
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? _pink.withOpacity(0.2) : _pillBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: selected ? _pink : _cardBorder, width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FutureBuilder<Map<String, dynamic>>(
                                future: FirestoreService().getUserProfile(uid),
                                builder: (ctx, snap) {
                                  final avatarIndex = snap.data?['avatarIndex'] as int? ?? 0;
                                  return HomeCatAvatar(avatarIndex: avatarIndex, size: 22);
                                },
                              ),
                              const SizedBox(width: 6),
                              Text(name, style: GoogleFonts.poppins(fontSize: 13, color: selected ? _pink : _textSec)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  _SheetLabel('Who needs to pay'),
                  const SizedBox(height: 8),

                  if (debtors.isEmpty)
                    Text('No one else in this bill.', style: GoogleFonts.poppins(color: _textSec, fontSize: 13))
                  else
                    ...debtors.map((uid) {
                      final name = _nameFor(uid);
                      final paid = _bill.isSettledBy(uid);
                      final isMe = uid == widget.currentUserId;
                      final amountDue = _bill.amountFor(uid);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: paid ? _greenBg.withOpacity(0.15) : _pillBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: paid ? _green.withOpacity(0.4) : _cardBorder),
                        ),
                        child: Row(
                          children: [
                            FutureBuilder<Map<String, dynamic>>(
                              future: FirestoreService().getUserProfile(uid),
                              builder: (ctx, snap) {
                                final avatarIndex = snap.data?['avatarIndex'] as int? ?? 0;
                                return HomeCatAvatar(avatarIndex: avatarIndex, size: 32);
                              },
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(isMe ? 'You' : name,
                                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: _textPri)),
                                  Text(
                                    '\$${amountDue.toStringAsFixed(2)}  →  $payerName',
                                    style: GoogleFonts.poppins(fontSize: 11, color: _textSec),
                                  ),
                                ],
                              ),
                            ),
                            if (isMe && !paid)
                              GestureDetector(
                                onTap: _saving ? null : () => _openMockPayment(uid, amountDue),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _pink.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: _pink.withOpacity(0.5)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.qr_code_rounded, size: 14, color: _pink),
                                      const SizedBox(width: 4),
                                      Text('Pay', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: _pink)),
                                    ],
                                  ),
                                ),
                              )
                            else if (isMe && !paid)
                              GestureDetector(
                                onTap: _saving
                                    ? null
                                    : () {
                                        SoundService.instance.playPop();
                                        _openMockPayment(uid, amountDue);
                                      },
                                child:  AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: paid ? _green.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: paid ? _green : _cardBorder, width: 2),
                                  ),
                                  child: Icon(Icons.check, size: 16, color: paid ? _green : _cardBorder),
                                ),
                              )
                            else
                              Icon(
                                paid ? Icons.check_circle : Icons.radio_button_unchecked,
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _greenBg.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _green.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, color: _green, size: 16),
                            const SizedBox(width: 6),
                            Text('Fully settled', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _green)),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditDetailsPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _pillBg.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SheetLabel('Category'),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: BillCategory.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat = BillCategory.values[i];
                final selected = cat == _editCategory;
                return GestureDetector(
                  onTap: () {
                    SoundService.instance.playPop();
                    setState(() => _editCategory = cat);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: selected ? _pink.withOpacity(0.2) : _card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? _pink : _cardBorder, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat.emoji),
                        const SizedBox(width: 5),
                        Text(cat.label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? _pink : _textSec)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),

          _SheetLabel('Split between'),
          const SizedBox(height: 4),
          Text('Tap to add or remove people', style: GoogleFonts.poppins(fontSize: 11, color: _textSec)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.members.map((m) {
              final uid = m['userId']!;
              final name = m['userName']!;
              final included = _editSplitBetween.contains(uid);
              final isPayer = uid == _bill.paidBy;
              return GestureDetector(
                onTap: isPayer
                    ? null // payer must always be included
                    : () {
                        if (included) {
                          SoundService.instance.playUndo();
                        } else {
                          SoundService.instance.playPop();
                        }
                        setState(() {
                          if (included) {
                            _editSplitBetween.remove(uid);
                          } else {
                            _editSplitBetween.add(uid);
                          }
                        });
                      },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: included ? _greenBg.withOpacity(0.2) : _card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: included ? _green : _cardBorder, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        included ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                        size: 14,
                        color: included ? _green : _textSec,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isPayer ? '$name (payer)' : name,
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: included ? _green : _textSec),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(child: _SheetLabel('Custom per-person amounts')),
              Switch.adaptive(
                value: _useCustomAmounts,
                activeTrackColor: _pink,
                onChanged: (v) {
                  SoundService.instance.playPop();
                  setState(() => _useCustomAmounts = v);
                },
              ),
            ],
          ),
          if (_useCustomAmounts) ...[
            const SizedBox(height: 4),
            Text(
              'Must add up to \$${_bill.amount.toStringAsFixed(2)} total.',
              style: GoogleFonts.poppins(fontSize: 11, color: _textSec),
            ),
            const SizedBox(height: 10),
            ..._editSplitBetween.map((uid) {
              final name = _nameFor(uid);
              _customAmountCtrls.putIfAbsent(
                uid,
                () => TextEditingController(text: _bill.amountFor(uid).toStringAsFixed(2)),
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(name, style: GoogleFonts.poppins(fontSize: 13, color: _textPri)),
                    ),
                    SizedBox(
                      width: 110,
                      child: TextField(
                        controller: _customAmountCtrls[uid],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: GoogleFonts.poppins(color: _textPri, fontSize: 13),
                        cursorColor: _pink,
                        decoration: InputDecoration(
                          prefixText: '\$',
                          prefixStyle: GoogleFonts.poppins(color: _textSec, fontSize: 13),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          filled: true,
                          fillColor: _card,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _cardBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _cardBorder)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _pink, width: 1.5)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    SoundService.instance.playUndo();
                    setState(() => _editingDetails = false);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _cardBorder),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Cancel', style: GoogleFonts.poppins(color: _textSec)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving
                      ? null
                      : () {
                          SoundService.instance.playPop();
                          _saveDetails();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pink,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Save', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Simulated "scan to pay" flow. No real money moves — this just shows a
/// fake QR/reference and lets the user confirm, which then calls settleBill.
class _MockPaymentSheet extends StatefulWidget {
  final double amount;
  final String payerName;
  final Future<void> Function() onConfirmed;

  const _MockPaymentSheet({
    required this.amount,
    required this.payerName,
    required this.onConfirmed,
  });

  @override
  State<_MockPaymentSheet> createState() => _MockPaymentSheetState();
}

class _MockPaymentSheetState extends State<_MockPaymentSheet> {
  bool _processing = false;
  bool _done = false;

  String get _mockRef =>
      'HOMIE-PAY-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

  Future<void> _confirm() async {
    setState(() => _processing = true);
    await Future.delayed(const Duration(milliseconds: 900));
    await widget.onConfirmed();
    if (mounted) setState(() { _processing = false; _done = true; });
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
      decoration: const BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: _cardBorder, borderRadius: BorderRadius.circular(2)),
          ),
          Text(
            'Simulated payment',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: _textPri),
          ),
          const SizedBox(height: 4),
          Text(
            'No real money is transferred — for demo purposes only.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 11, color: _textSec),
          ),
          const SizedBox(height: 20),

          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(Icons.qr_code_2_rounded, size: 130, color: _card),
            ),
          ),
          const SizedBox(height: 16),
          Text(_mockRef, style: GoogleFonts.poppins(fontSize: 11, color: _textSec, letterSpacing: 1)),
          const SizedBox(height: 20),

          Text(
            '\$${widget.amount.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w800, color: _textPri),
          ),
          Text(
            widget.payerName,
            style: GoogleFonts.poppins(fontSize: 13, color: _textSec),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _processing || _done ? null : _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: _done ? _green : _pink,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _processing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      _done ? 'Payment confirmed ✓' : 'Simulate payment',
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────
// NEW BILL SHEET — working creation form
// ─────────────────────────────────────────────

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
  bool _useCustomAmounts = false;
  final Map<String, TextEditingController> _customAmountCtrls = {};
  final Map<String, int> _avatarCache = {};

  @override
  void initState() {
    super.initState();
    _paidByUid = widget.currentUserId;
    _splitBetween = widget.members.map((m) => m['userId']!).toSet();
    for (final m in widget.members) {
      _customAmountCtrls[m['userId']!] = TextEditingController();
    }
    _fetchAvatars();
  }

  Future<void> _fetchAvatars() async {
    for (final m in widget.members) {
      final uid = m['userId']!;
      final profile = await FirestoreService().getUserProfile(uid);
      if (mounted) {
        setState(() {
          _avatarCache[uid] = (profile['avatarIndex'] as int?) ?? 0;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    for (final c in _customAmountCtrls.values) {
      c.dispose();
    }
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
    if (!_splitBetween.contains(_paidByUid)) {
      _showError('The payer must be included in the split.');
      return;
    }

    Map<String, double>? customAmounts;
    if (_useCustomAmounts) {
      customAmounts = {};
      double sum = 0;
      for (final uid in _splitBetween) {
        final raw = double.tryParse(_customAmountCtrls[uid]?.text.trim() ?? '');
        if (raw == null || raw < 0) {
          _showError('Enter a valid amount for everyone.');
          return;
        }
        customAmounts[uid] = raw;
        sum += raw;
      }
      if ((sum - amount).abs() > 0.01) {
        _showError(
          'Custom amounts must add up to \$${amount.toStringAsFixed(2)} (currently \$${sum.toStringAsFixed(2)}).',
        );
        return;
      }
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
    final amountVal = double.tryParse(_amountCtrl.text.trim()) ?? 0;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/BillSubPanel.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: _card.withOpacity(0.88)),
          ),

          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                Text('New Bill',
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _textPri)),
                const SizedBox(height: 22),

                _SheetLabel('Amount (\$)'),
                const SizedBox(height: 8),
                _StyledTextField(
                  controller: _amountCtrl,
                  hint: '0.00',
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 18),

                _SheetLabel('Category'),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: BillCategory.values.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final cat = BillCategory.values[i];
                      final selected = cat == _selectedCat;
                      return GestureDetector(
                        onTap: () {
                          SoundService.instance.playPop();
                          setState(() => _selectedCat = cat);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
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
                                      color: selected ? _pink : _textSec)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

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
                      onTap: () {
                        SoundService.instance.playPop();
                        setState(() => _paidByUid = uid);
                      },
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
                            HomeCatAvatar(
                                avatarIndex: _avatarCache[uid] ?? 0,
                                size: 22),
                            const SizedBox(width: 6),
                            Text(name,
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: selected ? _pink : _textSec)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                _SheetLabel('Split between'),
                const SizedBox(height: 4),
                Text('Tap to toggle who shares this bill',
                    style:
                        GoogleFonts.poppins(fontSize: 11, color: _textSec)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.members.map((m) {
                    final uid = m['userId']!;
                    final name = m['userName']!;
                    final included = _splitBetween.contains(uid);
                    return GestureDetector(
                      onTap: () {
                        if (included) {
                          SoundService.instance.playUndo();
                        } else {
                          SoundService.instance.playPop();
                        }
                        setState(() {
                          if (included) {
                            _splitBetween.remove(uid);
                          } else {
                            _splitBetween.add(uid);
                          }
                        });
                      },
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
                                    color: included ? _green : _textSec)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(child: _SheetLabel('Custom per-person amounts')),
                    Switch.adaptive(
                      value: _useCustomAmounts,
                      activeTrackColor: _pink,
                      onChanged: (v) {
                        SoundService.instance.playPop();
                        setState(() => _useCustomAmounts = v);
                      },
                    ),
                  ],
                ),
                if (_useCustomAmounts) ...[
                  const SizedBox(height: 4),
                  Text(
                    amountVal > 0
                        ? 'Must add up to \$${amountVal.toStringAsFixed(2)} total.'
                        : 'Enter the bill amount first.',
                    style: GoogleFonts.poppins(fontSize: 11, color: _textSec),
                  ),
                  const SizedBox(height: 10),
                  ..._splitBetween.map((uid) {
                    final name = widget.members.firstWhere(
                        (m) => m['userId'] == uid)['userName']!;
                    _customAmountCtrls.putIfAbsent(
                        uid, () => TextEditingController());
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(name,
                                style: GoogleFonts.poppins(
                                    fontSize: 13, color: _textPri)),
                          ),
                          SizedBox(
                            width: 110,
                            child: TextField(
                              controller: _customAmountCtrls[uid],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              style: GoogleFonts.poppins(
                                  color: _textPri, fontSize: 13),
                              cursorColor: _pink,
                              decoration: InputDecoration(
                                prefixText: '\$',
                                prefixStyle: GoogleFonts.poppins(
                                    color: _textSec, fontSize: 13),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 10),
                                filled: true,
                                fillColor: _pillBg,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        const BorderSide(color: _cardBorder)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        const BorderSide(color: _cardBorder)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: _pink, width: 1.5)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading
                        ? null
                        : () {
                            SoundService.instance.playDone();
                            _submit();
                          },
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
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
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
  final ValueChanged<String>? onChanged;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: GoogleFonts.poppins(color: _textPri, fontSize: 15),
        cursorColor: _pink,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: _textSec),
          filled: true,
          fillColor: _pillBg.withOpacity(0.8),
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