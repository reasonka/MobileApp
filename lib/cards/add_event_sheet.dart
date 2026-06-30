import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../services/sound_service.dart';

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

  
  static void show(BuildContext context, String houseId, String currentUserId, {DateTime? initialDate}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
    width: double.infinity,
    height: 480,
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
          "New event",
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
          onTap: () {
            SoundService.instance.playPop();
            _pickDate();
          },
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {
            SoundService.instance.playDone();
            _submit();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE040FB),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text("Save Event", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
        const SizedBox(height: 40), 
      ],
    ),
  );
}
}