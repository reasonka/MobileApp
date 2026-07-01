import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';
import 'login_widgets.dart';

/// Shown when a user has entered a valid invite code but the house requires
/// owner approval before they can join.
class PendingApprovalScreen extends StatefulWidget {
  final String userId;
  final String pendingHouseId;

  const PendingApprovalScreen({
    super.key,
    required this.userId,
    required this.pendingHouseId,
  });

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  bool _cancelling = false;

  Future<void> _cancel() async {
    setState(() => _cancelling = true);
    try {
      await FirestoreService()
          .cancelPendingRequest(widget.pendingHouseId, widget.userId);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
    // AuthGate reacts automatically once pendingHouseId is removed from Firestore.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Stack(
        children: [
          const LoginScreenBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.pink.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.hourglass_top_rounded,
                        color: AppColors.pink, size: 38),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Waiting for approval',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your request to join this house has been sent.\n'
                    'The house owner needs to accept you before you can continue.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Live status indicator
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('houses')
                        .doc(widget.pendingHouseId)
                        .snapshots(),
                    builder: (context, snap) {
                      final pending = List<String>.from(
                          snap.data?.data()?['pendingMembers'] ?? []);
                      final isStillPending =
                          pending.contains(widget.userId);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isStillPending
                              ? Colors.orange.withOpacity(0.12)
                              : Colors.green.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isStillPending
                                ? Colors.orange.withOpacity(0.35)
                                : Colors.green.withOpacity(0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isStillPending
                                  ? Icons.pending_outlined
                                  : Icons.check_circle_outline,
                              color: isStillPending
                                  ? Colors.orange
                                  : Colors.green,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isStillPending
                                  ? 'Pending owner review'
                                  : 'Approved! Loading…',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isStillPending
                                    ? Colors.orange
                                    : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  // Cancel request button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: Colors.white.withOpacity(0.2)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _cancelling ? null : _cancel,
                      child: _cancelling
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.pink),
                            )
                          : Text(
                              'Cancel request',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
