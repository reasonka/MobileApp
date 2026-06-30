import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../services/firestore_service.dart';
import '../../services/sound_service.dart';
import '../../services/notification_service.dart';

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
      backgroundColor: Colors.transparent,
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
  DateTime? _reminderAt;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _selectedDate = widget.event.date;
    _reminderAt = widget.event.reminderAt;
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
      setState(() => _selectedDate = picked);
    }
  }

  void _setReminderBefore(Duration before) {
    SoundService.instance.playPop();
    setState(() => _reminderAt = _selectedDate.subtract(before));
  }

  Future<void> _pickCustomReminder() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _reminderAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _clearReminder() {
    SoundService.instance.playPop();
    setState(() => _reminderAt = null);
  }

  void _submit() async {
    if (_titleController.text.trim().isEmpty) return;
    final title = _titleController.text.trim();

    await _firestoreService.updateEvent(
      eventId: widget.event.eventId,
      title: title,
      date: _selectedDate,
      houseId: widget.houseId,
      reminderAt: _reminderAt,
    );

    if (_reminderAt != null) {
      await NotificationService.instance.scheduleReminder(
        eventId: widget.event.eventId,
        eventTitle: title,
        fireAt: _reminderAt!,
      );
    } else {
      await NotificationService.instance.cancelReminder(widget.event.eventId);
    }

    if (mounted) Navigator.pop(context);
  }

  Widget _quickReminderChip(String label, Duration before) {
    final bool selected = _reminderAt == _selectedDate.subtract(before);
    return GestureDetector(
      onTap: () => _setReminderBefore(before),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE040FB).withOpacity(0.25)
              : Colors.black.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFE040FB) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
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
            onTap: () {
              SoundService.instance.playPop();
              _pickDate();
            },
          ),
          const SizedBox(height: 16),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Reminder", style: TextStyle(color: Colors.white70, fontSize: 13)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _quickReminderChip('1h before', const Duration(hours: 1)),
              _quickReminderChip('3h before', const Duration(hours: 3)),
              _quickReminderChip('6h before', const Duration(hours: 6)),
              _quickReminderChip('12h before', const Duration(hours: 12)),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickCustomReminder,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_outlined, color: Colors.white60, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _reminderAt == null
                          ? 'Pick custom date & time'
                          : 'Remind at ${DateFormat('dd/MM/yyyy HH:mm').format(_reminderAt!)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                  if (_reminderAt != null)
                    GestureDetector(
                      onTap: _clearReminder,
                      child: const Icon(Icons.close, color: Colors.white38, size: 18),
                    ),
                ],
              ),
            ),
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
            child: const Text("Update Event", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ),

          // DEV-ONLY: fires a notification immediately to verify wiring.
          // Remove before release.
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => NotificationService.instance.debugFireTestNotification(
              eventTitle: _titleController.text.trim().isEmpty
                  ? 'Test event'
                  : _titleController.text.trim(),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text(
              "🧪 Simulate notification now (dev)",
              style: TextStyle(fontSize: 13, color: Colors.white60),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}