import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/chore_model.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';

class NewChoreSheet extends StatefulWidget {
  final String userId;
  final String houseId;
  final List<Map<String, dynamic>> members; // {userId, name, avatarIndex}
  final int memberCount;
  /// Current user's own chores this week (used to enforce the 6-slot limit).
  final List<ChoreModel> myChores;

  const NewChoreSheet({
    super.key,
    required this.userId,
    required this.houseId,
    required this.members,
    required this.memberCount,
    required this.myChores,
  });

  @override
  State<NewChoreSheet> createState() => _NewChoreSheetState();
}

class _NewChoreSheetState extends State<NewChoreSheet> {
  final _titleCtrl = TextEditingController();
  late String _assignedTo;
  int _proposedXP = 5;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _assignedTo = widget.userId; // default: assign to self
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Please enter a chore name.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final fs = FirestoreService();

    try {
      // If adding this chore would exceed 6 total slots, remove the oldest
      // completed chore to make room (uncompleted guard already checked in the
      // button handler before the sheet opened).
      if (widget.myChores.length >= 6) {
        final completed = widget.myChores
            .where((c) => c.completed)
            .toList()
          ..sort((a, b) {
            final aTime = a.completedAt ?? a.createdAt;
            final bTime = b.completedAt ?? b.createdAt;
            return aTime.compareTo(bTime); // oldest first
          });
        final toDelete = widget.myChores.length - 5; // make exactly 1 free slot
        for (int i = 0; i < toDelete && i < completed.length; i++) {
          await fs.deleteChore(completed[i].choreId);
        }
      }

      await fs.addChore(
        title: title,
        assignedTo: _assignedTo,
        houseId: widget.houseId,
        createdBy: widget.userId,
        proposedXP: _proposedXP,
        memberCount: widget.memberCount,
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      setState(() => _error = 'Could not create chore. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 28,
        right: 28,
        top: 28,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'New Chore',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            widget.memberCount > 1
                ? 'Everyone will vote on the XP value'
                : 'XP is auto-agreed (solo house)',
            style: GoogleFonts.poppins(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Chore name
          _GradientField(
            controller: _titleCtrl,
            label: 'Chore name',
          ),
          const SizedBox(height: 16),

          // Assign to
          Text(
            'Assign to',
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.members.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final m = widget.members[i];
                final uid = m['userId'] as String;
                final name = m['name'] as String? ?? '';
                final selected = _assignedTo == uid;

                return GestureDetector(
                  onTap: () => setState(() => _assignedTo = uid),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? const LinearGradient(
                              colors: [Color(0xFF7B2DBD), AppColors.pink],
                            )
                          : null,
                      color: selected ? null : Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: selected
                            ? Colors.transparent
                            : Colors.white.withOpacity(0.12),
                      ),
                    ),
                    child: Text(
                      uid == widget.userId ? 'Me ($name)' : name,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // XP slider
          Row(
            children: [
              Text(
                'Proposed XP:',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(width: 10),
              Text(
                '$_proposedXP',
                style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.pink),
              ),
            ],
          ),
          Slider(
            value: _proposedXP.toDouble(),
            min: 1,
            max: 20,
            divisions: 19,
            activeColor: AppColors.pink,
            inactiveColor: Colors.white12,
            label: '$_proposedXP XP',
            onChanged: (v) => setState(() => _proposedXP = v.round()),
          ),

          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.redAccent)),
          ],
          const SizedBox(height: 20),

          // Submit
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B2DBD), AppColors.pink],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        'Create Chore',
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _GradientField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3D1370), Color(0xFF7B2DBD)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          labelText: label,
          labelStyle:
              GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
          floatingLabelBehavior: FloatingLabelBehavior.never,
        ),
      ),
    );
  }
}
