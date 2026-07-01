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
  String? _selectedMemberId;

  final MapController _mapController = MapController();

  // Matches _BeltNavBar in main.dart: a 75px bar with a 14px bottom
  // margin, sitting inside a SafeArea(top: false). We add the device's
  // actual safe-area bottom inset (home indicator / gesture bar) plus a
  // small gap so the strip floats just above the real nav bar on every
  // device instead of a fixed guess that only works on some phones.
  static const double _navBarHeight = 75.0;
  static const double _navBarMargin = 14.0;
  static const double _stripGap = 12.0;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
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

  Future<void> _sendNotification({
    required String toUserId,
    required String toName,
    required String type, // 'arrived' or 'leaving'
  }) async {
    final message = type == 'arrived'
        ? "I've arrived home!"
        : "I'm heading out.";

    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'houseId': widget.houseId,
        'toUserId': toUserId,
        'fromUserId': widget.currentUserId,
        'type': type,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Notified $toName')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send notification: $e')),
      );
    }
  }

  void _onMarkerTap({
    required String memberId,
    required String memberName,
  }) {
    if (memberId == widget.currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("That's you!")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Notify $memberName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _NotifyOption(
                  icon: Icons.home_rounded,
                  label: "I've arrived",
                  color: const Color(0xFF4CAF50),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _sendNotification(
                      toUserId: memberId,
                      toName: memberName,
                      type: 'arrived',
                    );
                  },
                ),
                const SizedBox(height: 10),
                _NotifyOption(
                  icon: Icons.directions_walk_rounded,
                  label: "I'm leaving",
                  color: const Color(0xFFE040FB),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _sendNotification(
                      toUserId: memberId,
                      toName: memberName,
                      type: 'leaving',
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  // Recenters the map directly on a specific member and zooms in close
  // enough that "where are they, specifically" is unambiguous.
  void _focusOnMember({
    required String memberId,
    required double lat,
    required double lng,
  }) {
    setState(() => _selectedMemberId = memberId);
    _mapController.move(LatLng(lat, lng), 17);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: !_checked
          ? const Center(child: CircularProgressIndicator())
          : _permissionIssue != null
              ? CustomScrollView(
                  slivers: [
                    HouseAppBar(
                      houseId: widget.houseId,
                      currentUserId: widget.currentUserId,
                      weekRangeLabel: '',
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _ErrorState(
                        message: _permissionIssue!,
                        onRetry: _checkPermissions,
                      ),
                    ),
                  ],
                )
              : _buildMapWithOverlay(),
    );
  }

  Widget _buildMapWithOverlay() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('houseId', isEqualTo: widget.houseId)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return CustomScrollView(
            slivers: [
              HouseAppBar(
                houseId: widget.houseId,
                currentUserId: widget.currentUserId,
                weekRangeLabel: '',
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: _ErrorState(message: 'Firestore error: ${snap.error}'),
              ),
            ],
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = snap.data!.docs
            .where((d) => d.data()['lastLat'] != null && d.data()['lastLng'] != null)
            .toList();

        if (members.isEmpty) {
          return CustomScrollView(
            slivers: [
              HouseAppBar(
                houseId: widget.houseId,
                currentUserId: widget.currentUserId,
                weekRangeLabel: '',
              ),
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No location data yet.\nMake sure location permissions are granted.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        final center = LatLng(
          members.first.data()['lastLat'],
          members.first.data()['lastLng'],
        );

        final bottomSafeInset = MediaQuery.of(context).padding.bottom;
        final stripBottomOffset =
            bottomSafeInset + _navBarMargin + _navBarHeight + _stripGap;

        return Stack(
          children: [
            CustomScrollView(
              slivers: [
                HouseAppBar(
                  houseId: widget.houseId,
                  currentUserId: widget.currentUserId,
                  weekRangeLabel: '',
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: FlutterMap(
                    mapController: _mapController,
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
                          final name = d['name'] as String? ?? 'Housemate';
                          return Marker(
                            point: LatLng(d['lastLat'], d['lastLng']),
                            width: 64,
                            height: 92,
                            alignment: Alignment.topCenter,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _onMarkerTap(
                                memberId: doc.id,
                                memberName: name,
                              ),
                              child: _MemberPin(
                                avatarIndex: d['avatarIndex'] as int? ?? 0,
                                battery: d['batteryLevel'] as int? ?? 0,
                                isSelf: doc.id == widget.currentUserId,
                                isSelected: doc.id == _selectedMemberId,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: stripBottomOffset,
              child: _MemberAvatarStrip(
                members: members,
                currentUserId: widget.currentUserId,
                selectedMemberId: _selectedMemberId,
                onMemberSelected: (id, lat, lng) => _focusOnMember(
                  memberId: id,
                  lat: lat,
                  lng: lng,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Horizontal strip of house member avatars floating above the bottom bar.
// Tapping one recenters the map on that specific person.
class _MemberAvatarStrip extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> members;
  final String currentUserId;
  final String? selectedMemberId;
  final void Function(String id, double lat, double lng) onMemberSelected;

  const _MemberAvatarStrip({
    required this.members,
    required this.currentUserId,
    required this.selectedMemberId,
    required this.onMemberSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        itemCount: members.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final doc = members[index];
          final d = doc.data();
          final isSelf = doc.id == currentUserId;
          final isSelected = doc.id == selectedMemberId;
          final name = d['name'] as String? ?? (isSelf ? 'You' : 'Housemate');
          final lat = d['lastLat'] as double;
          final lng = d['lastLng'] as double;

          return GestureDetector(
            onTap: () => onMemberSelected(doc.id, lat, lng),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF64FFDA)
                          : (isSelf ? const Color(0xFF64B5F6) : const Color(0xFFE040FB)),
                      width: isSelected ? 3 : 2,
                    ),
                  ),
                  child: HomeCatAvatar(
                    avatarIndex: d['avatarIndex'] as int? ?? 0,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isSelf ? 'You' : name,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF64FFDA) : Colors.white70,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NotifyOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _NotifyOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
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

class _BatteryStyle {
  final IconData icon;
  final Color color;
  const _BatteryStyle(this.icon, this.color);

  static _BatteryStyle from(int battery) {
    if (battery <= 20) {
      return const _BatteryStyle(Icons.battery_alert_rounded, Color(0xFFFF5252));
    } else if (battery <= 40) {
      return const _BatteryStyle(Icons.battery_3_bar_rounded, Color(0xFFFFA726));
    } else if (battery <= 70) {
      return const _BatteryStyle(Icons.battery_5_bar_rounded, Color(0xFFFFEE58));
    } else {
      return const _BatteryStyle(Icons.battery_full_rounded, Color(0xFF66BB6A));
    }
  }
}

class _MemberPin extends StatelessWidget {
  final int avatarIndex;
  final int battery;
  final bool isSelf;
  final bool isSelected;

  const _MemberPin({
    required this.avatarIndex,
    required this.battery,
    this.isSelf = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final batteryStyle = _BatteryStyle.from(battery);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF162338) : const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? const Color(0xFF64FFDA) : Colors.white12,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              HomeCatAvatar(
                avatarIndex: avatarIndex,
                size: 36,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(batteryStyle.icon, color: batteryStyle.color, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '$battery%',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF64FFDA) : Colors.white24,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
