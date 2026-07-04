import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../services/firestore_service.dart';
import '../../services/sound_service.dart';
import '../../services/saved_accounts_service.dart';
import '../../services/theme_service.dart';
import '../../theme.dart';
import '../home/home_widgets.dart';
import 'settings_widgets.dart';

class SettingsSubpageScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const SettingsSubpageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SettingsTokens.screenBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: SettingsTokens.horizontalPadding,
          ),
          children: [
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () {
                  SoundService.instance.playPop();
                  Navigator.pop(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SettingsBackIcon(width: 13, height: 25),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 24),
            ...children,
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class SettingsSectionLabel extends StatelessWidget {
  final String label;

  const SettingsSectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10, top: 4),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class SettingsToggleRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsToggleRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SettingsGradientPanel(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onPanel,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.onPanelSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              activeTrackColor: const Color(0xFFE040FB),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
              onChanged: (v) {
                SoundService.instance.playPop();
                onChanged(v);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsActionRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? trailing;
  final VoidCallback onTap;

  const SettingsActionRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          SoundService.instance.playPop();
          onTap();
        },
        child: SettingsGradientPanel(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onPanel,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.onPanelSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.onPanelSecondary,
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.onPanelMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsChoiceRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const SettingsChoiceRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          SoundService.instance.playPop();
          onTap();
        },
        child: SettingsGradientPanel(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onPanel,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? const Color(0xFFE040FB)
                        : AppColors.onPanelMuted,
                    width: 2,
                  ),
                  color: selected
                      ? const Color(0xFFE040FB)
                      : Colors.transparent,
                ),
                child: selected
                    ? Icon(Icons.check, color: AppColors.onPanel, size: 14)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool _choreReminders = true;
  bool _xpVotes = true;
  bool _newNotes = true;
  bool _houseActivity = false;
  bool _weeklyDigest = true;

  @override
  Widget build(BuildContext context) {
    return SettingsSubpageScaffold(
      title: 'Notifications',
      subtitle: 'Choose what Homie should nudge you about.',
      children: [
        const SettingsSectionLabel(label: 'Chores & house'),
        SettingsToggleRow(
          title: 'Chore reminders',
          subtitle: 'Get reminded before chores are due',
          value: _choreReminders,
          onChanged: (v) => setState(() => _choreReminders = v),
        ),
        SettingsToggleRow(
          title: 'House activity',
          subtitle: 'When someone completes a chore or earns XP',
          value: _houseActivity,
          onChanged: (v) => setState(() => _houseActivity = v),
        ),
        SettingsToggleRow(
          title: 'New notes',
          subtitle: 'When a housemate posts a note',
          value: _newNotes,
          onChanged: (v) => setState(() => _newNotes = v),
        ),
        const SettingsSectionLabel(label: 'Leaderboard'),
        SettingsToggleRow(
          title: 'XP votes',
          subtitle: 'When someone votes on your chore XP',
          value: _xpVotes,
          onChanged: (v) => setState(() => _xpVotes = v),
        ),
        const SettingsSectionLabel(label: 'Summary'),
        SettingsToggleRow(
          title: 'Weekly digest',
          subtitle: 'A Sunday recap of your house',
          value: _weeklyDigest,
          onChanged: (v) => setState(() => _weeklyDigest = v),
        ),
      ],
    );
  }
}



class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _biometric = false;

  void _showPasswordDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🔐', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              'Password reset',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.onPanel,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We\'ll send a reset link to your email address.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFFB0ADCC),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE040FB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  final email = FirebaseAuth.instance.currentUser?.email;
                  if (email != null) {
                    await FirebaseAuth.instance
                        .sendPasswordResetEmail(email: email);
                  }
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Reset link sent',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: AppColors.onPanel),
                        ),
                        backgroundColor: const Color(0xFF1A1A2E),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    );
                },
                child: Text(
                  'Send link',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onPanel,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '—';

    return SettingsSubpageScaffold(
      title: 'Security',
      subtitle: 'Keep your account safe.',
      children: [
        const SettingsSectionLabel(label: 'Sign in'),
        SettingsActionRow(
          title: 'Email',
          subtitle: email,
          onTap: () {},
        ),
        SettingsActionRow(
          title: 'Change password',
          subtitle: 'Send a reset link to your email',
          onTap: _showPasswordDialog,
        ),
        const SettingsSectionLabel(label: 'Device'),
        SettingsToggleRow(
          title: 'Biometric unlock',
          subtitle: 'Use Face ID or fingerprint to open Homie',
          value: _biometric,
          onChanged: (v) => setState(() => _biometric = v),
        ),
      ],
    );
  }
}



class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _showOnLeaderboard = true;
  bool _showBirthday = false;
  bool _analytics = true;

  @override
  Widget build(BuildContext context) {
    return SettingsSubpageScaffold(
      title: 'Privacy',
      subtitle: 'Control what your housemates can see.',
      children: [
        const SettingsSectionLabel(label: 'Profile'),
        SettingsToggleRow(
          title: 'Show on leaderboard',
          subtitle: 'Display your XP ranking to housemates',
          value: _showOnLeaderboard,
          onChanged: (v) => setState(() => _showOnLeaderboard = v),
        ),
        SettingsToggleRow(
          title: 'Share birthday',
          subtitle: 'Let housemates see your birthday on your profile',
          value: _showBirthday,
          onChanged: (v) => setState(() => _showBirthday = v),
        ),
        const SettingsSectionLabel(label: 'Data'),
        SettingsToggleRow(
          title: 'Usage analytics',
          subtitle: 'Help us improve Homie with anonymous usage data',
          value: _analytics,
          onChanged: (v) => setState(() => _analytics = v),
        ),
        SettingsActionRow(
          title: 'Download my data',
          subtitle: 'Request a copy of your account data',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'We\'ll email you when your export is ready',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: AppColors.onPanel),
                ),
                backgroundColor: const Color(0xFF1A1A2E),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}



class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  @override
  void initState() {
    super.initState();
    ThemeService.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeService.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  HomieThemePreference get _selected => ThemeService.instance.preference;

  Future<void> _select(HomieThemePreference value) async {
    await ThemeService.instance.setPreference(value);
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSubpageScaffold(
      title: 'Theme',
      subtitle: 'Homie looks best in dark mode — but the choice is yours.',
      children: [
        SettingsChoiceRow(
          label: 'Dark',
          selected: _selected == HomieThemePreference.dark,
          onTap: () => _select(HomieThemePreference.dark),
        ),
        SettingsChoiceRow(
          label: 'Light',
          selected: _selected == HomieThemePreference.light,
          onTap: () => _select(HomieThemePreference.light),
        ),
        SettingsChoiceRow(
          label: 'Match system',
          selected: _selected == HomieThemePreference.system,
          onTap: () => _select(HomieThemePreference.system),
        ),
      ],
    );
  }
}



class HelpSettingsScreen extends StatefulWidget {
  const HelpSettingsScreen({super.key});

  @override
  State<HelpSettingsScreen> createState() => _HelpSettingsScreenState();
}

class _HelpSettingsScreenState extends State<HelpSettingsScreen> {
  String? _expanded;

  static const _housemateFaqTitle = 'How to be a good housemate?';
  static const _youtubeVideoId = 'JNI1fWTlGwY';

  late final YoutubePlayerController _youtubeController;

  static const _faqs = [
    (
      'How do I invite housemates?',
      'Open Settings → Family Link and share the QR code or invite code with your housemates.',
    ),
    (
      'How does XP voting work?',
      'After completing a chore, housemates can vote on how much XP you earned. The majority decides.',
    ),
    (
      'Can I leave my house?',
      'Yes — contact support and we\'ll help you transfer or remove your account from the house.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _youtubeController = YoutubePlayerController.fromVideoId(
      videoId: _youtubeVideoId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        mute: false,
        enableCaption: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
      ),
    );
  }

  @override
  void dispose() {
    _youtubeController.close();
    super.dispose();
  }

  void _toggleFaq(String title) {
    SoundService.instance.playPop();
    final opening = _expanded != title;
    setState(() => _expanded = opening ? title : null);
    if (!opening || title != _housemateFaqTitle) {
      _youtubeController.pauseVideo();
    }
  }

  @override
  Widget build(BuildContext context) {
    final housemateOpen = _expanded == _housemateFaqTitle;

    return SettingsSubpageScaffold(
      title: 'Help',
      subtitle: 'Quick answers and ways to reach us.',
      children: [
        const SettingsSectionLabel(label: 'FAQ'),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SettingsGradientPanel(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _toggleFaq(_housemateFaqTitle),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _housemateFaqTitle,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onPanel,
                          ),
                        ),
                      ),
                      Icon(
                        housemateOpen
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.onPanelMuted,
                      ),
                    ],
                  ),
                ),
                if (housemateOpen) ...[
                  const SizedBox(height: 10),
                  Text(
                    'A short guide to living well with the people you share a home with.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.onPanel.withValues(alpha: 0.6),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: YoutubePlayer(
                      controller: _youtubeController,
                      backgroundColor: Colors.black,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        ..._faqs.map((faq) {
          final open = _expanded == faq.$1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => _toggleFaq(faq.$1),
              child: SettingsGradientPanel(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            faq.$1,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onPanel,
                            ),
                          ),
                        ),
                        Icon(
                          open
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.onPanelMuted,
                        ),
                      ],
                    ),
                    if (open) ...[
                      const SizedBox(height: 10),
                      Text(
                        faq.$2,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.onPanel.withValues(alpha: 0.6),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
        const SettingsSectionLabel(label: 'Support'),
        SettingsActionRow(
          title: 'Contact support',
          subtitle: 'support@homie.app',
          onTap: () {},
        ),
        SettingsActionRow(
          title: 'App version',
          trailing: '1.0.0',
          onTap: () {},
        ),
      ],
    );
  }
}



class AddAccountSettingsScreen extends StatefulWidget {
  final String currentUserId;
  final String currentEmail;
  final String userName;
  final int avatarIndex;

  const AddAccountSettingsScreen({
    super.key,
    required this.currentUserId,
    required this.currentEmail,
    required this.userName,
    required this.avatarIndex,
  });

  @override
  State<AddAccountSettingsScreen> createState() => _AddAccountSettingsScreenState();
}

class _AddAccountSettingsScreenState extends State<AddAccountSettingsScreen> {
  final _auth = FirebaseAuth.instance;
  List<SavedAccount> _accounts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await SavedAccountsService.instance.saveAccount(
      SavedAccount(
        uid: widget.currentUserId,
        email: widget.currentEmail,
        name: widget.userName,
        avatarIndex: widget.avatarIndex,
      ),
    );
    final accounts = await SavedAccountsService.instance.loadAccounts();
    if (mounted) {
      setState(() {
        _accounts = accounts;
        _loading = false;
      });
    }
  }

  Future<void> _signOutForSwitch({String? prefilledEmail}) async {
    if (prefilledEmail != null) {
      await SavedAccountsService.instance.setPendingSwitchEmail(prefilledEmail);
    }
    await _auth.signOut();
  }

  void _confirmAddAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Add another account?',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.onPanel,
          ),
        ),
        content: Text(
          'You\'ll be signed out so you can log in with a different email.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.onPanel.withValues(alpha: 0.6),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.onPanelMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              SoundService.instance.playPop();
              await _signOutForSwitch();
            },
            child: Text(
              'Continue',
              style: GoogleFonts.poppins(
                color: const Color(0xFFE040FB),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSwitchAccount(SavedAccount account) {
    if (account.uid == widget.currentUserId) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Switch to ${account.name}?',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.onPanel,
          ),
        ),
        content: Text(
          'You\'ll be signed out and asked to sign in as ${account.email}.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.onPanel.withValues(alpha: 0.6),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.onPanelMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              SoundService.instance.playPop();
              await _signOutForSwitch(prefilledEmail: account.email);
            },
            child: Text(
              'Switch',
              style: GoogleFonts.poppins(
                color: const Color(0xFFE040FB),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSubpageScaffold(
      title: 'Add account',
      subtitle: 'Switch between accounts or sign in with another email.',
      children: [
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFFE040FB)),
            ),
          )
        else ...[
          const SettingsSectionLabel(label: 'Saved accounts'),
          ..._accounts.map((account) {
            final isActive = account.uid == widget.currentUserId;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: isActive
                    ? null
                    : () {
                        SoundService.instance.playPop();
                        _confirmSwitchAccount(account);
                      },
                child: SettingsGradientPanel(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      HomeCatAvatar(
                        avatarIndex: account.avatarIndex,
                        size: 44,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              account.name.isNotEmpty ? account.name : 'Account',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onPanel,
                              ),
                            ),
                            Text(
                              account.email,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.onPanelSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE040FB).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Active',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFE040FB),
                            ),
                          ),
                        )
                      else
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.onPanelMuted,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              SoundService.instance.playPop();
              _confirmAddAccount();
            },
            child: SettingsGradientPanel(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.onPanelDivider,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Color(0xFFE040FB),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Add another account',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onPanel,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOUSE SETTINGS SCREEN  (owner only)
// ─────────────────────────────────────────────────────────────────────────────

class HouseSettingsScreen extends StatefulWidget {
  final String houseId;
  final String ownerId;

  const HouseSettingsScreen({
    super.key,
    required this.houseId,
    required this.ownerId,
  });

  @override
  State<HouseSettingsScreen> createState() => _HouseSettingsScreenState();
}

class _HouseSettingsScreenState extends State<HouseSettingsScreen> {
  final FirestoreService _fs = FirestoreService();

  static const _bg    = Color(0xFF0D0D1A);
  static const _card  = Color(0xFF1A1A2E);
  static const _pink  = Color(0xFFE040FB);
  static const _sec   = Color(0xFFB0ADCC);

  bool _requireApproval = false;
  String _houseName  = '';
  String _inviteCode = '';
  bool _editingName  = false;
  late final TextEditingController _nameCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(color: AppColors.onPanel)),
      backgroundColor: error ? Colors.redAccent : _card,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await _fs.updateHouseName(widget.houseId, name);
      _snack('House name updated');
      setState(() => _editingName = false);
    } catch (_) {
      _snack('Could not update name', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _regen() async {
    setState(() => _saving = true);
    try {
      final code = await _fs.regenerateInviteCode(widget.houseId);
      _snack('New code: $code');
    } catch (_) {
      _snack('Could not regenerate code', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _confirmRemove(Map<String, dynamic> member) {
    final name = member['name'] as String;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('👋', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 12),
            Text(
              'Remove $name?',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onPanel),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'They will need the invite code to rejoin.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: _sec, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AppColors.onPanelDivider),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel',
                      style: GoogleFonts.poppins(
                          color: _sec, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _fs.removeMember(
                        widget.houseId, member['userId'] as String);
                    _snack('$name removed');
                  },
                  child: Text('Remove',
                      style: GoogleFonts.poppins(
                          color: AppColors.onPanel,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: StreamBuilder<Map<String, dynamic>>(
          stream: _fs.houseStream(widget.houseId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: _pink));
            }
            final house = snap.data ?? {};
            _houseName      = (house['name'] as String?) ?? '';
            _inviteCode     = (house['inviteCode'] as String?) ?? '';
            _requireApproval =
                (house['requireApproval'] as bool?) ?? false;

            final memberIds =
                List<String>.from(house['members'] ?? []);
            final pendingIds =
                List<String>.from(house['pendingMembers'] ?? []);

            if (!_editingName) {
              _nameCtrl.text = _houseName;
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                // ── back button ──────────────────────────────────────
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      SoundService.instance.playPop();
                      Navigator.pop(context);
                    },
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: 8),
                      child: SettingsBackIcon(width: 13, height: 25),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'House Settings',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPanel,
                  ),
                ),
                Text(
                  'Only visible to you as the owner.',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.onPanel.withValues(alpha: 0.45)),
                ),
                const SizedBox(height: 28),

                // ── house name ───────────────────────────────────────
                _sectionLabel('House Name'),
                SettingsGradientPanel(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameCtrl,
                          onTap: () =>
                              setState(() => _editingName = true),
                          style: GoogleFonts.poppins(
                              color: AppColors.onPanel, fontSize: 16),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'House name…',
                            hintStyle: GoogleFonts.poppins(
                                color: AppColors.onPanelMuted, fontSize: 16),
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    vertical: 16),
                          ),
                        ),
                      ),
                      if (_editingName)
                        TextButton(
                          onPressed: _saving ? null : _saveName,
                          child: Text('Save',
                              style: GoogleFonts.poppins(
                                  color: _pink,
                                  fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── invite code ──────────────────────────────────────
                _sectionLabel('Invite Code'),
                SettingsGradientPanel(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _inviteCode.isEmpty ? '—' : _inviteCode,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onPanel,
                            letterSpacing: 6,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                              ClipboardData(text: _inviteCode));
                          _snack('Code copied!');
                        },
                        child: const Icon(Icons.copy_rounded,
                            color: _pink, size: 20),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _saving ? null : _regen,
                        child: const Icon(Icons.refresh_rounded,
                            color: _pink, size: 22),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 4, top: 6, bottom: 20),
                  child: Text(
                    'Regenerating the code invalidates the old one.',
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.onPanelMuted),
                  ),
                ),

                // ── require approval toggle ──────────────────────────
                _sectionLabel('Join Requests'),
                SettingsToggleRow(
                  title: 'Require my approval',
                  subtitle:
                      'New housemates wait for you to accept them before joining.',
                  value: _requireApproval,
                  onChanged: (v) async {
                    await _fs.setRequireApproval(widget.houseId, v);
                  },
                ),
                const SizedBox(height: 20),

                // ── pending requests ─────────────────────────────────
                if (pendingIds.isNotEmpty) ...[
                  _sectionLabel('Pending Requests (${pendingIds.length})'),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _fs.pendingMembersStream(widget.houseId),
                    builder: (context, pendSnap) {
                      final pending = pendSnap.data ?? [];
                      return Column(
                        children: pending
                            .map((m) => _PendingRow(
                                  member: m,
                                  onAccept: () async {
                                    await _fs.acceptMember(
                                        widget.houseId,
                                        m['userId'] as String);
                                    _snack('${m['name']} accepted!');
                                  },
                                  onReject: () async {
                                    await _fs.rejectMember(
                                        widget.houseId,
                                        m['userId'] as String);
                                    _snack('${m['name']} rejected.');
                                  },
                                ))
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // ── current members ──────────────────────────────────
                _sectionLabel('Members (${memberIds.length})'),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fs.getHouseMemberDetails(widget.houseId),
                  builder: (context, membSnap) {
                    final members = membSnap.data ?? [];
                    if (members.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: members.map((m) {
                        final isOwner =
                            m['userId'] == widget.ownerId;
                        return _MemberRow(
                          member: m,
                          isOwner: isOwner,
                          onRemove: isOwner
                              ? null
                              : () => _confirmRemove(m),
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10, top: 4),
        child: Text(
          text.toUpperCase(),
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF555577),
            letterSpacing: 1.2,
          ),
        ),
      );
}

// ── Pending request row ────────────────────────────────────────────────────

class _PendingRow extends StatelessWidget {
  final Map<String, dynamic> member;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _PendingRow({
    required this.member,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final name        = member['name'] as String;
    final avatarIndex = member['avatarIndex'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SettingsGradientPanel(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(
                child: Image.asset(
                  SettingsTokens.avatarAsset(avatarIndex),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onPanel,
                ),
              ),
            ),
            // Reject
            GestureDetector(
              onTap: () {
                SoundService.instance.playPop();
                onReject();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: Text('Reject',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.redAccent,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 8),
            // Accept
            GestureDetector(
              onTap: () {
                SoundService.instance.playPop();
                onAccept();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE040FB).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFE040FB)
                          .withValues(alpha: 0.3)),
                ),
                child: Text('Accept',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFFE040FB),
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Current member row ─────────────────────────────────────────────────────

class _MemberRow extends StatelessWidget {
  final Map<String, dynamic> member;
  final bool isOwner;
  final VoidCallback? onRemove;

  const _MemberRow({
    required this.member,
    required this.isOwner,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final name        = member['name'] as String;
    final avatarIndex = member['avatarIndex'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SettingsGradientPanel(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: ClipOval(
                child: Image.asset(
                  SettingsTokens.avatarAsset(avatarIndex),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onPanel,
                    ),
                  ),
                  if (isOwner)
                    Text(
                      'Owner',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFFE040FB),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            if (onRemove != null)
              GestureDetector(
                onTap: () {
                  SoundService.instance.playDelete();
                  onRemove!();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color:
                            Colors.redAccent.withValues(alpha: 0.25)),
                  ),
                  child: Text('Remove',
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
