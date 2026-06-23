import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bill_model.dart';
import '../models/chore_model.dart';
import '../models/event_model.dart';
import '../models/note_model.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Returns "YYYY-MM-DD" for the Monday of the current week.
  static String currentWeekStart() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final d = DateTime(monday.year, monday.month, monday.day);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  // ── User names cache ──────────────────────────────────────────────────────────

  final Map<String, String> _nameCache = {};

  Future<String> getUserName(String userId) async {
    if (_nameCache.containsKey(userId)) return _nameCache[userId]!;
    final doc = await _db.collection('users').doc(userId).get();
    // Profile screens save as 'name'; fall back to 'userName' for older docs
    final name = (doc.data()?['name'] as String?)
        ?? (doc.data()?['userName'] as String?)
        ?? 'Unknown';
    _nameCache[userId] = name;
    return name;
  }

  // ── House ────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> getHouseData(String houseId) async {
    final doc = await _db.collection('houses').doc(houseId).get();
    return doc.data();
  }

  /// Returns a list of member profiles: {userId, name, avatarIndex}.
  Future<List<Map<String, dynamic>>> getHouseMemberDetails(String houseId) async {
    final houseDoc = await _db.collection('houses').doc(houseId).get();
    final memberIds = List<String>.from(houseDoc.data()?['members'] ?? []);

    final profiles = await Future.wait(memberIds.map((uid) async {
      final userDoc = await _db.collection('users').doc(uid).get();
      final d = userDoc.data() ?? {};
      return <String, dynamic>{
        'userId': uid,
        'name': (d['name'] as String?) ?? (d['userName'] as String?) ?? 'Unknown',
        'avatarIndex': d['avatarIndex'] as int? ?? 0,
      };
    }));

    return profiles;
  }
// ── Leave House ──────────────────────────────────────────────────────────────

  Future<void> leaveHouse(String userId, String houseId) async {
    final batch = _db.batch();

    // 1. Remove the houseId from the user's document
    batch.update(_db.collection('users').doc(userId), {
      'houseId': FieldValue.delete(),
    });

    // 2. Remove the user from the house's members array
    batch.update(_db.collection('houses').doc(houseId), {
      'members': FieldValue.arrayRemove([userId]),
    });

    await batch.commit();
  }
  // ── Events ───────────────────────────────────────────────────────────────────

  Stream<List<EventModel>> eventsStream(String houseId) => _db
      .collection('events')
      .where('houseId', isEqualTo: houseId)
      .orderBy('date')
      .snapshots()
      .map((s) => s.docs.map(EventModel.fromFirestore).toList());

Future<void> updateEvent({
    required String eventId,
    required String title,
    required DateTime date,
    required String houseId, // Kept so your UI parameters don't break
  }) async {
    // Point directly to the root 'events' collection and find the specific event doc
    await _db.collection('events').doc(eventId).update({
      'title': title,
      'date': Timestamp.fromDate(date),
    });
  }

  Future<void> deleteEvent({
    required String eventId,
    required String houseId, // Kept so your UI parameters don't break
  }) async {
    // Point directly to the root 'events' collection and delete the specific event doc
    await _db.collection('events').doc(eventId).delete();
  }

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

  // ── Bills ────────────────────────────────────────────────────────────────────

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

  // FIND and REPLACE this entire method:
Future<void> settleBill({
  required String billId,
  required String userId,
  required bool settled,
}) =>
    _db.collection('bills').doc(billId).update({
      'settledBy': settled
          ? FieldValue.arrayUnion([userId])
          : FieldValue.arrayRemove([userId]),
    });

Future<void> updateBillPayer({
  required String billId,
  required String newPayerId,
}) =>
    _db.collection('bills').doc(billId).update({'paidBy': newPayerId});

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


  // ── House members (legacy — kept for bills/calendar compatibility) ────────────

  Future<List<Map<String, String>>> getHouseMembers(String houseId) async {
    final snap = await _db
        .collection('users')
        .where('houseId', isEqualTo: houseId)
        .get();
    return snap.docs
        .map((d) => {
              'userId': d.id,
              'userName': (d.data()['name'] as String?)
                  ?? (d.data()['userName'] as String?)
                  ?? 'Unknown',
            })
        .toList();
  }

  // ── Chores ───────────────────────────────────────────────────────────────────

  /// Streams all chores for the house in the current week.
  Stream<List<ChoreModel>> choresStream(String houseId) => _db
      .collection('chores')
      .where('houseId', isEqualTo: houseId)
      .where('weekStart', isEqualTo: currentWeekStart())
      .snapshots()
      .map((s) => s.docs.map(ChoreModel.fromFirestore).toList());

  /// Creates a new chore. If there is only one member, XP is auto-agreed.
  Future<void> addChore({
    required String title,
    required String assignedTo,
    required String houseId,
    required String createdBy,
    required int proposedXP,
    required int memberCount,
  }) async {
    final agreed = memberCount <= 1;
    await _db.collection('chores').add({
      'title': title,
      'assignedTo': assignedTo,
      'houseId': houseId,
      'completed': false,
      'completedAt': null,
      'proposedXP': proposedXP,
      'xpStatus': agreed ? 'agreed' : 'pending',
      'xpVotes': {createdBy: proposedXP},
      'agreedXP': proposedXP,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'weekStart': currentWeekStart(),
    });
  }

  Future<void> deleteChore(String choreId) =>
      _db.collection('chores').doc(choreId).delete();

  /// Toggles a chore's completion. Only the assigned user should call this.
  Future<void> toggleChore(String choreId, bool completed) =>
      _db.collection('chores').doc(choreId).update({
        'completed': completed,
        'completedAt': completed ? FieldValue.serverTimestamp() : null,
      });

  /// Records this user's XP vote. Finalises XP once all members have voted.
  Future<void> voteOnChoreXP({
    required String choreId,
    required String userId,
    required int vote,
    required String houseId,
  }) async {
    // Get current member list
    final houseDoc = await _db.collection('houses').doc(houseId).get();
    final memberIds = List<String>.from(houseDoc.data()?['members'] ?? []);

    // Merge new vote with existing votes
    final choreDoc = await _db.collection('chores').doc(choreId).get();
    final existing = Map<String, int>.from(
      (choreDoc.data()?['xpVotes'] as Map?)
              ?.map((k, v) => MapEntry(k as String, v as int)) ??
          {},
    );
    existing[userId] = vote;

    final allVoted = memberIds.every(existing.containsKey);
    final avgXP = allVoted
        ? (existing.values.reduce((a, b) => a + b) / existing.length).round()
        : (choreDoc.data()?['proposedXP'] as int? ?? 5);

    final update = <String, dynamic>{'xpVotes': existing};
    if (allVoted) {
      update['xpStatus'] = 'agreed';
      update['agreedXP'] = avgXP;
    }
    await _db.collection('chores').doc(choreId).update(update);
  }

  /// Returns a map of userId → total XP earned this week.
  Future<Map<String, int>> getWeeklyXP(String houseId) async {
    final snap = await _db
        .collection('chores')
        .where('houseId', isEqualTo: houseId)
        .where('weekStart', isEqualTo: currentWeekStart())
        .where('completed', isEqualTo: true)
        .get();

    final scores = <String, int>{};
    for (final doc in snap.docs) {
      final c = ChoreModel.fromFirestore(doc);
      scores[c.assignedTo] = (scores[c.assignedTo] ?? 0) + c.effectiveXP;
    }
    return scores;
  }

  // ── Notes ────────────────────────────────────────────────────────────────────

  /// Streams notes that have not yet expired.
  /// Filters client-side to avoid needing a composite Firestore index.
  Stream<List<NoteModel>> notesStream(String houseId) {
    return _db
        .collection('notes')
        .where('houseId', isEqualTo: houseId)
        .snapshots()
        .map((s) {
          final now = DateTime.now();
          final active = s.docs
              .map(NoteModel.fromFirestore)
              .where((n) => n.expiresAt.isAfter(now))
              .toList();
          active.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return active;
        });
  }

  Future<void> addNote({
    required String content,
    required String authorId,
    required String authorName,
    required String houseId,
  }) async {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    await _db.collection('notes').add({
      'content': content,
      'authorId': authorId,
      'authorName': authorName,
      'houseId': houseId,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(endOfDay),
    });
  }
}
