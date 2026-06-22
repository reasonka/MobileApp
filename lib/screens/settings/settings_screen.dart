import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../home/home_widgets.dart';
import 'settings_widgets.dart';

class SettingsScreen extends StatefulWidget {
  final String userId;
  final String houseId;

  const SettingsScreen({
    super.key,
    required this.userId,
    required this.houseId,
  });

  static void open(
    BuildContext context, {
    required String userId,
    required String houseId,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(userId: userId, houseId: houseId),
      ),
    );
  }

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _fs = FirestoreService();
  final _searchCtrl = TextEditingController();

  String _userName = '';
  String _houseName = '';
  String _inviteCode = '';
  int _avatarIndex = 0;
  bool _loading = true;
  String _query = '';

  static const _menuItems = [
    _SettingsItem('Account', 'assets/images/settings/account.svg'),
    _SettingsItem('Notifications', 'assets/images/settings/notifications.svg'),
    _SettingsItem('Security', 'assets/images/settings/security.svg'),
    _SettingsItem('Privacy', 'assets/images/settings/privacy.svg'),
    _SettingsItem('Theme', 'assets/images/settings/theme.svg'),
    _SettingsItem('Help', 'assets/images/settings/help.svg'),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final members = await _fs.getHouseMemberDetails(widget.houseId);
    final house = await _fs.getHouseData(widget.houseId);
    final me = members.firstWhere(
      (m) => m['userId'] == widget.userId,
      orElse: () => {'name': 'User', 'avatarIndex': 0},
    );

    if (mounted) {
      setState(() {
        _userName = me['name'] as String? ?? 'User';
        _avatarIndex = me['avatarIndex'] as int? ?? 0;
        _houseName = (house?['name'] as String?) ?? 'Our House';
        _inviteCode = (house?['inviteCode'] as String?) ?? '';
        _loading = false;
      });
    }
  }

  List<_SettingsItem> get _filteredMenuItems {
    if (_query.trim().isEmpty) return _menuItems;
    final q = _query.trim().toLowerCase();
    return _menuItems
        .where((item) => item.label.toLowerCase().contains(q))
        .toList();
  }

  bool get _showFamilyLink {
    if (_query.trim().isEmpty) return true;
    return 'family link'.contains(_query.trim().toLowerCase()) ||
        'add your housemates'.contains(_query.trim().toLowerCase());
  }

  bool get _showBottomActions {
    if (_query.trim().isEmpty) return true;
    final q = _query.trim().toLowerCase();
    return 'add account'.contains(q) || 'log out'.contains(q);
  }

  Future<void> _logOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log out?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'You will need to sign in again to access your house.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  void _onMenuTap(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label — coming soon'),
        backgroundColor: const Color(0xFF1A1A2E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeTokens.screenBg,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFE040FB)),
              )
            : ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: SettingsTokens.horizontalPadding,
                ),
                children: [
                  Row(
                    children: [
                      SettingsBackButton(
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SettingsSearchBar(controller: _searchCtrl),
                  const SizedBox(height: 22),
                  SettingsAccountHeader(
                    userName: _userName,
                    houseName: _houseName,
                    avatarIndex: _avatarIndex,
                    inviteCode:
                        _inviteCode.isNotEmpty ? _inviteCode : null,
                  ),
                  const SizedBox(height: 24),
                  ..._filteredMenuItems.map(
                    (item) => SettingsMenuRow(
                      iconAsset: item.iconAsset,
                      label: item.label,
                      onTap: () => _onMenuTap(item.label),
                    ),
                  ),
                  if (_showFamilyLink && _inviteCode.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SettingsFamilyLinkCard(inviteCode: _inviteCode),
                  ],
                  if (_showBottomActions) ...[
                    const SizedBox(height: 16),
                    SettingsMenuRow(
                      iconAsset: 'assets/images/settings/add_account.svg',
                      label: 'Add account',
                      onTap: () => _onMenuTap('Add account'),
                    ),
                    SettingsMenuRow(
                      iconAsset: 'assets/images/settings/logout.svg',
                      label: 'Log Out',
                      onTap: _logOut,
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }
}

class _SettingsItem {
  final String label;
  final String iconAsset;

  const _SettingsItem(this.label, this.iconAsset);
}
