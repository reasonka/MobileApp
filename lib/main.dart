import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/bills/bills_screen.dart';
import 'screens/calendar/calendar_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/login/profile_setup_screen.dart';
import 'screens/login/family_setup_screen.dart';
// ignore: unused_import
import 'firebase_options.dart';
import 'services/sound_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform,
  );
  await SoundService.instance.preload();
  runApp(const HomieApp());
}

class HomieApp extends StatelessWidget {
  const HomieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Homie',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D1A),
        fontFamily: GoogleFonts.poppins().fontFamily,
        colorScheme: const ColorScheme.dark(
          primary:   Color(0xFFE040FB),
          secondary: Color(0xFF00C9A7),
          surface:   Color(0xFF1A1A2E),
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnap) {
          if (authSnap.connectionState == ConnectionState.waiting) {
            return _loadingScaffold;
          }

          final user = authSnap.data;
          if (user == null) return const LoginScreen();

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, userSnap) {
              if (userSnap.connectionState == ConnectionState.waiting) {
                return _loadingScaffold;
              }

              final data = userSnap.data?.data();

              if (data == null) {
                return ProfileSetupScreen(
                  uid: user.uid,
                  email: user.email ?? '',
                );
              }

              if (data['houseId'] == null) {
                return FamilySetupScreen(
                  uid: user.uid,
                  userName: data['name'] as String? ?? '',
                );
              }

              return RootNavigation(
                userId: user.uid,
                houseId: data['houseId'] as String,
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PALETTE
// ─────────────────────────────────────────────

const _loadingScaffold = Scaffold(
  backgroundColor: Color(0xFF0D0D1A),
  body: Center(
    child: CircularProgressIndicator(color: Color(0xFFE040FB)),
  ),
);

const Color _bg = Color(0xFF0D0D1A);

// ─────────────────────────────────────────────
// NAV ITEMS
// ─────────────────────────────────────────────

/// Figma bottom-nav icon sizes (node 88:297) — inactive vs active (centre tab).
class _NavItem {
  final String activeAsset;
  final String inactiveAsset;
  final double inactiveW;
  final double inactiveH;
  final double activeW;
  final double activeH;

  const _NavItem({
    required this.activeAsset,
    required this.inactiveAsset,
    required this.inactiveW,
    required this.inactiveH,
    required this.activeW,
    required this.activeH,
  });
}

const List<_NavItem> _navItems = [
  _NavItem(
    activeAsset: 'assets/images/nav/home_active.svg',
    inactiveAsset: 'assets/images/nav/home_inactive.svg',
    inactiveW: 49,
    inactiveH: 49,
    activeW: 73,
    activeH: 58,
  ),
  _NavItem(
    activeAsset: 'assets/images/nav/coin_active.svg',
    inactiveAsset: 'assets/images/nav/coin_inactive.svg',
    inactiveW: 48,
    inactiveH: 48,
    activeW: 58,
    activeH: 58,
  ),
  _NavItem(
    activeAsset: 'assets/images/nav/calendar_active.svg',
    inactiveAsset: 'assets/images/nav/calendar_inactive.svg',
    inactiveW: 43,
    inactiveH: 46,
    activeW: 55,
    activeH: 58,
  ),
];

// ─────────────────────────────────────────────
// ROOT NAVIGATION
// ─────────────────────────────────────────────

class RootNavigation extends StatefulWidget {
  final String userId;
  final String houseId;

  const RootNavigation({
    super.key,
    required this.userId,
    required this.houseId,
  });

  @override
  State<RootNavigation> createState() => _RootNavigationState();
}

class _RootNavigationState extends State<RootNavigation>
    with TickerProviderStateMixin {

  int _current  = 0;
  int _previous = 0;

  late final List<AnimationController> _controllers = List.generate(
    _navItems.length,
    (_) => AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      lowerBound: 0.0,
      upperBound: 2.0,
    ),
  );

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].value = (i == 0) ? 1.0 : 2.0;
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _navigateTo(int index) {
    if (index == _current) return;
    SoundService.instance.playSwipe(); 
    
    bool goingRight = index > _current;
    if (_current == _navItems.length - 1 && index == 0) {
      goingRight = true;
    } else if (_current == 0 && index == _navItems.length - 1) {
      goingRight = false;
    }

    setState(() {
      _previous = _current;
      _current  = index;
    });

    _controllers[_previous].animateTo(
      goingRight ? 0.0 : 2.0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );

    _controllers[index].value = goingRight ? 2.0 : 0.0;
    _controllers[index].animateTo(
      1.0,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:  return HomeScreen(userId: widget.userId, houseId: widget.houseId);
      case 1:  return BillsScreen(houseId: widget.houseId, currentUserId: widget.userId, houseName: '', avatarIndex: 0);
      case 2:  return CalendarScreen(houseId: widget.houseId, currentUserId: widget.userId, houseName: '', avatarIndex: 0);
      default: return const _PlaceholderScreen(label: '?');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          for (int i = 0; i < _navItems.length; i++)
            AnimatedBuilder(
              animation: _controllers[i],
              builder: (_, child) {
                final offsetX =
                    (_controllers[i].value - 1.0) * MediaQuery.of(context).size.width;
                return Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(offsetX, 0),
                    child: child,
                  ),
                );
              },
              child: _buildScreen(i),
            ),

          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _BeltNavBar(
              currentIndex: _current,
              onNavigate:   _navigateTo,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BELT-CONVEYOR NAV BAR
// ─────────────────────────────────────────────

class _BeltNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigate;

  const _BeltNavBar({
    required this.currentIndex,
    required this.onNavigate,
  });

  @override
  State<_BeltNavBar> createState() => _BeltNavBarState();
}

class _BeltNavBarState extends State<_BeltNavBar>
    with SingleTickerProviderStateMixin {

  // Figma nav panel: 360×75, r=30, three 120px slots
  static const double slotW = 120.0;
  static const double slotH = 58.0;
  static const double _barW = slotW * 3;
  static const double _barH = 75.0;
  static const double _barRadius = 30.0;

  late final AnimationController _ctrl;
  late Animation<double> _anim;
  double _offset = 0;

  @override
  void initState() {
    super.initState();
    _ctrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _offset = _targetFor(widget.currentIndex);
    _anim   = AlwaysStoppedAnimation(_offset);
  }

  @override
  void didUpdateWidget(_BeltNavBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _slideToIndex(widget.currentIndex, old.currentIndex);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double _targetFor(int i) {
    const int middle = 15;
    return -((middle + i) * slotW);
  }

  void _slideToIndex(int to, int from) {
    final int n  = _navItems.length;
    int delta    = to - from;
    if (delta >  n ~/ 2) delta -= n;
    if (delta < -(n ~/ 2)) delta += n;

    final double fromOff = _offset;
    final double toOff   = fromOff + delta * slotW * -1;

    _ctrl.reset();
    _anim = Tween<double>(begin: fromOff, end: toOff).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic),
    );
    _ctrl.forward().then((_) {
      _offset = _targetFor(to);
      _anim   = AlwaysStoppedAnimation(_offset);
      if (mounted) setState(() {});
    });
    _offset = toOff;
  }

  void _onTap(TapUpDetails d) {
    final int n = _navItems.length;
    if (d.localPosition.dx < _barW / 2) {
      widget.onNavigate((widget.currentIndex - 1 + n) % n);
    } else {
      widget.onNavigate((widget.currentIndex + 1) % n);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int n = _navItems.length;

    return SafeArea(
      top: false,
      child: Center(
        child: GestureDetector(
          onTapUp: _onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            width: _barW,
            height: _barH,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_barRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_barRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_barRadius),
                    color: const Color(0xFF161823).withValues(alpha: 0.42),
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.1,
                      colors: [
                        const Color(0x33E3F6FF),
                        const Color(0x1AD7D7D7),
                        const Color(0x33161823),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _anim,
                        builder: (_, __) {
                          final double dx =
                              _anim.value + (_barW / 2) - (slotW / 2);

                          final List<Widget> slots = List.generate(30, (i) {
                            final int idx = i % n;
                            final bool active = idx == widget.currentIndex;
                            return _Slot(
                              item: _navItems[idx],
                              active: active,
                            );
                          });

                          return Transform.translate(
                            offset: Offset(dx, 0),
                            child: OverflowBox(
                              maxWidth: double.infinity,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: slots,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// SLOT — single icon cell on the belt
// ─────────────────────────────────────────────

class _Slot extends StatelessWidget {
  final _NavItem item;
  final bool active;

  const _Slot({required this.item, required this.active});

  @override
  Widget build(BuildContext context) {
    final w = active ? item.activeW : item.inactiveW;
    final h = active ? item.activeH : item.inactiveH;

    return SizedBox(
      width: _BeltNavBarState.slotW,
      height: _BeltNavBarState.slotH,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          width: w,
          height: h,
          child: SvgPicture.asset(
            active ? item.activeAsset : item.inactiveAsset,
            width: w,
            height: h,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PLACEHOLDER SCREENS
// ─────────────────────────────────────────────-

class _PlaceholderScreen extends StatelessWidget {
  final String label;
  const _PlaceholderScreen({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Text(
          label,
          style: const TextStyle(
            color:        Color(0xFF6B6892),
            fontSize:     22,
            fontWeight:   FontWeight.w500,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}