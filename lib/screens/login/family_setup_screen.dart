import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../theme.dart';
import 'login_widgets.dart';
import '../../services/firestore_service.dart';

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
  final _firestoreService = FirestoreService();

  Future<void> _createBirthdayEventIfNeeded(String houseId) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .get();
    final data = userDoc.data();
    final birthdayTs = data?['birthday'] ?? data?['dateOfBirth'];
    if (birthdayTs is! Timestamp) return;

    await _firestoreService.addBirthdayEvent(
      houseId: houseId,
      currentUserId: widget.uid,
      userName: widget.userName,
      birthday: birthdayTs.toDate(),
    );
  }

  bool _isCreating = true;
  final _familyNameCtrl = TextEditingController();
  final _inviteCodeCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  
  String? _createdCode;
  String? _createdHouseId;

  @override
  void dispose() {
    _familyNameCtrl.dispose();
    _inviteCodeCtrl.dispose();
    super.dispose();
  }

  

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; 
    final random = Random.secure();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  

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

  
  
  Future<void> _finalizeCreate() async {
    if (_createdHouseId == null) return;
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({'houseId': _createdHouseId});
      await _createBirthdayEventIfNeeded(_createdHouseId!);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
      if (mounted) setState(() => _loading = false);
    }
  }

  

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
      final requireApproval =
          houseDoc.data()['requireApproval'] as bool? ?? false;

      final batch = FirebaseFirestore.instance.batch();
      if (requireApproval) {
        // Owner must approve — place in pending queue only.
        batch.update(houseDoc.reference, {
          'pendingMembers': FieldValue.arrayUnion([widget.uid]),
        });
        batch.update(
          FirebaseFirestore.instance.collection('users').doc(widget.uid),
          {'pendingHouseId': houseDoc.id},
        );
      } else {
        // Direct join.
        batch.update(houseDoc.reference, {
          'members': FieldValue.arrayUnion([widget.uid]),
        });
        batch.update(
          FirebaseFirestore.instance.collection('users').doc(widget.uid),
          {'houseId': houseDoc.id},
        );
      }
      await batch.commit();
      if (!requireApproval) {
        await _createBirthdayEventIfNeeded(houseDoc.id);
      }
    } on FirebaseException catch (_) {
      setState(() => _error = 'Could not join family. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoginTokens.screenBg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const LoginScreenBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: LoginTokens.horizontalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 44),
                  const Center(child: LoginCatLogo()),
                  const SizedBox(height: 36),
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

  

  Widget _buildCreatePanel() {
    
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
        LoginGradientField(
          controller: _familyNameCtrl,
          label: 'e.g.  The Dream House',
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          LoginErrorBanner(message: _error!),
        ],
        const SizedBox(height: 28),
        LoginPrimaryButton(
          label: 'Create Home',
          loading: _loading,
          onPressed: _createFamily,
        ),
      ],
    );
  }

  
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
          LoginErrorBanner(message: _error!),
        ],
        const SizedBox(height: 24),
        LoginPrimaryButton(
          label: "Let's Go!",
          loading: _loading,
          onPressed: _finalizeCreate,
        ),
      ],
    );
  }

  

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
        LoginGradientField(
          controller: _inviteCodeCtrl,
          label: 'Invite Code',
          allCaps: true,
          maxLength: 6,
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          LoginErrorBanner(message: _error!),
        ],
        const SizedBox(height: 28),
        LoginPrimaryButton(
          label: 'Join Home',
          loading: _loading,
          onPressed: _joinFamily,
        ),
      ],
    );
  }
}



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
