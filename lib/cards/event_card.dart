import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart'; // FIXED: Added import
import '../models/event_model.dart';
import '../services/firestore_service.dart';
import 'edit_event_sheet.dart';

class EventCard extends StatelessWidget {
  final EventModel event;
  final String houseId;
  final String currentUserId;

  const EventCard({
    super.key,
    required this.event,
    required this.houseId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(event.date.year, event.date.month, event.date.day);
    final isDone = eventDate.isBefore(today);
    final String formattedDate = DateFormat('dd/MM').format(event.date);
    final firestoreService = FirestoreService();

    return GestureDetector( // FIXED: Clicking anywhere opens edit
      onTap: () => EditEventSheet.show(context, event, houseId, currentUserId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF2A2B3E).withValues(alpha: isDone ? 0.4 : 0.8),
              const Color(0xFF3E3054).withValues(alpha: isDone ? 0.4 : 0.8),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: Colors.white.withValues(alpha: isDone ? 0.04 : 0.08),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isDone
                  ? Colors.grey.withValues(alpha: 0.2)
                  : const Color(0xFFB721A9).withValues(alpha: 0.2), // FIXED: Color to _pink
              child: Icon(
                isDone ? Icons.check : Icons.star,
                color: isDone ? Colors.grey : const Color(0xFFB721A9), // FIXED: Color to _pink
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDone ? '$formattedDate (Done)' : formattedDate,
                    style: GoogleFonts.poppins( // FIXED: Added GoogleFonts
                      color: isDone ? Colors.white38 : Colors.white60,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.title,
                    style: GoogleFonts.poppins( // FIXED: Added GoogleFonts
                      color: isDone ? Colors.white54 : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ],
              ),
            ),
            if (!isDone)
              const Icon(Icons.edit, color: Colors.white60, size: 20),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: Colors.redAccent, size: 20),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: const Color(0xFF1D1D35),
                    title: const Text('Delete event?',
                        style: TextStyle(color: Colors.white)),
                    content: Text(
                      'Remove "${event.title}"?',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel',
                            style: TextStyle(color: Colors.white54)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete',
                            style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await firestoreService.deleteEvent(
                    eventId: event.eventId,
                    houseId: houseId,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}