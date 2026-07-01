import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class InboxListener {
  InboxListener._();
  static final InboxListener instance = InboxListener._();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  void start(String currentUserId) {
    _sub?.cancel();
    _sub = FirebaseFirestore.instance
        .collection('notifications')
        .where('toUserId', isEqualTo: currentUserId)
        .where('read', isEqualTo: false)
        .snapshots()
        .listen((snap) async {
      for (final change in snap.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        final doc = change.doc;
        final data = doc.data();
        if (data == null) continue;

        await NotificationService.instance.showInstantNotification(
          id: doc.id.hashCode & 0x7FFFFFFF,
          title: 'Housemate update',
          body: data['message'] as String? ?? '',
        );

        await doc.reference.update({'read': true});
      }
    });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }
}