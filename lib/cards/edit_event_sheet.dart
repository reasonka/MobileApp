import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../services/firestore_service.dart';
import 'package:google_fonts/google_fonts.dart'; 

class EditEventSheet extends StatefulWidget {
  final EventModel event;
  final String houseId;
  final String currentUserId;

  const EditEventSheet({
    super.key,
    required this.event,
    required this.houseId,
    required this.currentUserId,
  });

  static void show(BuildContext context, EventModel event, String houseId, String currentUserId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // FIXED: Set to transparent to show container rounding
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: EditEventSheet(event: event, houseId: houseId, currentUserId: currentUserId),
      ),
    );
  }

  @override
  State<EditEventSheet> createState() => _EditEventSheetState();
}

class _EditEventSheetState extends State<EditEventSheet> {
  late TextEditingController _titleController;
  final _firestoreService = FirestoreService();
  late DateTime _selectedDate;

  // Theme tokens
  static const _sheetBg = Color(0xFF1A1A2E);
  static const _fieldBg = Color(0xFF23233A);
  static const _border = Color(0xFF2E2E50);
  static const _pink = Color(0xFFB721A9);
  static const _textPri = Color(0xFFFFFFFF);
  static const _textSec = Color(0xFFB0ADCC);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _selectedDate = widget.event.date;
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
      // FIXED: Added theme builder to match the pink theme
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
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() async {
    if (_titleController.text.trim().isEmpty) return;

    await _firestoreService.updateEvent(
      eventId: widget.event.eventId,
      title: _titleController.text.trim(),
      date: _selectedDate,
      houseId: widget.houseId,
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
          // Drag handle
          Center(
            child: Container(
              width: 40, 
              height: 4, 
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: _border, 
                borderRadius: BorderRadius.circular(2)
              ),
            ),
          ),
          Text(
            'Edit Event', 
            style: GoogleFonts.poppins(
              fontSize: 22, 
              fontWeight: FontWeight.w700, 
              color: _textPri
            )
          ),
          const SizedBox(height: 20),

          // Title field
          Text(
            'Event title',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textSec,
              letterSpacing: 0.5
            )
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            style: GoogleFonts.poppins(color: _textPri, fontSize: 15),
            cursorColor: _pink,
            decoration: InputDecoration(
              filled: true,
              fillColor: _fieldBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14), 
                borderSide: const BorderSide(color: _border)
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14), 
                borderSide: const BorderSide(color: _pink, width: 1.5)
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Date selection
          Text(
            'Date',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textSec,
              letterSpacing: 0.5
            )
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _fieldBg, 
                borderRadius: BorderRadius.circular(14), 
                border: Border.all(color: _border)
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
                      fontWeight: FontWeight.w600
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'tap to change', 
                    style: GoogleFonts.poppins(color: _textSec, fontSize: 12)
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _pink,
                foregroundColor: _textPri,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)
                ),
                elevation: 0,
              ),
              child: Text(
                'Update Event', 
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)
              ),
            ),
          ),
        ],
      ),
    );
  }
}