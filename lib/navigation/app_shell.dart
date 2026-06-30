import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/home/home_screen.dart';
import '../screens/bills/bills_screen.dart';
import '../screens/calendar/calendar_screen.dart';

const Color _darkBg = Color(0xFF0D0D1A);
const Color _pink   = Color(0xFFE040FB);


const String _navBgImage = 'assets/images/BottomNavBG.png';
const List<String> _navIconPaths = [
  'assets/images/coinIcon.png',
  'assets/images/homeIcon.png',
  'assets/images/calendarIcon.png',
];

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
  int _index = 1; 

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

  @override
  Widget build(BuildContext context) {
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
          
          BillsScreen(
            houseId: widget.houseId,
            currentUserId: widget.currentUserId,
            houseName: _houseName,
            avatarIndex: 0,
          ),
          
          HomeScreen(
            userId: widget.currentUserId,
            houseId: widget.houseId,
          ),
          
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
        
        image: const DecorationImage(
          image: AssetImage(_navBgImage),
          fit: BoxFit.fill,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Stack(
        children: [
          
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
                    color: _pink.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _pink.withValues(alpha: 0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          
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
                        scale: active ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutBack,
                        
                        child: ColorFiltered(
                          colorFilter: active
                              ? const ColorFilter.mode(
                                  Colors.transparent,
                                  BlendMode.multiply,
                                )
                              : ColorFilter.mode(
                                  Colors.white.withValues(alpha: 0.35),
                                  BlendMode.srcATop,
                                ),
                          child: Image.asset(
                            _navIconPaths[i],
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                          ),
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