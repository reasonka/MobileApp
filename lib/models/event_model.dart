import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String eventId;
  final String title;
  final DateTime date;
  final String houseId;
  final String createdBy;

  EventModel({
    required this.eventId,
    required this.title,
    required this.date,
    required this.houseId,
    required this.createdBy,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      eventId: doc.id,
      title: data['title'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      houseId: data['houseId'] ?? '',
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': Timestamp.fromDate(date),
      'houseId': houseId,
      'createdBy': createdBy,
    };
  }
}