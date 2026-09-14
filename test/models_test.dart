import 'package:flutter_test/flutter_test.dart';
import 'package:jwenn_met/models/app_user.dart';
import 'package:jwenn_met/models/chat.dart';
import 'package:jwenn_met/models/invoice.dart';
import 'package:jwenn_met/models/job_request.dart';
import 'package:jwenn_met/models/worker_profile.dart';

/// Stands in for a Firestore `Timestamp`, which the models duck-type through
/// `toDate()` so they can stay free of a cloud_firestore import.
class FakeTimestamp {
  FakeTimestamp(this._value);

  final DateTime _value;

  DateTime toDate() => _value;
}

void main() {
  group('AppUser', () {
    test('round-trips through a map', () {
      final AppUser user = AppUser(
        id: 'u1',
        fullName: 'Marie-Ange Prophète',
        role: UserRole.worker,
        email: 'marie@jwennmet.ht',
        languageCode: 'ht',
        favoriteWorkerIds: const <String>['w1'],
        createdAt: DateTime.utc(2026, 3, 4),
      );
      final AppUser parsed = AppUser.fromMap('u1', user.toMap());

      expect(parsed.fullName, user.fullName);
      expect(parsed.role, UserRole.worker);
      expect(parsed.favoriteWorkerIds, <String>['w1']);
      expect(parsed.createdAt, DateTime.utc(2026, 3, 4));
    });

    test('defaults an unknown role to customer', () {
      final AppUser parsed =
          AppUser.fromMap('u2', <String, dynamic>{'role': 'superuser'});
      expect(parsed.role, UserRole.customer);
      expect(parsed.status, AccountStatus.active);
    });
  });

  group('date parsing', () {
    test('accepts ISO strings, millis, DateTime and Timestamp-likes', () {
      final DateTime expected = DateTime.utc(2026, 1, 2, 3, 4);
      for (final Object value in <Object>[
        expected.toIso8601String(),
        expected.millisecondsSinceEpoch,
        expected,
        FakeTimestamp(expected),
      ]) {
        final JobRequest job =
            JobRequest.fromMap('j', <String, dynamic>{'createdAt': value});
        expect(job.createdAt?.toUtc(), expected, reason: '$value');
      }
    });
  });

  group('WorkerProfile', () {
    test('parses nested portfolio and certificates', () {
      final WorkerProfile profile = WorkerProfile.fromMap('w1', <String, dynamic>{
        'fullName': 'Wilner Dorcéus',
        'categoryIds': <String>['electrician', 'ac_technician'],
        'departmentId': 'ouest',
        'city': 'Delmas',
        'verification': 'approved',
        'portfolio': <Map<String, dynamic>>[
          <String, dynamic>{'id': 'p1', 'imageUrl': 'https://x/1.jpg'},
        ],
        'certificates': <Map<String, dynamic>>[
          <String, dynamic>{'id': 'c1', 'title': 'INFP', 'fileUrl': 'https://x/c.pdf'},
        ],
      });

      expect(profile.isVerified, isTrue);
      expect(profile.portfolio.single.id, 'p1');
      expect(profile.certificates.single.title, 'INFP');
      // Workers who never set a preference accept every method, cards
      // included — the platform carries card processing, not the worker.
      expect(
        profile.acceptedPaymentMethods,
        <String>['moncash', 'natcash', 'card', 'cash'],
      );
      // A document written before custom trades existed still parses.
      expect(profile.customCategories, isEmpty);
    });

    test('custom trades survive a round trip', () {
      const WorkerProfile profile = WorkerProfile(
        id: 'w2',
        fullName: 'Darline Delva',
        categoryIds: <String>['mason', 'other'],
        customCategories: <String>['Fotograf evènman', 'DJ'],
        departmentId: 'ouest',
        city: 'Delmas',
      );

      final WorkerProfile parsed =
          WorkerProfile.fromMap('w2', profile.toMap());
      expect(parsed.customCategories, <String>['Fotograf evènman', 'DJ']);
      expect(parsed.categoryIds, contains('other'));
    });
  });

  group('Invoice', () {
    test('total is subtotal plus fee, payout excludes the fee', () {
      const Invoice invoice = Invoice(
        id: 'i1',
        number: 'JM-2026-1000',
        jobId: 'j1',
        customerId: 'c1',
        customerName: 'Kliyan',
        workerId: 'w1',
        workerName: 'Bòs',
        subtotal: 4500,
        serviceFee: 450,
        method: PaymentMethod.moncash,
        status: PaymentStatus.unpaid,
      );

      expect(invoice.total, 4950);
      expect(invoice.workerPayout, 4500);
      expect(
        invoice.copyWith(status: PaymentStatus.paid).status,
        PaymentStatus.paid,
      );
    });

    test('card receipts round-trip brand and last four, and nothing more', () {
      const Invoice invoice = Invoice(
        id: 'i2',
        number: 'JM-2026-1002',
        jobId: 'j2',
        customerId: 'c1',
        customerName: 'Kliyan',
        workerId: 'w1',
        workerName: 'Bòs',
        subtotal: 3000,
        serviceFee: 300,
        method: PaymentMethod.card,
        status: PaymentStatus.paid,
        cardBrand: 'visa',
        cardLast4: '4242',
      );
      final Invoice parsed = Invoice.fromMap('i2', invoice.toMap());

      expect(parsed.method, PaymentMethod.card);
      expect(parsed.cardBrand, 'visa');
      expect(parsed.cardLast4, '4242');
      // The serialized form carries no field that could hold a full number.
      expect(invoice.toMap().containsKey('cardNumber'), isFalse);
      expect(invoice.toMap()['cardLast4'].toString().length, 4);
    });

    test('copyWith can relabel the method chosen at checkout', () {
      const Invoice invoice = Invoice(
        id: 'i3',
        number: 'JM-2026-1003',
        jobId: 'j3',
        customerId: 'c1',
        customerName: 'Kliyan',
        workerId: 'w1',
        workerName: 'Bòs',
        subtotal: 1000,
        serviceFee: 100,
        method: PaymentMethod.moncash,
        status: PaymentStatus.unpaid,
      );
      final Invoice paidByCard = invoice.copyWith(
        method: PaymentMethod.card,
        status: PaymentStatus.paid,
        cardBrand: 'mastercard',
        cardLast4: '4444',
      );
      expect(paidByCard.method, PaymentMethod.card);
      expect(paidByCard.cardBrand, 'mastercard');
    });
  });

  group('JobRequest', () {
    test('billable amount prefers the agreed price over the budget', () {
      const JobRequest job = JobRequest(
        id: 'j1',
        customerId: 'c1',
        customerName: 'Kliyan',
        workerId: 'w1',
        workerName: 'Bòs',
        categoryId: 'plumber',
        description: 'Fuite',
        status: JobStatus.inProgress,
        paymentMethod: PaymentMethod.cash,
        budget: 3000,
        agreedPrice: 3500,
      );
      expect(job.billableAmount, 3500);
      expect(job.status.isOpen, isTrue);
      expect(JobStatus.completed.isOpen, isFalse);
    });

    test('a job booked under an unlisted trade keeps the wording', () {
      const JobRequest job = JobRequest(
        id: 'j2',
        customerId: 'c1',
        customerName: 'Kliyan',
        workerId: 'w1',
        workerName: 'Bòs',
        categoryId: 'other',
        customCategory: 'Repetitè lekòl',
        description: 'De fwa pa semèn apre lekòl.',
        status: JobStatus.pending,
        paymentMethod: PaymentMethod.cash,
      );

      final JobRequest parsed = JobRequest.fromMap('j2', job.toMap());
      expect(parsed.categoryId, 'other');
      expect(parsed.customCategory, 'Repetitè lekòl');
      // Advancing a job must not drop what it was booked for.
      expect(
        parsed.copyWith(status: JobStatus.accepted).customCategory,
        'Repetitè lekòl',
      );
    });
  });

  group('Conversation', () {
    test('id is stable whichever side opens the thread', () {
      expect(Conversation.idFor('b', 'a'), Conversation.idFor('a', 'b'));
    });

    test('resolves the other participant and their title', () {
      const Conversation conversation = Conversation(
        id: 'a_b',
        participantIds: <String>['a', 'b'],
        titles: <String, String>{'a': 'Kliyan', 'b': 'Bòs'},
        unreadCounts: <String, int>{'a': 3},
      );
      expect(conversation.otherParticipantId('a'), 'b');
      expect(conversation.titleFor('a'), 'Bòs');
      expect(conversation.unreadFor('a'), 3);
      expect(conversation.unreadFor('b'), 0);
    });
  });
}
