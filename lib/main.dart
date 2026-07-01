import 'dart:async';
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
import 'screens/map/map_screen.dart';
import 'screens/login/login_screen.dart';
import 'screens/login/profile_setup_screen.dart';
import 'screens/login/family_setup_screen.dart';
import 'screens/login/pending_approval_screen.dart';
// ignore: unused_import
import 'firebase_options.dart';
import 'services/firestore_service.dart';
import 'services/sound_service.dart';
import 'services/notification_service.dart'; 
import 'services/location_service.dart'; 
import 'services/inbox_listener.dart';
import 'screens/home/home_widgets.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/profile_screen.dart';
import 'theme.dart';





void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform,
  );
  

  await SoundService.instance.preload();
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermissions();

  InboxListener.instance.start(FirebaseAuth.instance.currentUser?.uid ?? '');

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
                // Awaiting owner approval for a specific house.
                final pendingId = data['pendingHouseId'] as String?;
                if (pendingId != null && pendingId.isNotEmpty) {
                  return PendingApprovalScreen(
                    userId: user.uid,
                    pendingHouseId: pendingId,
                  );
                }
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
  _NavItem(
    activeAsset: 'assets/images/nav/map_active.svg',
    inactiveAsset: 'assets/images/nav/map_inactive.svg',
    inactiveW: 44, inactiveH: 44, activeW: 56, activeH: 58,
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

  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _navItems.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
        lowerBound: 0.0,
        upperBound: 2.0,
      ),
    );
    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].value = (i == 0) ? 1.0 : 2.0;
    }

    LocationService.instance.start(
      userId: widget.userId,
      houseId: widget.houseId,
    );
    InboxListener.instance.start(widget.userId);
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    LocationService.instance.stop();
    InboxListener.instance.stop(); 
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

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top + kGlobalTopBarHeight;

    // Local helper so it has access to context (for MediaQuery top padding).
    Widget buildScreen(int index) {
      switch (index) {
        case 0:
          // HomeScreen manages its own top spacer internally.
          return HomeScreen(userId: widget.userId, houseId: widget.houseId);
        case 1:
          return Padding(
            padding: EdgeInsets.only(top: topPad),
            child: BillsScreen(
              houseId: widget.houseId,
              currentUserId: widget.userId,
              houseName: '',
              avatarIndex: 0,
            ),
          );
        case 2:
          return Padding(
            padding: EdgeInsets.only(top: topPad),
            child: CalendarScreen(
              houseId: widget.houseId,
              currentUserId: widget.userId,
              houseName: '',
              avatarIndex: 0,
            ),
          );
        case 3:
          return Padding(
            padding: EdgeInsets.only(top: topPad),
            child: MapScreen(
              houseId: widget.houseId,
              currentUserId: widget.userId,
            ),
          );
        default:
          return const _PlaceholderScreen(label: '?');
      }
    }

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
              child: buildScreen(i),
            ),

          // ── Static global top bar — never moves ───────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: _GlobalTopBar(
              userId:  widget.userId,
              houseId: widget.houseId,
            ),
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

// ─────────────────────────────────────────────
// RESPONSIVE NAV BAR (replaces belt-conveyor version)
// ─────────────────────────────────────────────

class _BeltNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigate;

  const _BeltNavBar({
    required this.currentIndex,
    required this.onNavigate,
  });

  static const double _barH = 75.0;
  static const double _barRadius = 30.0;
  static const double _horizontalMargin = 16.0;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double barWidth = screenWidth - (_horizontalMargin * 2);
    final double slotW = barWidth / _navItems.length;

    return SafeArea(
      top: false,
      child: Center(
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          width: barWidth,
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
                    colors: const [
                      Color(0x33E3F6FF),
                      Color(0x1AD7D7D7),
                      Color(0x33161823),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOutCubic,
                      left: currentIndex * slotW + (slotW - slotW * 0.78) / 2,
                      top: (_barH - 58) / 2,
                      child: Container(
                        width: slotW * 0.78,
                        height: 58,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE040FB).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFE040FB).withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(_navItems.length, (i) {
                        final bool active = i == currentIndex;
                        return SizedBox(
                          width: slotW,
                          height: _barH,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onNavigate(i),
                            child: Center(
                              child: _Slot(item: _navItems[i], active: active),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
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
// SLOT — single icon cell on the bar
// ─────────────────────────────────────────────

class _Slot extends StatelessWidget {
  final _NavItem item;
  final bool active;

  const _Slot({required this.item, required this.active});

  @override
  Widget build(BuildContext context) {
    final w = active ? item.activeW : item.inactiveW;
    final h = active ? item.activeH : item.inactiveH;

    return AnimatedContainer(
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
    );
  }
}

// ─────────────────────────────────────────────
// GLOBAL STATIC TOP BAR
// ─────────────────────────────────────────────

class _GlobalTopBar extends StatefulWidget {
  final String userId;
  final String houseId;

  const _GlobalTopBar({required this.userId, required this.houseId});

  @override
  State<_GlobalTopBar> createState() => _GlobalTopBarState();
}

class _GlobalTopBarState extends State<_GlobalTopBar> {
  final FirestoreService _fs = FirestoreService();

  String _houseName   = '';
  int    _avatarIndex = 0;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _avatarSub;

  @override
  void initState() {
    super.initState();
    _loadData();
    _listenAvatar();
  }

  Future<void> _loadData() async {
    final house   = await _fs.getHouseData(widget.houseId);
    final members = await _fs.getHouseMemberDetails(widget.houseId);
    final me = members.firstWhere(
      (m) => m['userId'] == widget.userId,
      orElse: () => <String, dynamic>{'avatarIndex': 0},
    );
    if (mounted) {
      setState(() {
        _houseName   = (house?['name'] as String?) ?? 'Our House';
        _avatarIndex = me['avatarIndex'] as int? ?? 0;
      });
    }
  }

  void _listenAvatar() {
    _avatarSub = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .snapshots()
        .listen((doc) {
      if (!mounted) return;
      final data = doc.data() ?? {};
      setState(() {
        _avatarIndex = data['avatarIndex'] as int? ?? _avatarIndex;
      });
    });
  }

  @override
  void dispose() {
    _avatarSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double statusH = MediaQuery.of(context).padding.top;

    return Container(
      height: statusH + kGlobalTopBarHeight,
      // Solid background so scrolling content from screens never shows through.
      color: HomeTokens.screenBg,
      child: Stack(
        children: [
          // Background panel image (same as HouseAppBar)
          Positioned.fill(
            child: Image.asset(
              'assets/images/TopPanel.png',
              fit: BoxFit.fill,
            ),
          ),
          // Content row, placed below the status bar
          Positioned(
            left: 0, right: 0,
            top: statusH,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Tappable avatar → profile screen
                  GestureDetector(
                    onTap: () {
                      SoundService.instance.playPop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(
                            userId: widget.userId,
                            houseId: widget.houseId,
                          ),
                        ),
                      );
                    },
                    child: HomeCatAvatar(avatarIndex: _avatarIndex, size: 42),
                  ),
                  const SizedBox(width: 8),
                  // House name with gradient shader
                  Expanded(
                    child: _houseName.isEmpty
                        ? const SizedBox.shrink()
                        : ShaderMask(
                            shaderCallback: (bounds) =>
                                HomeTokens.houseTitleGradient.createShader(bounds),
                            child: Text(
                              _houseName.toUpperCase(),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: _houseName.length > 14
                                    ? _houseName.length > 20 ? 13.0 : 22.0
                                    : 32.0,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: _houseName.length > 14 ? -0.5 : -1.5,
                                height: 1.1,
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  // Tappable settings icon → settings screen
                  GestureDetector(
                    onTap: () {
                      SoundService.instance.playPop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SettingsScreen(
                            userId: widget.userId,
                            houseId: widget.houseId,
                          ),
                        ),
                      );
                    },
                    child: SvgPicture.asset(
                      'assets/images/home/settings.svg',
                      width: 40,
                      height: 40,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ],
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