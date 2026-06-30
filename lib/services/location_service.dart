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
  bool _wasHome = true; // assume home on boot; first reading will correct it

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

    _posSub?.cancel();
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 30, // meters before a new update fires
      ),
    ).listen((pos) async {
      final battery = await _battery.batteryLevel;

      bool? isHomeNow;
      if (homeLat != null && homeLng != null) {
        final distance = Geolocator.distanceBetween(
          pos.latitude, pos.longitude, homeLat, homeLng,
        );
        isHomeNow = distance <= _homeRadiusMeters;

        if (isHomeNow != _wasHome) {
          _wasHome = isHomeNow;
          await NotificationService.instance.debugFireTestNotification(
            eventTitle: isHomeNow ? "You've arrived home 🏠" : "You've left home 👋",
          );
          // TODO: also write a 'lastTransition' field so a Cloud Function
          // can pick it up and push to other house members.
        }
      }

      await _db.collection('users').doc(userId).update({
        'lastLat': pos.latitude,
        'lastLng': pos.longitude,
        'lastLocationAt': FieldValue.serverTimestamp(),
        'batteryLevel': battery,
        if (isHomeNow != null) 'isHome': isHomeNow,
      });
    });
  }

  void stop() => _posSub?.cancel();
}