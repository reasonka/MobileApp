import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  final _db = FirebaseFirestore.instance;
  final _battery = Battery();

  StreamSubscription<Position>? _posSub;
  bool _wasHome = true;
  String? _currentHouseId; 

  static const double _homeRadiusMeters = 120;

  Future<bool> _ensurePermission() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) return false;
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  Future<void> start({
    required String userId,
    required String houseId,
  }) async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    if (!await _ensurePermission()) return;

    final houseDoc = await _db.collection('houses').doc(houseId).get();
    final homeLat = houseDoc.data()?['homeLat'] as double?;
    final homeLng = houseDoc.data()?['homeLng'] as double?;
    _currentHouseId = houseId;

    // Seed an immediate reading so the map has data as soon as the app
    // opens, instead of waiting for `distanceFilter` to be satisfied.
    // getPositionStream only fires once you've moved far enough from the
    // *previous* reading — on a stationary emulator (or someone who just
    // isn't walking anywhere) that may never happen on its own.
    try {
      final initialPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      await _handlePosition(
        pos: initialPos,
        userId: userId,
        homeLat: homeLat,
        homeLng: homeLng,
      );
    } catch (e) {
      // getCurrentPosition can time out on some emulators/devices without
      // a warmed-up GPS fix. Not fatal — the stream below will still pick
      // up a reading whenever one arrives.
    }

    _posSub?.cancel();
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 30, // meters before a new update fires
      ),
    ).listen((pos) => _handlePosition(
          pos: pos,
          userId: userId,
          homeLat: homeLat,
          homeLng: homeLng,
        ));
  }

  Future<void> _handlePosition({
    required Position pos,
    required String userId,
    required double? homeLat,
    required double? homeLng,
  }) async {
    final battery = await _battery.batteryLevel;

    bool? isHomeNow;
    if (homeLat != null && homeLng != null) {
      final distance = Geolocator.distanceBetween(
        pos.latitude, pos.longitude, homeLat, homeLng,
      );
      isHomeNow = distance <= _homeRadiusMeters;

      if (isHomeNow != _wasHome) {
        _wasHome = isHomeNow;
        await _notifyHousemates(
          userId: userId,
          houseId: _currentHouseId!,
          type: isHomeNow ? 'arrived' : 'leaving',
        );
      }
    }

    await _db.collection('users').doc(userId).update({
      'lastLat': pos.latitude,
      'lastLng': pos.longitude,
      'lastLocationAt': FieldValue.serverTimestamp(),
      'batteryLevel': battery,
      if (isHomeNow != null) 'isHome': isHomeNow,
    });
  }

Future<void> _notifyHousemates({
    required String userId,
    required String houseId,
    required String type,
  }) async {
    final selfDoc = await _db.collection('users').doc(userId).get();
    final selfName = selfDoc.data()?['name'] as String? ?? 'A housemate';
    final message = type == 'arrived'
        ? '$selfName has arrived home!'
        : '$selfName is heading out.';

    final housemates = await _db
        .collection('users')
        .where('houseId', isEqualTo: houseId)
        .get();

    final batch = _db.batch();
    for (final doc in housemates.docs) {
      if (doc.id == userId) continue;
      final ref = _db.collection('notifications').doc();
      batch.set(ref, {
        'houseId': houseId,
        'toUserId': doc.id,
        'fromUserId': userId,
        'type': type,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    }
    await batch.commit();
  }
  void stop() => _posSub?.cancel();
}