import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String eventId;
  final String title;
  final DateTime date;
  final String houseId;
  final String createdBy;

  /// True only for the auto-generated birthday event. Locked: no edit/delete,
  /// recurs every year on the same month/day regardless of the stored year.
  final bool isBirthday;

  /// When set, a local notification is scheduled to fire at this moment.
  final DateTime? reminderAt;

  EventModel({
    required this.eventId,
    required this.title,
    required this.date,
    required this.houseId,
    required this.createdBy,
    this.isBirthday = false,
    this.reminderAt,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final reminderTs = data['reminderAt'];
    return EventModel(
      eventId: doc.id,
      title: data['title'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      houseId: data['houseId'] ?? '',
      createdBy: data['createdBy'] ?? '',
      isBirthday: data['isBirthday'] as bool? ?? false,
      reminderAt:
          reminderTs is Timestamp ? reminderTs.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': Timestamp.fromDate(date),
      'houseId': houseId,
      'createdBy': createdBy,
      'isBirthday': isBirthday,
      'reminderAt': reminderAt != null ? Timestamp.fromDate(reminderAt!) : null,
    };
  }

  /// True if [day] matches this event's month+day, for any year — used so
  /// birthday events recur on the calendar every year automatically.
  bool occursOnDay(DateTime day) {
    if (isBirthday) {
      return date.month == day.month && date.day == day.day;
    }
    return date.year == day.year && date.month == day.month && date.day == day.day;
  }
}