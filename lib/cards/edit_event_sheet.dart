import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../services/firestore_service.dart';

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
    backgroundColor: Colors.transparent, // MUST BE TRANSPARENT
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage('assets/images/calendar/EventMainPanel.png'),
        fit: BoxFit.fill,
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        const Text(
          "Edit event",
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _titleController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Event title",
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.black.withOpacity(0.2),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          title: const Text("Event date", style: TextStyle(color: Colors.white70)),
          subtitle: Text(
            DateFormat('yyyy-MM-dd').format(_selectedDate),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          trailing: const Icon(Icons.calendar_month, color: Color(0xFFE040FB)),
          tileColor: Colors.black.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onTap: _pickDate,
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE040FB),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text("Update Event", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        const SizedBox(height: 40),
      ],
    ),
  );
}
}