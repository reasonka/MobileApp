import 'package:flutter/material.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform,
  );
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

const Color _bg        = Color(0xFF0D0D1A);
const Color _navBg     = Color(0xFF14142A);
const Color _navBorder = Color(0xFF2E2E50);
const Color _pink      = Color(0xFFE040FB);
const Color _inactive  = Color(0xFF6B6892);

// ─────────────────────────────────────────────
// NAV ITEMS
// ─────────────────────────────────────────────

class _NavItem {
  final String imagePath;
  const _NavItem({required this.imagePath});
}

const List<_NavItem> _navItems = [
  _NavItem(imagePath: 'assets/images/homeIcon.png'),
  _NavItem(imagePath: 'assets/images/coinIcon.png'),
  _NavItem(imagePath: 'assets/images/calendarIcon.png'),
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

  static const double slotW = 120.0;
  static const double slotH = 70.0;        // taller slots
  static const double _barW = slotW * 3 + 40;
  static const double _barH = slotH + 24;  // taller bar

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
            margin: const EdgeInsets.fromLTRB(0, 0, 0, 14),
            width:  _barW,
            height: _barH,
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('assets/images/BottomNavBG.png'),
                fit: BoxFit.fill,
              ),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: _navBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Stack(
                alignment: Alignment.center,
                children: [

                  // ── Fixed center highlight pill ──────────
                  // Container(
                  //   width:  slotW,
                  //   height: slotH,
                  //   decoration: BoxDecoration(
                  //     color: _pink.withValues(alpha: 0.18),
                  //     borderRadius: BorderRadius.circular(24),
                  //     border: Border.all(
                  //       color: _pink.withValues(alpha: 0.55),
                  //       width: 1.2,
                  //     ),
                  //   ),
                  // ),

                  // ── Sliding icon belt ────────────────────
                  AnimatedBuilder(
                    animation: _anim,
                    builder: (_, __) {
                      final double dx = _anim.value + (_barW / 2) - (slotW / 2);

                      final List<Widget> slots = List.generate(30, (i) {
                        final int idx    = i % n;
                        final bool active = idx == widget.currentIndex;
                        return _Slot(
                          imagePath: _navItems[idx].imagePath,
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
    );
  }
}

// ─────────────────────────────────────────────
// SLOT — single icon cell on the belt
// ─────────────────────────────────────────────

class _Slot extends StatelessWidget {
  final String imagePath;
  final bool   active;
  const _Slot({required this.imagePath, required this.active});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:  _BeltNavBarState.slotW,
      height: _BeltNavBarState.slotH,
      child: Center(
        child: AnimatedScale(
          scale: active ? 2 : 1.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          child: ColorFiltered(
            colorFilter: active
                ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                : ColorFilter.mode(
                    Colors.white.withValues(alpha: 0.6),
                    BlendMode.srcATop,
                  ),
            child: Image.asset(
              imagePath,
              width:  40,
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PLACEHOLDER SCREENS
// ─────────────────────────────────────────────

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