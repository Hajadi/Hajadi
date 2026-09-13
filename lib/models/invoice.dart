import '../core/utils/json_utils.dart';
import 'job_request.dart';

enum PaymentStatus {
  unpaid('unpaid'),
  processing('processing'),
  paid('paid'),
  failed('failed'),
  refunded('refunded');

  const PaymentStatus(this.id);

  final String id;

  static PaymentStatus fromId(String? id) => switch (id) {
        'processing' => PaymentStatus.processing,
        'paid' => PaymentStatus.paid,
        'failed' => PaymentStatus.failed,
        'refunded' => PaymentStatus.refunded,
        _ => PaymentStatus.unpaid,
      };
}

/// A row in `invoices/{invoiceId}`, generated when a job is marked complete.
///
/// Amounts are in gourdes. The platform fee is stored on the document so a
/// later change to the commission rate never rewrites history.
class Invoice {
  const Invoice({
    required this.id,
    required this.number,
    required this.jobId,
    required this.customerId,
    required this.customerName,
    required this.workerId,
    required this.workerName,
    required this.subtotal,
    required this.serviceFee,
    required this.method,
    required this.status,
    this.currency = 'HTG',
    this.transactionRef,
    this.cardBrand,
    this.cardLast4,
    this.issuedAt,
    this.paidAt,
  });

  final String id;
  final String number;
  final String jobId;
  final String customerId;
  final String customerName;
  final String workerId;
  final String workerName;
  final double subtotal;
  final double serviceFee;
  final String currency;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? transactionRef;

  /// Card receipts keep the brand and the last four digits — never more.
  final String? cardBrand;
  final String? cardLast4;
  final DateTime? issuedAt;
  final DateTime? paidAt;

  double get total => subtotal + serviceFee;

  /// What the worker actually takes home.
  double get workerPayout => subtotal;

  factory Invoice.fromMap(String id, Map<String, dynamic> map) => Invoice(
        id: id,
        number: Json.asString(map['number']),
        jobId: Json.asString(map['jobId']),
        customerId: Json.asString(map['customerId']),
        customerName: Json.asString(map['customerName']),
        workerId: Json.asString(map['workerId']),
        workerName: Json.asString(map['workerName']),
        subtotal: Json.asDouble(map['subtotal']),
        serviceFee: Json.asDouble(map['serviceFee']),
        currency: Json.asString(map['currency'], fallback: 'HTG'),
        method: PaymentMethod.fromId(Json.asStringOrNull(map['method'])),
        status: PaymentStatus.fromId(Json.asStringOrNull(map['status'])),
        transactionRef: Json.asStringOrNull(map['transactionRef']),
        cardBrand: Json.asStringOrNull(map['cardBrand']),
        cardLast4: Json.asStringOrNull(map['cardLast4']),
        issuedAt: Json.asDateOrNull(map['issuedAt']),
        paidAt: Json.asDateOrNull(map['paidAt']),
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'number': number,
        'jobId': jobId,
        'customerId': customerId,
        'customerName': customerName,
        'workerId': workerId,
        'workerName': workerName,
        'subtotal': subtotal,
        'serviceFee': serviceFee,
        'currency': currency,
        'method': method.id,
        'status': status.id,
        'transactionRef': transactionRef,
        'cardBrand': cardBrand,
        'cardLast4': cardLast4,
        'issuedAt': issuedAt?.toIso8601String(),
        'paidAt': paidAt?.toIso8601String(),
      };

  Invoice copyWith({
    PaymentStatus? status,
    PaymentMethod? method,
    String? transactionRef,
    String? cardBrand,
    String? cardLast4,
    DateTime? paidAt,
  }) =>
      Invoice(
        id: id,
        number: number,
        jobId: jobId,
        customerId: customerId,
        customerName: customerName,
        workerId: workerId,
        workerName: workerName,
        subtotal: subtotal,
        serviceFee: serviceFee,
        currency: currency,
        method: method ?? this.method,
        status: status ?? this.status,
        transactionRef: transactionRef ?? this.transactionRef,
        cardBrand: cardBrand ?? this.cardBrand,
        cardLast4: cardLast4 ?? this.cardLast4,
        issuedAt: issuedAt,
        paidAt: paidAt ?? this.paidAt,
      );
}
