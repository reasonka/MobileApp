import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bill_model.dart';
import '../models/event_model.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // ── Names cache ──────────────────────────────────────────────────────────
  final Map<String, String> _nameCache = {};

  Future<String> getUserName(String userId) async {
    if (_nameCache.containsKey(userId)) return _nameCache[userId]!;
    final doc = await _db.collection('users').doc(userId).get();
    final name = (doc.data()?['userName'] as String?) ?? 'Unknown';
    _nameCache[userId] = name;
    return name;
  }

// ── Events ───────────────────────────────────────────────────────────────
  Stream<List<EventModel>> eventsStream(String houseId) => _db
      .collection('events')
      .where('houseId', isEqualTo: houseId)
      .orderBy('date', descending: false)
      .snapshots()
      .map((s) => s.docs.map(EventModel.fromFirestore).toList());

  Future<void> addEvent({
    required String title,
    required DateTime date,
    required String houseId,
    required String currentUserId,
  }) =>
      _db.collection('events').add(EventModel(
            eventId: '',
            title: title,
            date: date,
            houseId: houseId,
            createdBy: currentUserId,
          ).toMap());


  // ── Bills ────────────────────────────────────────────────────────────────
  Stream<List<BillModel>> billsStream(String houseId) => _db
      .collection('bills')
      .where('houseId', isEqualTo: houseId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(BillModel.fromFirestore).toList());

  Future<void> addBill({
    required double amount,
    required BillCategory category,
    required List<String> splitBetween,
    required String houseId,
    required String currentUserId,
  }) =>
      _db.collection('bills').add(BillModel(
            billId: '',
            amount: amount,
            paidBy: currentUserId,
            splitBetween: splitBetween,
            category: category,
            createdAt: DateTime.now(),
            houseId: houseId,
          ).toMap());

  Future<void> deleteBill(String billId) =>
      _db.collection('bills').doc(billId).delete();

  // ── Balance totals ───────────────────────────────────────────────────────
  Future<List<double>> getBalances(String houseId, String currentUserId) async {
    final snap = await _db
        .collection('bills')
        .where('houseId', isEqualTo: houseId)
        .get();

    double owe = 0, owedToMe = 0;
    for (final doc in snap.docs) {
      final b = BillModel.fromFirestore(doc);
      if (b.paidBy != currentUserId && b.splitBetween.contains(currentUserId)) {
        owe += b.perPersonAmount;
      }
      if (b.paidBy == currentUserId) {
        final others =
            b.splitBetween.where((id) => id != currentUserId).length;
        owedToMe += b.perPersonAmount * others;
      }
    }
    return [owe, owedToMe];
  }

  // ── House members ────────────────────────────────────────────────────────
  Future<List<Map<String, String>>> getHouseMembers(String houseId) async {
    final snap = await _db
        .collection('users')
        .where('houseId', isEqualTo: houseId)
        .get();
    return snap.docs
        .map((d) => {
              'userId': d.id,
              'userName': (d.data()['userName'] as String?) ?? 'Unknown',
            })
        .toList();
  }
}