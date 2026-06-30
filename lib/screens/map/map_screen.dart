import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/shared_app_bar.dart';
import '../home/home_widgets.dart';

class MapScreen extends StatefulWidget {
  final String houseId;
  final String currentUserId;

  const MapScreen({super.key, required this.houseId, required this.currentUserId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String? _permissionIssue;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _permissionIssue = 'Location services are turned off on this device.';
        _checked = true;
      });
      return;
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      setState(() {
        _permissionIssue =
            'Location permission permanently denied. Enable it in system settings.';
        _checked = true;
      });
      return;
    }
    if (perm == LocationPermission.denied) {
      setState(() {
        _permissionIssue = 'Location permission denied.';
        _checked = true;
      });
      return;
    }

    setState(() {
      _permissionIssue = null;
      _checked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: CustomScrollView(
        slivers: [
          HouseAppBar(
            houseId: widget.houseId,
            currentUserId: widget.currentUserId,
            weekRangeLabel: '',
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: !_checked
                ? const Center(child: CircularProgressIndicator())
                : _permissionIssue != null
                    ? _ErrorState(
                        message: _permissionIssue!,
                        onRetry: _checkPermissions,
                      )
                    : _buildMapStream(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapStream() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('houseId', isEqualTo: widget.houseId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return _ErrorState(message: 'Firestore error: ${snap.error}');
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = snap.data!.docs
            .where((d) => d.data()['lastLat'] != null && d.data()['lastLng'] != null)
            .toList();

        if (members.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No location data yet.\nMake sure location permissions are granted '
                'and walk a few meters to trigger the first GPS reading.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54),
              ),
            ),
          );
        }

        final center = LatLng(
          members.first.data()['lastLat'],
          members.first.data()['lastLng'],
        );

        return FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: 15),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.homie',
              errorTileCallback: (tile, error, stackTrace) {
                debugPrint('Tile load failed: $error');
              },
            ),
            MarkerLayer(
              markers: members.map((doc) {
                final d = doc.data();
                return Marker(
                  point: LatLng(d['lastLat'], d['lastLng']),
                  width: 60,
                  height: 70,
                  child: _MemberPin(
                    avatarIndex: d['avatarIndex'] as int? ?? 0,
                    battery: d['batteryLevel'] as int? ?? 0,
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorState({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off, color: Colors.white38, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

class _MemberPin extends StatelessWidget {
  final int avatarIndex;
  final int battery;

  const _MemberPin({required this.avatarIndex, required this.battery});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1A1A2E),
            border: Border.all(color: const Color(0xFFE040FB), width: 2),
          ),
          child: HomeCatAvatar(avatarIndex: avatarIndex, size: 40),
        ),
        Positioned(
          right: -4,
          bottom: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: battery <= 20 ? Colors.redAccent : Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$battery%', style: const TextStyle(color: Colors.white, fontSize: 9)),
          ),
        ),
      ],
    );
  }
}