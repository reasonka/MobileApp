import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';

class NewNoteSheet extends StatefulWidget {
  final String userId;
  final String houseId;
  final String authorName;

  const NewNoteSheet({
    super.key,
    required this.userId,
    required this.houseId,
    required this.authorName,
  });

  @override
  State<NewNoteSheet> createState() => _NewNoteSheetState();
}

class _NewNoteSheetState extends State<NewNoteSheet> {
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _ctrl.text.trim();
    if (content.isEmpty) return;

    setState(() => _loading = true);
    try {
      await FirestoreService().addNote(
        content: content,
        authorId: widget.userId,
        authorName: widget.authorName,
        houseId: widget.houseId,
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      
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
          
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.onPanelMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'New Note',
            style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.onPanel),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.schedule, color: AppColors.onPanelMuted, size: 14),
              const SizedBox(width: 4),
              Text(
                'This note disappears after 24 hours',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppColors.onPanelDivider,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.onPanelDivider),
            ),
            child: TextField(
              controller: _ctrl,
              maxLines: 5,
              style: GoogleFonts.poppins(color: AppColors.onPanel, fontSize: 14),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                hintText: 'Write something for your housemates…',
                hintStyle: GoogleFonts.poppins(
                    color: AppColors.onPanelMuted, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 20),
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
                            strokeWidth: 2, color: AppColors.onAccent))
                    : Text(
                        'Post Note',
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onAccent),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
