import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sportsync/features/booking/providers/booking_providers.dart';

enum SlotHoldStatus { active, consumed, cancelled, expired }

extension SlotHoldStatusX on SlotHoldStatus {
  String get wireValue => name;

  static SlotHoldStatus parse(String? raw) {
    return SlotHoldStatus.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => SlotHoldStatus.active,
    );
  }
}

/// In-progress reservation that blocks the slot from being booked by anyone
/// else while the user completes payment. 5-min TTL.
class SlotHold {
  const SlotHold({
    required this.id,
    required this.userId,
    required this.courtId,
    required this.date,
    required this.slots,
    required this.amountCents,
    required this.expiresAt,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String courtId;
  final String date; // YYYY-MM-DD
  final List<SelectedSlot> slots;
  final int amountCents;
  final DateTime expiresAt;
  final SlotHoldStatus status;
  final DateTime createdAt;

  Duration get remaining => expiresAt.difference(DateTime.now());
  bool get isExpired => remaining.isNegative;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'courtId': courtId,
        'date': date,
        'slots': slots.map((s) => {'court': s.court, 'time': s.time}).toList(),
        'amountCents': amountCents,
        'expiresAt': Timestamp.fromDate(expiresAt),
        'status': status.wireValue,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory SlotHold.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return SlotHold(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      courtId: data['courtId'] as String? ?? '',
      date: data['date'] as String? ?? '',
      slots: ((data['slots'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => (
                court: m['court'] as String? ?? '',
                time: m['time'] as String? ?? '',
              ))
          .toList(),
      amountCents: (data['amountCents'] as num?)?.toInt() ?? 0,
      expiresAt:
          (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: SlotHoldStatusX.parse(data['status'] as String?),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
