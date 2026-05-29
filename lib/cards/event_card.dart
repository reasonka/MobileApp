import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';

class EventCard extends StatelessWidget {
  final EventModel event;

  const EventCard({Key? key, required this.event}) : super(key: key);
  
  get cross => null;

  @override
  Widget build(BuildContext context) {
    // Formats date to match "29/05" syntax
    final String formattedDate = DateFormat('dd/MM').format(event.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2A2B3E).withOpacity(0.8),
            const Color(0xFF3E3054).withOpacity(0.8),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFE040FB).withOpacity(0.2),
            child: const Icon(Icons.star, color: Color(0xFFE040FB), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}