import 'package:cloud_firestore/cloud_firestore.dart';

class NoteModel {
  final String noteId;
  final String content;
  final String authorId;
  final String authorName;
  final String houseId;
  final DateTime createdAt;
  final DateTime expiresAt; // end of the day it was created

  const NoteModel({
    required this.noteId,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.houseId,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory NoteModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NoteModel(
      noteId: doc.id,
      content: d['content'] as String? ?? '',
      authorId: d['authorId'] as String? ?? '',
      authorName: d['authorName'] as String? ?? '',
      houseId: d['houseId'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (d['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'content': content,
        'authorId': authorId,
        'authorName': authorName,
        'houseId': houseId,
        'createdAt': Timestamp.fromDate(createdAt),
        'expiresAt': Timestamp.fromDate(expiresAt),
      };
}
