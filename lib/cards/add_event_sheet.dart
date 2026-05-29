import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';

class AddEventSheet extends StatefulWidget {
  final String houseId;
  final String currentUserId;

  const AddEventSheet({
    Key? key,
    required this.houseId,
    required this.currentUserId,
  }) : super(key: key);

  static void show(BuildContext context, String houseId, String currentUserId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF14142A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddEventSheet(houseId: houseId, currentUserId: currentUserId),
      ),
    );
  }

  @override
  State<AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<AddEventSheet> {
  final _titleController = TextEditingController();
  final _firestoreService = FirestoreService();
  DateTime _selectedDate = DateTime.now();

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
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "New event",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
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
              fillColor: const Color(0xFF1D1D35),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
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
            tileColor: const Color(0xFF1D1D35),
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
            child: const Text(
              "Save Event",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}