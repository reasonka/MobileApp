import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/sound_service.dart';
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
            GestureDetector(
              onTap: () {
                SoundService.instance.playPop();
                Navigator.pop(context);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SvgPicture.asset(
                  SettingsTokens.iconAsset('back'),
                  width: 13,
                  height: 25,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.55),
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
          color: const Color(0xFF555577),
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
                      color: Colors.white,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.55),
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
                        color: Colors.white,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.55),
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
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.4),
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
                    color: Colors.white,
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
                        : Colors.white.withValues(alpha: 0.35),
                    width: 2,
                  ),
                  color: selected
                      ? const Color(0xFFE040FB)
                      : Colors.transparent,
                ),
                child: selected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Notifications ────────────────────────────────────────────────────────────

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

// ── Security ─────────────────────────────────────────────────────────────────

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
            const Text('🔐', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              'Password reset',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
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
                          style: GoogleFonts.poppins(color: Colors.white),
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
                    color: Colors.white,
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

// ── Privacy ──────────────────────────────────────────────────────────────────

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
                  style: GoogleFonts.poppins(color: Colors.white),
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

// ── Theme ────────────────────────────────────────────────────────────────────

enum _AppTheme { dark, light, system }

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  _AppTheme _selected = _AppTheme.dark;

  @override
  Widget build(BuildContext context) {
    return SettingsSubpageScaffold(
      title: 'Theme',
      subtitle: 'Homie looks best in dark mode — but the choice is yours.',
      children: [
        SettingsChoiceRow(
          label: 'Dark',
          selected: _selected == _AppTheme.dark,
          onTap: () => setState(() => _selected = _AppTheme.dark),
        ),
        SettingsChoiceRow(
          label: 'Light',
          selected: _selected == _AppTheme.light,
          onTap: () {
            setState(() => _selected = _AppTheme.light);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Light theme coming soon',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.white),
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
        SettingsChoiceRow(
          label: 'Match system',
          selected: _selected == _AppTheme.system,
          onTap: () {
            setState(() => _selected = _AppTheme.system);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'System theme coming soon',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.white),
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

// ── Help ─────────────────────────────────────────────────────────────────────

class HelpSettingsScreen extends StatefulWidget {
  const HelpSettingsScreen({super.key});

  @override
  State<HelpSettingsScreen> createState() => _HelpSettingsScreenState();
}

class _HelpSettingsScreenState extends State<HelpSettingsScreen> {
  String? _expanded;

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
  Widget build(BuildContext context) {
    return SettingsSubpageScaffold(
      title: 'Help',
      subtitle: 'Quick answers and ways to reach us.',
      children: [
        const SettingsSectionLabel(label: 'FAQ'),
        ..._faqs.map((faq) {
          final open = _expanded == faq.$1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                SoundService.instance.playPop();
                setState(() => _expanded = open ? null : faq.$1);
              },
              child: SettingsGradientPanel(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Icon(
                          open
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                    if (open) ...[
                      const SizedBox(height: 10),
                      Text(
                        faq.$2,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.6),
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

// ── Add account ──────────────────────────────────────────────────────────────

class AddAccountSettingsScreen extends StatelessWidget {
  const AddAccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSubpageScaffold(
      title: 'Add account',
      subtitle: 'Switch between households or sign in with another email.',
      children: [
        SettingsGradientPanel(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.switch_account_rounded,
                  color: Color(0xFFE040FB), size: 48),
              const SizedBox(height: 16),
              Text(
                'Multi-account support is on the way',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'For now, log out and sign in with a different email to join another house.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.55),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
