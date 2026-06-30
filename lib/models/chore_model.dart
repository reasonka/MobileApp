import 'package:cloud_firestore/cloud_firestore.dart';

class ChoreModel {
  final String choreId;
  final String title;
  final String assignedTo; 
  final String houseId;
  final bool completed;
  final DateTime? completedAt;
  final int proposedXP;
  final String xpStatus; 
  final Map<String, int> xpVotes; 
  final int agreedXP; 
  final String createdBy;
  final DateTime createdAt;
  final String weekStart; 

  const ChoreModel({
    required this.choreId,
    required this.title,
    required this.assignedTo,
    required this.houseId,
    required this.completed,
    this.completedAt,
    required this.proposedXP,
    required this.xpStatus,
    required this.xpVotes,
    required this.agreedXP,
    required this.createdBy,
    required this.createdAt,
    required this.weekStart,
  });

  
  int get effectiveXP => xpStatus == 'agreed' ? agreedXP : proposedXP;

  factory ChoreModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ChoreModel(
      choreId: doc.id,
      title: d['title'] as String? ?? '',
      assignedTo: d['assignedTo'] as String? ?? '',
      houseId: d['houseId'] as String? ?? '',
      completed: d['completed'] as bool? ?? false,
      completedAt: (d['completedAt'] as Timestamp?)?.toDate(),
      proposedXP: d['proposedXP'] as int? ?? 5,
      xpStatus: d['xpStatus'] as String? ?? 'pending',
      xpVotes: Map<String, int>.from(
        (d['xpVotes'] as Map?)?.map((k, v) => MapEntry(k as String, v as int)) ?? {},
      ),
      agreedXP: d['agreedXP'] as int? ?? 5,
      createdBy: d['createdBy'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      weekStart: d['weekStart'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'assignedTo': assignedTo,
        'houseId': houseId,
        'completed': completed,
        'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'proposedXP': proposedXP,
        'xpStatus': xpStatus,
        'xpVotes': xpVotes,
        'agreedXP': agreedXP,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
        'weekStart': weekStart,
      };
}
