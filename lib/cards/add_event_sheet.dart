import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../services/sound_service.dart';
import '../services/notification_service.dart';
import '../theme.dart';

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
  DateTime? _reminderAt;

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

    final docRef = await _firestoreService.addEventReturningRef(
      title: _titleController.text.trim(),
      date: _selectedDate,
      houseId: widget.houseId,
      currentUserId: widget.currentUserId,
      reminderAt: _reminderAt,
    );

    if (_reminderAt != null) {
      await NotificationService.instance.scheduleReminder(
        eventId: docRef.id,
        eventTitle: _titleController.text.trim(),
        fireAt: _reminderAt!,
      );
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
            color: selected ? Colors.white : AppColors.onPanelSecondary,
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
      decoration: HomiePanel.imageOrCard(
        darkAsset: 'assets/images/calendar/EventMainPanel.png',
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Text(
            "New event",
            style: TextStyle(color: AppColors.onPanel, fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _titleController,
            style: TextStyle(color: AppColors.onPanel),
            decoration: InputDecoration(
              hintText: "Event title",
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: HomiePalette.current.fieldFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: Text("Event date", style: TextStyle(color: AppColors.onPanelSecondary)),
            subtitle: Text(
              DateFormat('yyyy-MM-dd').format(_selectedDate),
              style: TextStyle(color: AppColors.onPanel, fontWeight: FontWeight.bold),
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

          Align(
            alignment: Alignment.centerLeft,
            child: Text("Reminder", style: TextStyle(color: AppColors.onPanelSecondary, fontSize: 13)),
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
                  Icon(Icons.notifications_outlined, color: AppColors.onPanelSecondary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _reminderAt == null
                          ? 'Pick custom date & time'
                          : 'Remind at ${DateFormat('dd/MM/yyyy HH:mm').format(_reminderAt!)}',
                      style: TextStyle(color: AppColors.onPanelSecondary, fontSize: 13),
                    ),
                  ),
                  if (_reminderAt != null)
                    GestureDetector(
                      onTap: _clearReminder,
                      child: Icon(Icons.close, color: AppColors.onPanelMuted, size: 18),
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
            child: Text("Save Event", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.onAccent)),
          ),

          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => NotificationService.instance.debugFireTestNotification(
              eventTitle: _titleController.text.trim().isEmpty
                  ? 'Test event'
                  : _titleController.text.trim(),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.onPanelMuted),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              "🧪 Simulate notification now (dev)",
              style: TextStyle(fontSize: 13, color: AppColors.onPanelSecondary),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}