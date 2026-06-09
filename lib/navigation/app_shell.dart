import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/home/home_screen.dart';
import '../screens/bills/bills_screen.dart';
import '../screens/calendar/calendar_screen.dart';

const _darkBg   = Color(0xFF0D0D1A);
const _navBg    = Color(0xFF12122A);
const _pink     = Color(0xFFE040FB);
const _inactive = Color(0xFF616161);

class AppShell extends StatefulWidget {
  final String houseId;
  final String currentUserId;

  const AppShell({
    super.key,
    required this.houseId,
    required this.currentUserId,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  // Loaded from Firestore
  String _houseName = '';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadHouseName();
  }

  Future<void> _loadHouseName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('houses')
          .doc(widget.houseId)
          .get();
      if (mounted) {
        setState(() {
          _houseName = (doc.data()?['name'] as String?) ?? 'Our House';
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _houseName = 'Our House';
          _loaded = true;
        });
      }
    }
  }

  static const _icons = [
    Icons.home_rounded,
    Icons.attach_money_rounded,
    Icons.calendar_month_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    // Show a minimal loading screen while house name loads
    // (usually <300ms since it's one Firestore read)
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: _darkBg,
        body: Center(
          child: CircularProgressIndicator(color: _pink),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _darkBg,
      body: IndexedStack(
        index: _index,
        children: [
          // 0 – Home
          HomeScreen(
            userId: widget.currentUserId,
            houseId: widget.houseId,
          ),

          // 1 – Bills
          BillsScreen(
            houseId: widget.houseId,
            currentUserId: widget.currentUserId,
            houseName: _houseName,
            avatarIndex: 0,
          ),

          // 2 – Calendar
          CalendarScreen(
            houseId: widget.houseId,
            currentUserId: widget.currentUserId,
            houseName: _houseName,
            avatarIndex: 0,
          ),
        ],
      ),
      bottomNavigationBar: _SlidingNavBar(
        currentIndex: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SLIDING BOTTOM NAV BAR  (unchanged from your original)
// ─────────────────────────────────────────────────────────────────────────────

class _SlidingNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const _SlidingNavBar({
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  State<_SlidingNavBar> createState() => _SlidingNavBarState();
}

class _SlidingNavBarState extends State<_SlidingNavBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  int _prev = 0;

  static const _icons = [
    Icons.home_rounded,
    Icons.attach_money_rounded,
    Icons.calendar_month_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _prev = widget.currentIndex;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
  }

  @override
  void didUpdateWidget(_SlidingNavBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _prev = old.currentIndex;
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const itemCount = 3;

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: _navBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Sliding pink pill
          AnimatedBuilder(
            animation: _anim,
            builder: (context, _) {
              final w = MediaQuery.of(context).size.width / itemCount;
              final x =
                  (_prev + (widget.currentIndex - _prev) * _anim.value) * w;
              return Positioned(
                left: x + w * 0.25,
                top: 10,
                child: Container(
                  width: w * 0.5,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _pink,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _pink.withOpacity(0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Icon buttons
          Row(
            children: List.generate(itemCount, (i) {
              final active = widget.currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onChanged(i),
                  child: SizedBox(
                    height: 72,
                    child: Center(
                      child: AnimatedScale(
                        scale: active ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutBack,
                        child: Icon(
                          _icons[i],
                          color: active ? Colors.white : _inactive,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}