import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jwenn_met/core/constants/haiti_departments.dart';
import 'package:jwenn_met/core/constants/service_categories.dart';
import 'package:jwenn_met/models/worker_profile.dart';

/// The bundled dataset is what demo mode shows and what seeds a fresh
/// Firebase project, so it has to stay consistent with the app's own enums.
void main() {
  List<Map<String, dynamic>> load(String name) =>
      (json.decode(File('assets/sample_data/$name').readAsStringSync())
              as List<dynamic>)
          .cast<Map<String, dynamic>>();

  test('covers all ten departments and all ten trades', () {
    final List<Map<String, dynamic>> workers = load('workers.json');
    final Set<String> departments = workers
        .map((Map<String, dynamic> w) => '${w['departmentId']}')
        .toSet();
    final Set<String> categories = workers
        .expand((Map<String, dynamic> w) => (w['categoryIds'] as List<dynamic>))
        .map((dynamic id) => '$id')
        .toSet();

    expect(departments.length, HaitiDepartment.values.length);
    expect(categories.length, ServiceCategory.values.length);
  });

  test('every worker id, department and category resolves', () {
    for (final Map<String, dynamic> map in load('workers.json')) {
      final WorkerProfile worker =
          WorkerProfile.fromMap('${map['id']}', map);
      expect(worker.fullName, isNotEmpty);
      expect(HaitiDepartment.fromId(worker.departmentId), isNotNull);
      for (final String id in worker.categoryIds) {
        expect(ServiceCategory.fromId(id), isNotNull, reason: id);
      }
      expect(worker.hourlyRate, greaterThan(0));
      expect(worker.rating, inInclusiveRange(0, 5));
    }
  });

  test('jobs point at workers and customers that exist', () {
    final Set<String> workerIds = load('workers.json')
        .map((Map<String, dynamic> w) => '${w['id']}')
        .toSet();
    final Set<String> userIds =
        load('users.json').map((Map<String, dynamic> u) => '${u['id']}').toSet();

    for (final Map<String, dynamic> job in load('jobs.json')) {
      expect(workerIds, contains('${job['workerId']}'));
      expect(userIds, contains('${job['customerId']}'));
    }
  });

  test('every completed job has an invoice whose fee is 10%', () {
    final Map<String, Map<String, dynamic>> invoices =
        <String, Map<String, dynamic>>{
      for (final Map<String, dynamic> invoice in load('invoices.json'))
        '${invoice['jobId']}': invoice,
    };

    for (final Map<String, dynamic> job in load('jobs.json')) {
      if (job['status'] != 'completed') {
        continue;
      }
      final Map<String, dynamic>? invoice = invoices['${job['id']}'];
      expect(invoice, isNotNull, reason: 'job ${job['id']} has no invoice');
      final double subtotal = (invoice!['subtotal'] as num).toDouble();
      final double fee = (invoice['serviceFee'] as num).toDouble();
      expect(fee, closeTo(subtotal * 0.10, 0.01));
    }
  });

  test('card invoices carry a brand and last four — and never a full number',
      () {
    final List<Map<String, dynamic>> invoices = load('invoices.json');
    final Iterable<Map<String, dynamic>> cards =
        invoices.where((Map<String, dynamic> i) => i['method'] == 'card');

    expect(cards, isNotEmpty, reason: 'demo mode should show a card payment');
    for (final Map<String, dynamic> invoice in cards) {
      expect(
        <String>['visa', 'mastercard'],
        contains(invoice['cardBrand']),
      );
      expect('${invoice['cardLast4']}', hasLength(4));
    }
    for (final Map<String, dynamic> invoice in invoices) {
      expect(invoice.containsKey('cardNumber'), isFalse);
      expect(invoice.containsKey('cvc'), isFalse);
    }
  });

  test('workers offer the methods the app knows about', () {
    const Set<String> known = <String>{'moncash', 'natcash', 'card', 'cash'};
    for (final Map<String, dynamic> worker in load('workers.json')) {
      final List<dynamic> methods =
          worker['acceptedPaymentMethods'] as List<dynamic>;
      expect(methods, isNotEmpty);
      for (final dynamic method in methods) {
        expect(known, contains('$method'), reason: '${worker['id']}');
      }
    }
  });

  test('the three demo accounts are present with the documented roles', () {
    final Map<String, String> roles = <String, String>{
      for (final Map<String, dynamic> user in load('users.json'))
        '${user['id']}': '${user['role']}',
    };
    expect(roles['demo_customer'], 'customer');
    expect(roles['demo_worker'], 'worker');
    expect(roles['demo_admin'], 'admin');
  });
}
