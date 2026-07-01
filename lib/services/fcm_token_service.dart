import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FcmTokenService {
  FcmTokenService._();
  static final FcmTokenService instance = FcmTokenService._();

  Future<void> register(String userId) async {
  final messaging = FirebaseMessaging.instance;
  final debugRef = FirebaseFirestore.instance.collection('_debug').doc(userId);

  try {
    final settings = await messaging.requestPermission(alert: true, badge: true, sound: true);
    await debugRef.set({'permissionStatus': settings.authorizationStatus.toString()}, SetOptions(merge: true));

    final token = await messaging.getToken();
    await debugRef.set({'token': token ?? 'NULL', 'tokenFetchedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));

    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': token,
      });
      await debugRef.set({'savedOk': true}, SetOptions(merge: true));
    }
  } catch (e) {
    await debugRef.set({'error': e.toString()}, SetOptions(merge: true));
  }

  messaging.onTokenRefresh.listen((newToken) {
    FirebaseFirestore.instance.collection('users').doc(userId).update({
      'fcmToken': newToken,
    });
  });
}
}