import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../services/firestore_service.dart';
import 'edit_event_sheet.dart'; 
import '../services/sound_service.dart';

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
    final _firestoreService = FirestoreService();

     return Container(
    margin: const EdgeInsets.only(bottom: 12.0),
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage('assets/images/calendar/EventPanel.png'),
        fit: BoxFit.fill,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isDone 
                ? Colors.grey.withOpacity(0.2) 
                : const Color(0xFFE040FB).withOpacity(0.2),
            child: Icon(
              isDone ? Icons.check : Icons.star, 
              color: isDone ? Colors.grey : const Color(0xFFE040FB), 
              size: 20
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDone ? "$formattedDate (Done)" : formattedDate,
                  style: TextStyle(
                    color: isDone ? Colors.white38 : Colors.white60,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.title,
                  style: TextStyle(
                    color: isDone ? Colors.white54 : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          ),
          
          if (!isDone) ...[
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white60, size: 20),
              onPressed: () {
                SoundService.instance.playPop();
                EditEventSheet.show(context, event, houseId, currentUserId);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: () async {
                
                
                SoundService.instance.playDelete();
                await _firestoreService.deleteEvent(
                  eventId: event.eventId,
                  houseId: houseId,
                );
              },
            ),
          ]
        ],
      ),
    );
  }
}