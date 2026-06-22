import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';

class AddEventSheet extends StatefulWidget {
  final String houseId;
  final String currentUserId;
  final DateTime? initialDate;

  const AddEventSheet({
    super.key,
    required this.houseId,
    required this.currentUserId,
    this.initialDate,
  });

  static void show(BuildContext context, String houseId, String currentUserId,
      {DateTime? initialDate}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddEventSheet(
          houseId: houseId,
          currentUserId: currentUserId,
          initialDate: initialDate,
        ),
      ),
    );
  }

  @override
  State<AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<AddEventSheet> {
  final _titleController = TextEditingController();
  final _firestoreService = FirestoreService();
  late DateTime _selectedDate;

  // ── theme tokens (match EventCard / BillsScreen) ──
  static const _sheetBg    = Color(0xFF1A1A2E);
  static const _fieldBg    = Color(0xFF23233A);
  static const _border     = Color(0xFF2E2E50);
  static const _pink       = Color(0xFFB721A9);
  static const _textPri    = Color(0xFFFFFFFF);
  static const _textSec    = Color(0xFFB0ADCC);

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _pink,
            onPrimary: Colors.white,
            surface: Color(0xFF1D1D35),
            onSurface: Colors.white,
          ),
          dialogTheme: const DialogThemeData(
            backgroundColor: Color(0xFF0D0D1A),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;
    await _firestoreService.addEvent(
      title: _titleController.text.trim(),
      date: _selectedDate,
      houseId: widget.houseId,
      currentUserId: widget.currentUserId,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: _sheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── drag handle ──────────────────────────────────────
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Text(
            'New Event',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _textPri,
            ),
          ),
          const SizedBox(height: 20),

          // ── title field ──────────────────────────────────────
          Text('Event title',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textSec,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            style: GoogleFonts.poppins(color: _textPri, fontSize: 15),
            cursorColor: _pink,
            decoration: InputDecoration(
              hintText: 'e.g. Movie night',
              hintStyle: GoogleFonts.poppins(color: _textSec),
              filled: true,
              fillColor: _fieldBg,
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 14, horizontal: 16),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _border)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _pink, width: 1.5)),
            ),
          ),
          const SizedBox(height: 18),

          // ── date picker ──────────────────────────────────────
          Text('Date',
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textSec,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _fieldBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: _pink, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('dd MMM yyyy').format(_selectedDate),
                    style: GoogleFonts.poppins(
                        color: _textPri,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text('tap to change',
                      style: GoogleFonts.poppins(
                          color: _textSec, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── save button ──────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _pink,
                foregroundColor: _textPri,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                'Save Event',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}