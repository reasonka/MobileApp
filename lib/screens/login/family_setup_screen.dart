import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../theme.dart';

class FamilySetupScreen extends StatefulWidget {
  final String uid;
  final String userName;

  const FamilySetupScreen({
    super.key,
    required this.uid,
    required this.userName,
  });

  @override
  State<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends State<FamilySetupScreen> {
  // ── State ────────────────────────────────────────────────────────────────────

  bool _isCreating = true; // true = create mode, false = join mode
  final _familyNameCtrl = TextEditingController();
  final _inviteCodeCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  // After a family is successfully created, these are populated.
  String? _createdCode;
  String? _createdHouseId;

  @override
  void dispose() {
    _familyNameCtrl.dispose();
    _inviteCodeCtrl.dispose();
    super.dispose();
  }

  // ── Invite code generator ────────────────────────────────────────────────────

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no O/0, I/1 to avoid confusion
    final random = Random.secure();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  // ── Create family ────────────────────────────────────────────────────────────

  Future<void> _createFamily() async {
    final name = _familyNameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter a family name.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final code = _generateCode();
      final houseRef =
          await FirebaseFirestore.instance.collection('houses').add({
        'name': name,
        'inviteCode': code,
        'members': [widget.uid],
        'createdBy': widget.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _createdCode = code;
        _createdHouseId = houseRef.id;
      });
    } catch (_) {
      setState(() => _error = 'Could not create family. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Tap "Let's Go!" — links the user to the house they created, which makes
  // the AuthGate's Firestore stream detect houseId and route to RootNavigation.
  Future<void> _finalizeCreate() async {
    if (_createdHouseId == null) return;
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({'houseId': _createdHouseId});
      // AuthGate will now route to RootNavigation automatically
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Join family ──────────────────────────────────────────────────────────────

  Future<void> _joinFamily() async {
    final code = _inviteCodeCtrl.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _error = 'Please enter a valid 6-character invite code.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final query = await FirebaseFirestore.instance
          .collection('houses')
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        setState(() => _error = 'Invite code not found. Please check and try again.');
        return;
      }

      final houseDoc = query.docs.first;

      // Add user to the house and set their houseId in one batch
      final batch = FirebaseFirestore.instance.batch();
      batch.update(houseDoc.reference, {
        'members': FieldValue.arrayUnion([widget.uid]),
      });
      batch.update(
        FirebaseFirestore.instance.collection('users').doc(widget.uid),
        {'houseId': houseDoc.id},
      );
      await batch.commit();
      // AuthGate will now route to RootNavigation automatically
    } on FirebaseException catch (_) {
      setState(() => _error = 'Could not join family. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _buildGlowBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 52),
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildModeToggle(),
                  const SizedBox(height: 32),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isCreating
                        ? _buildCreatePanel()
                        : _buildJoinPanel(),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Background ───────────────────────────────────────────────────────────────

  Widget _buildGlowBackground() {
    return Stack(
      children: [
        Positioned(
          top: -60,
          left: 0,
          right: 0,
          child: Container(
            height: 260,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 0.9,
                colors: [
                  const Color(0xFFE040FB).withOpacity(0.30),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          left: 0,
          right: 0,
          child: Container(
            height: 260,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.bottomCenter,
                radius: 0.9,
                colors: [
                  const Color(0xFF1B5E20).withOpacity(0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Set up your\n',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              TextSpan(
                text: 'Home',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.pink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hi ${widget.userName}! Create a home or join an existing one.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ── Mode toggle (Create / Join) ───────────────────────────────────────────────

  Widget _buildModeToggle() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          _ToggleTab(
            label: 'Create a Home',
            selected: _isCreating,
            onTap: () => setState(() {
              _isCreating = true;
              _error = null;
              _createdCode = null;
              _createdHouseId = null;
            }),
          ),
          _ToggleTab(
            label: 'Join a Home',
            selected: !_isCreating,
            onTap: () => setState(() {
              _isCreating = false;
              _error = null;
            }),
          ),
        ],
      ),
    );
  }

  // ── Create panel ─────────────────────────────────────────────────────────────

  Widget _buildCreatePanel() {
    // If the family was just created, show the invite code + QR instead of the form
    if (_createdCode != null) {
      return _buildCodeReveal();
    }

    return Column(
      key: const ValueKey('create'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Give your home a name',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        _GradientPillField(
          controller: _familyNameCtrl,
          label: 'e.g.  The Dream House',
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          _buildErrorBanner(),
        ],
        const SizedBox(height: 28),
        _buildPrimaryButton(
          label: 'Create Home',
          onPressed: _createFamily,
        ),
      ],
    );
  }

  // Shows after a family is created — invite code + QR + "Let's Go!" button
  Widget _buildCodeReveal() {
    return Column(
      key: const ValueKey('code'),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Column(
            children: [
              Text(
                'Your invite code',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _createdCode!,
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 8,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _createdCode!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Code copied!',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                      backgroundColor: AppColors.cardBg,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.copy_rounded,
                        color: AppColors.pink, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Tap to copy',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.pink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // QR code (white background so it's scannable)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: QrImageView(
                  data: _createdCode!,
                  version: QrVersions.auto,
                  size: 180,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Share this with your housemates',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          _buildErrorBanner(),
        ],
        const SizedBox(height: 24),
        _buildPrimaryButton(
          label: "Let's Go!",
          onPressed: _finalizeCreate,
        ),
      ],
    );
  }

  // ── Join panel ───────────────────────────────────────────────────────────────

  Widget _buildJoinPanel() {
    return Column(
      key: const ValueKey('join'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Paste the invite code your housemate shared',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        _GradientPillField(
          controller: _inviteCodeCtrl,
          label: 'Invite Code',
          allCaps: true,
          maxLength: 6,
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          _buildErrorBanner(),
        ],
        const SizedBox(height: 28),
        _buildPrimaryButton(
          label: 'Join Home',
          onPressed: _joinFamily,
        ),
      ],
    );
  }

  // ── Shared UI ────────────────────────────────────────────────────────────────

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7B2DBD), AppColors.pink],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.pink.withOpacity(0.42),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Gradient pill text field ───────────────────────────────────────────────────

class _GradientPillField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool allCaps;
  final int? maxLength;

  const _GradientPillField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.allCaps = false,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3D1370), Color(0xFF7B2DBD)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        inputFormatters: allCaps
            ? [TextInputFormatter.withFunction(
                (old, next) => next.copyWith(text: next.text.toUpperCase()),
              )]
            : null,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 15,
          letterSpacing: allCaps ? 3.0 : 0.0,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          counterText: '',
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.white70, fontSize: 15),
          floatingLabelBehavior: FloatingLabelBehavior.never,
        ),
      ),
    );
  }
}

// ── Toggle tab button ─────────────────────────────────────────────────────────

class _ToggleTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFF7B2DBD), AppColors.pink],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
