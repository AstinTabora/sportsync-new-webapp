import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus {
  pending,
  pendingPayment,
  paid,
  paymentFailed,
  slotExpired,
  cash,
  completed,
  cancelled,
}

extension BookingStatusX on BookingStatus {
  String get wireValue => name;

  static BookingStatus parse(String? raw) {
    return BookingStatus.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => BookingStatus.pending,
    );
  }
}

enum BookingPayment { gcash, card, qrph, cash }

extension BookingPaymentX on BookingPayment {
  String get wireValue => name;

  static BookingPayment parse(String? raw) {
    return BookingPayment.values.firstWhere(
      (p) => p.name == raw,
      orElse: () => BookingPayment.cash,
    );
  }
}

class Booking {
  const Booking({
    required this.id,
    required this.userId,
    required this.courtId,
    required this.courtName,
    required this.courtType,
    required this.date,
    required this.slots,
    required this.totalAmount,
    required this.payment,
    required this.status,
    required this.refCode,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.createdAt,
    this.amountCents,
    this.paymongoCheckoutSessionId,
    this.paymongoPaymentId,
    this.checkoutUrl,
    this.paidAt,
  });

  final String id;
  final String userId;
  final String courtId;
  final String courtName;
  final String courtType;
  final DateTime date;
  final List<BookingSlot> slots;
  final int totalAmount;
  final BookingPayment payment;
  final BookingStatus status;
  final String refCode;
  final String userName;
  final String userEmail;
  final String userPhone;
  final DateTime createdAt;

  final int? amountCents;
  final String? paymongoCheckoutSessionId;
  final String? paymongoPaymentId;
  final String? checkoutUrl;
  final DateTime? paidAt;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'courtId': courtId,
        'courtName': courtName,
        'courtType': courtType,
        'date': Timestamp.fromDate(date),
        'slots': slots.map((s) => s.toMap()).toList(),
        'totalAmount': totalAmount,
        'payment': payment.wireValue,
        'status': status.wireValue,
        'refCode': refCode,
        'userName': userName,
        'userEmail': userEmail,
        'userPhone': userPhone,
        'createdAt': Timestamp.fromDate(createdAt),
        if (amountCents != null) 'amountCents': amountCents,
        if (paymongoCheckoutSessionId != null)
          'paymongoCheckoutSessionId': paymongoCheckoutSessionId,
        if (paymongoPaymentId != null) 'paymongoPaymentId': paymongoPaymentId,
        if (checkoutUrl != null) 'checkoutUrl': checkoutUrl,
        if (paidAt != null) 'paidAt': Timestamp.fromDate(paidAt!),
      };

  factory Booking.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Booking(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      courtId: data['courtId'] as String? ?? '',
      courtName: data['courtName'] as String? ?? '',
      courtType: data['courtType'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      slots: ((data['slots'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => BookingSlot.fromMap(Map<String, dynamic>.from(m)))
          .toList(),
      totalAmount: (data['totalAmount'] as num?)?.toInt() ?? 0,
      payment: BookingPaymentX.parse(data['payment'] as String?),
      status: BookingStatusX.parse(data['status'] as String?),
      refCode: data['refCode'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      userEmail: data['userEmail'] as String? ?? '',
      userPhone: data['userPhone'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      amountCents: (data['amountCents'] as num?)?.toInt(),
      paymongoCheckoutSessionId:
          data['paymongoCheckoutSessionId'] as String?,
      paymongoPaymentId: data['paymongoPaymentId'] as String?,
      checkoutUrl: data['checkoutUrl'] as String?,
      paidAt: (data['paidAt'] as Timestamp?)?.toDate(),
    );
  }
}

class BookingSlot {
  const BookingSlot({required this.court, required this.time});

  final String court;
  final String time;

  Map<String, dynamic> toMap() => {'court': court, 'time': time};

  factory BookingSlot.fromMap(Map<String, dynamic> m) =>
      BookingSlot(court: m['court'] as String, time: m['time'] as String);
}
